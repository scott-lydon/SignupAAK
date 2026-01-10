//
//  SignupAAKApp.swift
//  SignupAAK
//
//  Created by Scott Lydon on 1/8/26.
//

import SwiftUI

@main
struct SignupAAKApp: App {

    @StateObject private var connectivity = ConnectivityMonitor()
    
    var body: some Scene {
        WindowGroup {
            SignupView()
                .environmentObject(connectivity)
        }
    }
}
