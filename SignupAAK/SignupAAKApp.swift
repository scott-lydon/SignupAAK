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
            GlobalBannerHost(
                isVisible: .constant(true),
                message: "Offline. Some features may not work."
            ) {
                NavigationStack {
                    SignupView()
                }
                .environmentObject(connectivity)
            }
        }
    }
}



struct GlobalBannerHost<Content: View>: View {
    @Binding var isVisible: Bool
    let message: String
    let content: Content

    init(isVisible: Binding<Bool>, message: String, @ViewBuilder content: () -> Content) {
        self._isVisible = isVisible
        self.message = message
        self.content = content()
    }

    var body: some View {
        content
            .overlay(alignment: .top) {
                if isVisible {
                    TopBanner(message: message)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(999)
                }
            }
            .animation(.default, value: isVisible)
    }
}

struct TopBanner: View {
    let message: String

    var body: some View {
        GeometryReader { proxy in
            let safeTop = proxy.safeAreaInsets.top

            VStack(spacing: 0) {
                Text(message)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
            }
            .background(
                Rectangle()
                    .fill(.red.opacity(0.90))
                    .ignoresSafeArea(edges: .top)    // background reaches top of device
            )
            .frame(maxWidth: .infinity, alignment: .top)
            .fixedSize(horizontal: false, vertical: true) // height driven by text
        }
        .frame(height: 0) // keeps GeometryReader from taking full-screen height
    }
}
