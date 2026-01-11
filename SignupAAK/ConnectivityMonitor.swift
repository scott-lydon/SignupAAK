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
            // only update if it changed.
            if isOnline != online {
                isOnline = online
            }
        }
    }

    deinit {
        monitor.cancel()
    }
}
