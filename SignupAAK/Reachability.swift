//
//  Reachability.swift
//  SignupAAK
//
//  Created by Scott Lydon on 1/10/26.
//

import Foundation
import SystemConfiguration

public struct Network {

    public static var reachability: Reachability?
    public static let flagsChanged = Notification.Name("FlagsChanged")

    public enum Status: String {
        case unreachable, wifi, wwan
    }

    public enum Error: Swift.Error {
        case failedToSetCallout
        case failedToSetDispatchQueue
        case failedToCreateWith(String)
        case failedToInitializeWith(sockaddr_in, sockaddr_in6)
    }
}

public class Reachability {
    var hostname: String?
    var ipv6 = false
    var isRunning = false
    var isReachableOnWWAN: Bool
    var reachability: SCNetworkReachability
    var reachabilityFlags = SCNetworkReachabilityFlags()
    static let serialQueue = DispatchQueue(label: "ReachabilityQueue")
    // avoid usind SCNetworkReachabilityCreateWithAddress (please use the hostname initializer)
    init() throws {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        if let reachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault , $0)
            }
        }) {
            self.reachability = reachability
        } else {
            var zeroAddress6 = sockaddr_in6()
            zeroAddress6.sin6_len = UInt8(MemoryLayout<sockaddr_in>.size)
            zeroAddress6.sin6_family = sa_family_t(AF_INET6)
            guard let reachability = withUnsafePointer(to: &zeroAddress6, {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, $0)
                }
            }) else {
                throw Network.Error.failedToInitializeWith(zeroAddress, zeroAddress6)
            }
            self.reachability = reachability
            print(zeroAddress6.sin6_addr)
            ipv6 = true
        }
        self.isReachableOnWWAN = true
        try start()
    }

    // preferred method SCNetworkReachabilityCreateWithName
    init<S: StringProtocol>(hostname: S) throws {
        let hostname = String(hostname)
        guard let reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, hostname) else {
            throw Network.Error.failedToCreateWith(hostname)
        }
        self.reachability = reachability
        self.hostname = hostname
        self.isReachableOnWWAN = true
        try start()
    }

    public var status: Network.Status {
        return isConnectedToNetwork && isReachableViaWiFi ? .wifi :
               isConnectedToNetwork && isRunningOnDevice  ? .wwan :
               .unreachable
    }
    public var isConnectedToNetwork: Bool {
        return reachable &&
               !isConnectionRequiredAndTransientConnection &&
               !(isRunningOnDevice && isWWAN && !isReachableOnWWAN)
    }
    public var isReachableViaWiFi: Bool { reachable && isRunningOnDevice && !isWWAN }
    public var isRunningOnDevice: Bool = {
        print("isRunningOnDevice")
        #if targetEnvironment(simulator)
            return false
        #else
            return true
        #endif
    }()
    deinit { stop() }


}


private extension Reachability {
    // start posting notifications on flagsChanged
    private func start() throws {
        guard !isRunning else { return }
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = Unmanaged<Reachability>.passUnretained(self).toOpaque()

        let callout: SCNetworkReachabilityCallBack = {
            guard
                let info = $2,
                case let reachability = Unmanaged<Reachability>.fromOpaque(info).takeUnretainedValue(),
                reachability.flags != reachability.reachabilityFlags
            else { return }
            reachability.reachabilityFlags = reachability.flags
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Network.flagsChanged, object: reachability)
            }
        }

        guard SCNetworkReachabilitySetCallback(reachability, callout, &context) else {
            stop()
            throw Network.Error.failedToSetCallout
        }
        guard SCNetworkReachabilitySetDispatchQueue(reachability, Reachability.serialQueue) else {
            stop()
            throw Network.Error.failedToSetDispatchQueue
        }

        Reachability.serialQueue.async { [unowned self] in
            NotificationCenter.default.post(name: Network.flagsChanged, object: self)
        }

        isRunning = true
    }
    // stops posting notifications on flagsChanged
    private func stop() {
        defer { isRunning = false }
        SCNetworkReachabilitySetCallback(reachability, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachability, nil)
    }


    /// Flags that indicate the reachability of a network node name or address, including whether a connection is required, and whether some user intervention might be required when establishing a connection.
    var flags: SCNetworkReachabilityFlags {
        var flags = SCNetworkReachabilityFlags()
        return withUnsafeMutablePointer(to: &flags) {
            SCNetworkReachabilityGetFlags(reachability, UnsafeMutablePointer($0))
        } ? flags : SCNetworkReachabilityFlags()
    }

    /// compares the current flags with the previous flags and if changed posts a flagsChanged notification

    func flagsChanged() {
        guard flags != reachabilityFlags else { return }
        reachabilityFlags = flags
        NotificationCenter.default.post(name: Network.flagsChanged, object: self)
    }

    /// The specified node name or address can be reached via a transient connection, such as PPP.
    var transientConnection: Bool { flags.contains(.transientConnection)  }

    /// The specified node name or address can be reached using the current network configuration.
    var reachable: Bool { flags.contains(.reachable) }

    /// The specified node name or address can be reached using the current network configuration, but a connection must first be established. If this flag is set, the kSCNetworkReachabilityFlagsConnectionOnTraffic flag, kSCNetworkReachabilityFlagsConnectionOnDemand flag, or kSCNetworkReachabilityFlagsIsWWAN flag is also typically set to indicate the type of connection required. If the user must manually make the connection, the kSCNetworkReachabilityFlagsInterventionRequired flag is also set.
    var connectionRequired: Bool { flags.contains(.connectionRequired) }

    /// The specified node name or address can be reached using the current network configuration, but a connection must first be established. Any traffic directed to the specified name or address will initiate the connection.
    var connectionOnTraffic: Bool { flags.contains(.connectionOnTraffic) }

    /// The specified node name or address can be reached using the current network configuration, but a connection must first be established.
    var interventionRequired: Bool { flags.contains(.interventionRequired) }

    /// The specified node name or address can be reached using the current network configuration, but a connection must first be established. The connection will be established "On Demand" by the CFSocketStream programming interface (see CFStream Socket Additions for information on this). Other functions will not establish the connection.
    var connectionOnDemand: Bool { flags.contains(.connectionOnDemand) }

    /// The specified node name or address is one that is associated with a network interface on the current system.
    var isLocalAddress: Bool { flags.contains(.isLocalAddress) }

    /// Network traffic to the specified node name or address will not go through a gateway, but is routed directly to one of the interfaces in the system.
    var isDirect: Bool { flags.contains(.isDirect) }

    /// The specified node name or address can be reached via a cellular connection, such as EDGE or GPRS.
    var isWWAN: Bool { flags.contains(.isWWAN) }

    /// The specified node name or address can be reached using the current network configuration, but a connection must first be established. If this flag is set
    /// The specified node name or address can be reached via a transient connection, such as PPP.
    var isConnectionRequiredAndTransientConnection: Bool { flags == [.connectionRequired, .transientConnection] }
}

extension StringProtocol {
    func reachability() throws -> Reachability  { try Reachability(hostname: self) }
}


import Foundation
import Combine

@MainActor
final class ReachabilityMonitor: ObservableObject {

    @Published private(set) var status: Network.Status = .unreachable

    private var token: NSObjectProtocol?
    private let reachability: Reachability

    init(reachability: Reachability) {
        self.reachability = reachability
        self.status = reachability.status

        token = NotificationCenter.default.addObserver(
            forName: Network.flagsChanged,
            object: nil, // or: reachability (see note below)
            queue: .main
        ) { [weak self] note in
            guard let self else { return }
            Task { @MainActor in
                if let r = note.object as? Reachability {
                    self.status = r.status
                } else {
                    self.status = self.reachability.status
                }
            }
        }
    }

    deinit {
        if let token { NotificationCenter.default.removeObserver(token) }
    }

    var isConnected: Bool { status != .unreachable }
    var isWifi: Bool { status == .wifi }
    var isCellular: Bool { status == .wwan } // WWAN = Wireless Wide Area Network (cellular)
}

