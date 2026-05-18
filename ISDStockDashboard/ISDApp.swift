//
//  ISDApp.swift
//  ISDStockDashboard
//

import SwiftUI

@main
struct ISDStockDashboardApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isCheckingAuth {
                    SplashView()
                } else if authManager.isAuthenticated {
                    ContentView()
                        .environmentObject(authManager)
                } else {
                    AuthView()
                        .environmentObject(authManager)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

struct SplashView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Color.isdBackground
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 72))
                    .foregroundColor(.isdGreen)
                    .scaleEffect(isAnimating ? 1.05 : 0.95)
                    .opacity(isAnimating ? 1.0 : 0.7)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isAnimating)

                Text("India Stock Dashboard")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.isdTextPrimary)

                Text("Real-Time Indian Stock Intelligence")
                    .font(.subheadline)
                    .foregroundColor(.isdTextSecondary)

                ProgressView()
                    .tint(Color.isdAccent)
                    .padding(.top, 16)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}
