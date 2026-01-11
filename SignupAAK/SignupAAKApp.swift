//
//  SignupAAKApp.swift
//  SignupAAK
//
//  Created by Scott Lydon on 1/8/26.
//

import SwiftUI

@main
struct SignupAAKApp: App {

    @StateObject private var connectivity = ConnectivityMonitor.shared

    var body: some Scene {
        WindowGroup {
            SignupView()
                //.environmentObject(connectivity)
                .safeAreaInset(edge: .top, spacing: 0) {
                    if !connectivity.isOnline {
                        OfflineBannerView()
                            .frame(height: 44)
                            .frame(maxWidth: .infinity)
                    }
                }
                .animation(.default, value: connectivity.isOnline)
        }
    }
}
