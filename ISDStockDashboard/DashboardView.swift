//
//  DashboardView.swift
//  ISDStockDashboard
//

import SwiftUI

struct DashboardView: View {
    @State private var indices: [IndexData] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedIndex: IndexData?

    private let api = APIClient.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView("Loading market data...")
                            .foregroundColor(.isdTextSecondary)
                            .padding()
                    } else if let error = errorMessage {
                        ContentUnavailableView {
                            Label("Error", systemImage: "exclamationmark.triangle")
                        } description: {
                            Text(error)
                        } actions: {
                            Button("Retry") {
                                Task { await loadData() }
                            }
                        }
                    } else {
                        marketIndicesSection
                        quickActionsSection
                    }
                }
                .padding()
            }
            .background(Color.isdBackground.ignoresSafeArea())
            .navigationTitle("Dashboard")
            .refreshable {
                await loadData()
            }
            .task {
                await loadData()
            }
        }
    }

    private var marketIndicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MARKET INDICES")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.isdTextMuted)
                .tracking(0.5)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(indices) { index in
                    IndexCard(index: index)
                }
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("QUICK ACTIONS")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.isdTextMuted)
                .tracking(0.5)

            HStack(spacing: 12) {
                NavigationLink(destination: SearchView()) {
                    QuickActionCard(
                        title: "Search",
                        icon: "magnifyingglass",
                        color: .isdAccent
                    )
                }

                NavigationLink(destination: WatchlistView()) {
                    QuickActionCard(
                        title: "Watchlist",
                        icon: "star.fill",
                        color: .isdGold
                    )
                }
            }

            HStack(spacing: 12) {
                NavigationLink(destination: AlertsView()) {
                    QuickActionCard(
                        title: "Alerts",
                        icon: "bell.fill",
                        color: .isdRed
                    )
                }

                NavigationLink(destination: NewsView()) {
                    QuickActionCard(
                        title: "News",
                        icon: "newspaper.fill",
                        color: .isdGreen
                    )
                }
            }
        }
    }

    private func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            indices = try await api.fetchIndices()
        } catch {
            errorMessage = "Failed to load market data"
        }
        isLoading = false
    }
}

struct IndexCard: View {
    let index: IndexData

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(index.name.uppercased())
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.isdTextMuted)
                .tracking(0.5)
                .lineLimit(1)

            if let value = index.value {
                Text(String(format: "%.2f", value))
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(.isdTextPrimary)
            } else {
                Text("--")
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(.isdTextMuted)
            }

            HStack(spacing: 4) {
                Image(systemName: (index.change ?? 0) >= 0 ? "arrow.up" : "arrow.down")
                if let change = index.change, let percent = index.change_percent {
                    Text(String(format: "%.2f (%.2f%%)", change, percent))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                } else {
                    Text("--")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                }
            }
            .foregroundStyle(Color.profitLossColor(index.change ?? 0))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.isdCard)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
        .cornerRadius(6)
    }
}

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.isdTextPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.isdCard)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
        .cornerRadius(6)
    }
}

#Preview {
    DashboardView()
}
