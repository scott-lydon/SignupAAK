//
//  ConnectivityMonitor.swift
//  SignupAAK
//
//  Created by Scott Lydon on 1/9/26.
//

import Foundation
import Network
import Combine

@MainActor
final class ConnectivityMonitor: ObservableObject {

    static let shared = ConnectivityMonitor()

    @Published private(set) var isOnline: Bool = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "ConnectivityMonitor.NWPathMonitor")

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            print("connectivity callback: ", #line, Date())
            Task { @MainActor [weak self] in
                self?.updateOnlineStatus(with: path)
            }
        }

        monitor.start(queue: queue)

        // Force an initial publish after start (currentPath can be stale before start).
        queue.async { [weak self] in
            print("connectivity callback: ", #line, Date())
            Task { @MainActor [weak self] in
                guard let self else { return }
                updateOnlineStatus(with: monitor.currentPath)
            }
        }
    }

    func updateOnlineStatus() {
        updateOnlineStatus(with: monitor.currentPath)
    }

    private func updateOnlineStatus(with path: NWPath) {
        print(#line, "We got a connectivity update: ", path.status, Date())
        let online: Bool = (path.status == .satisfied)
        Task { @MainActor [weak self] in
            guard let self else { return }
            // if it changed.
            if isOnline != online {
                isOnline = online
            }
        }
    }

    deinit {
        monitor.cancel()
    }
}




import Foundation
import SystemConfiguration
import Combine

@MainActor
final class ConnectivityMonitor2: ObservableObject {
    static let shared = ConnectivityMonitor2()

    @Published private(set) var isOnline: Bool = true

    private var reachabilityRef: SCNetworkReachability?
    private var queue = DispatchQueue(label: "ReachabilityQueue")

    private init() {
        startMonitoring()
    }

    private func startMonitoring() {
        guard let ref = SCNetworkReachabilityCreateWithName(nil, "apple.com") else {
            print("❌ Failed to create reachability reference.")
            return
        }

        self.reachabilityRef = ref

        var context = SCNetworkReachabilityContext(
            version: 0,
            info: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let callback: SCNetworkReachabilityCallBack = { (_, flags, info) in
            guard let info = info else { return }
            let monitor = Unmanaged<ConnectivityMonitor2>.fromOpaque(info).takeUnretainedValue()
            monitor.handleReachabilityChanged(flags)
        }

        if SCNetworkReachabilitySetCallback(ref, callback, &context) {
            if SCNetworkReachabilitySetDispatchQueue(ref, queue) {
                updateInitialStatus()
            } else {
                print("❌ Failed to set reachability dispatch queue.")
            }
        } else {
            print("❌ Failed to set reachability callback.")
        }
    }

    private func stopMonitoring() {
        if let ref = reachabilityRef {
            SCNetworkReachabilitySetDispatchQueue(ref, nil)
        }
    }

    private func updateInitialStatus() {
        guard let ref = reachabilityRef else { return }

        var flags = SCNetworkReachabilityFlags()
        if SCNetworkReachabilityGetFlags(ref, &flags) {
            handleReachabilityChanged(flags)
        }
    }

    private func handleReachabilityChanged(_ flags: SCNetworkReachabilityFlags) {
        let newStatus = flags.contains(.reachable) &&
                       !flags.contains(.connectionRequired)

        Task { @MainActor in
            self.isOnline = newStatus
        }
    }
}
import Foundation
import SystemConfiguration
import Combine

extension Notification.Name {
    static let connectivityFlagsChanged = Notification.Name("ConnectivityFlagsChanged")
}

@MainActor
final class ConnectivityMonitor3: ObservableObject {

    static let shared = ConnectivityMonitor3()

    @Published private(set) var isOnline: Bool = true

    private let reachability: SCNetworkReachability
    private var cancellable: AnyCancellable?

    // Must be stored to prevent duplicate notifications
    private var lastFlags: SCNetworkReachabilityFlags = []

    private static let reachabilityQueue = DispatchQueue(label: "ConnectivityMonitor.ReachabilityQueue")

    private init() {
        // Using a hostname forces the OS to evaluate routing
        let host = "apple.com"

        guard let ref = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, host) else {
            // Fail open rather than permanently offline
            self.reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, "localhost")!
            self.isOnline = true
            return
        }

        self.reachability = ref

        // Subscribe to our reachability notifications
        self.cancellable = NotificationCenter.default
            .publisher(for: .connectivityFlagsChanged)
            .sink { [weak self] note in
                guard let self else { return }
                guard let flags = note.object as? SCNetworkReachabilityFlags else { return }
                self.apply(flags: flags)
            }

        startReachabilityCallback()

        // Publish initial state immediately
        Self.reachabilityQueue.async { [weak self] in
            guard let self else { return }
            let flags = self.currentFlags()
            DispatchQueue.main.async { [weak self] in
                self?.apply(flags: flags)
            }
        }
    }

    /// Optional manual re-check
    func refresh() {
        let flags = currentFlags()
        apply(flags: flags)
    }
}

private extension ConnectivityMonitor3 {

    func startReachabilityCallback() {
        var context = SCNetworkReachabilityContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let callback: SCNetworkReachabilityCallBack = { _, flags, info in
            guard let info else { return }
            let monitor = Unmanaged<ConnectivityMonitor>.fromOpaque(info).takeUnretainedValue()

            // Only emit when flags actually change
            //if flags == monitor.lastFlags { return }
//            monitor.lastFlags = flags
//
//            DispatchQueue.main.async {
//                NotificationCenter.default.post(name: .connectivityFlagsChanged, object: flags)
//            }
        }

        SCNetworkReachabilitySetCallback(reachability, callback, &context)
        SCNetworkReachabilitySetDispatchQueue(reachability, Self.reachabilityQueue)
    }

    func stopReachabilityCallback() {
        SCNetworkReachabilitySetCallback(reachability, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachability, nil)
    }

    func currentFlags() -> SCNetworkReachabilityFlags {
        var flags = SCNetworkReachabilityFlags()
        let ok = SCNetworkReachabilityGetFlags(reachability, &flags)
        return ok ? flags : []
    }

    func apply(flags: SCNetworkReachabilityFlags) {
        let online = Self.flagsIndicateOnline(flags)

        if isOnline != online {
            isOnline = online
        }
    }

    static func flagsIndicateOnline(_ flags: SCNetworkReachabilityFlags) -> Bool {
        let reachable = flags.contains(.reachable)
        let connectionRequired = flags.contains(.connectionRequired)

        if !reachable { return false }
        if !connectionRequired { return true }

        let canConnectAutomatically =
            flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic)

        let needsUserIntervention = flags.contains(.interventionRequired)

        return canConnectAutomatically && !needsUserIntervention
    }
}
