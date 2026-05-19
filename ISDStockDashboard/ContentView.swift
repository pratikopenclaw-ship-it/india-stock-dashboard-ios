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

            Nifty50View()
                .tabItem {
                    Label("NIFTY 50", systemImage: "indianrupeesign.circle")
                }

            SignalsView()
                .tabItem {
                    Label("Signals", systemImage: "waveform")
                }

            HoldingsView()
                .tabItem {
                    Label("Portfolio", systemImage: "briefcase.fill")
                }

            ScreenerView()
                .tabItem {
                    Label("Screener", systemImage: "line.3.horizontal.decrease.circle")
                }

            IPOCalendarView()
                .tabItem {
                    Label("IPO", systemImage: "calendar")
                }

            SmartMoneyView()
                .tabItem {
                    Label("Smart Money", systemImage: "banknote.fill")
                }

            AgentDebateView()
                .tabItem {
                    Label("Debate", systemImage: "bubble.left.and.bubble.right.fill")
                }

            PaperTradingView()
                .tabItem {
                    Label("Paper Trade", systemImage: "dollarsign.circle")
                }

            OptionsChainView()
                .tabItem {
                    Label("Options", systemImage: "list.bullet.rectangle")
                }

            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar.badge.clock")
                }

            Week52View()
                .tabItem {
                    Label("52W Scan", systemImage: "arrow.up.arrow.down")
                }

            ReportsView()
                .tabItem {
                    Label("Reports", systemImage: "doc.text.fill")
                }

            SignalAccuracyView()
                .tabItem {
                    Label("Accuracy", systemImage: "target")
                }

            TradePlannerView()
                .tabItem {
                    Label("Planner", systemImage: "clipboard.fill")
                }

            AdditionalMarketInfoView()
                .tabItem {
                    Label("Market Info", systemImage: "chart.bar.fill")
                }

            AIChatView()
                .tabItem {
                    Label("AI Chat", systemImage: "bubble.left.fill")
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
