//
//  ContentView.swift
//  ISDStockDashboard
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis")
                }

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            WatchlistView()
                .tabItem {
                    Label("Watchlist", systemImage: "star.fill")
                }

            SignalsView()
                .tabItem {
                    Label("Signals", systemImage: "waveform")
                }

            HoldingsView()
                .tabItem {
                    Label("Portfolio", systemImage: "briefcase.fill")
                }

            InsiderView()
                .tabItem {
                    Label("Insider", systemImage: "person.2.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .tint(.isdAccent)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
