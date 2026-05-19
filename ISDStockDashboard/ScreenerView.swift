//
//  ScreenerView.swift
//  ISDStockDashboard
//

import SwiftUI

struct ScreenerView: View {
    @State private var stocks: [ScreenerStock] = []
    @State private var stats: ScreenerQuickStats?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedFilter: String? = nil
    @State private var selectedSector: String? = nil
    @State private var selectedTab = 0

    private let api = APIClient.shared
    private let filters = ["STRONG_BUY", "BUY", "HOLD", "SELL", "STRONG_SELL"]
    private let sectors = ["Financials", "IT", "Healthcare", "Energy", "Consumer", "Auto", "Metals"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.isdBackground.ignoresSafeArea()
                List {
                    if isLoading {
                        Section {
                            ProgressView("Loading screener...")
                                .tint(.isdTextSecondary)
                                .padding()
                        }
                    } else if let error = errorMessage {
                        Section {
                            ContentUnavailableView {
                                Label("Error", systemImage: "exclamationmark.triangle")
                            } description: {
                                Text(error)
                            } actions: {
                                Button("Retry") {
                                    Task { await loadData() }
                                }
                            }
                        }
                    } else {
                        if let stats = stats {
                            statsSection(stats: stats)
                        }
                        filterChips
                        stocksSection
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Screener")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("", selection: $selectedTab) {
                        Text("AI").tag(0)
                        Text("All").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }
            }
            .refreshable {
                await loadData()
            }
            .task {
                await loadData()
            }
        }
    }

    private var filterChips: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button {
                        selectedFilter = nil
                        Task { await loadData() }
                    } label: {
                        Text("All")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .foregroundColor(selectedFilter == nil ? .white : .isdAccent)
                            .background(selectedFilter == nil ? Color.isdAccent : Color.isdAccent.opacity(0.10))
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.isdAccent.opacity(selectedFilter == nil ? 0 : 0.30), lineWidth: 1))
                            .cornerRadius(4)
                    }

                    ForEach(filters, id: \.self) { filter in
                        Button {
                            selectedFilter = filter
                            Task { await loadData() }
                        } label: {
                            Text(filter.replacingOccurrences(of: "_", with: " "))
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .foregroundColor(selectedFilter == filter ? .white : recommendationColor(filter))
                                .background(selectedFilter == filter ? recommendationColor(filter) : recommendationColor(filter).opacity(0.10))
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(recommendationColor(filter).opacity(selectedFilter == filter ? 0 : 0.30), lineWidth: 1))
                                .cornerRadius(4)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            }
            .background(Color.isdCard)
        }
    }

    private func statsSection(stats: ScreenerQuickStats) -> some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    StatBadge(title: "TOTAL", value: "\(stats.total_stocks)", color: .isdAccent)
                    if let top = stats.top_gainers.first {
                        StatBadge(title: "TOP GAINER", value: "\(top.symbol) +\(String(format: "%.1f%%", top.change_percent))", color: .isdGreen)
                    }
                    let buyCount = (stats.recommendation_distribution["BUY"] ?? 0) + (stats.recommendation_distribution["STRONG_BUY"] ?? 0)
                    StatBadge(title: "BUY SIGNALS", value: "\(buyCount)", color: .isdGreen)
                    let sellCount = (stats.recommendation_distribution["SELL"] ?? 0) + (stats.recommendation_distribution["STRONG_SELL"] ?? 0)
                    StatBadge(title: "SELL SIGNALS", value: "\(sellCount)", color: .isdRed)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .background(Color.isdCard)
        }
    }

    private var stocksSection: some View {
        ForEach(stocks) { stock in
            ScreenerRow(stock: stock)
        }
    }

    private func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            async let statsTask = api.fetchScreenerStats()
            async let stocksTask = api.fetchScreenerStocks(
                recommendation: selectedFilter,
                sector: selectedSector,
                sortBy: selectedTab == 0 ? "composite_score" : "change_percent",
                page: 1,
                limit: 50
            )
            let (statsResult, stocksResult) = try await (statsTask, stocksTask)
            stats = statsResult
            stocks = stocksResult.data
        } catch APIError.unauthorized {
            errorMessage = "Please sign in to view screener"
        } catch {
            errorMessage = "Failed to load screener data"
        }
        isLoading = false
    }

    private func recommendationColor(_ rec: String) -> Color {
        switch rec {
        case "STRONG_BUY", "BUY": return .isdGreen
        case "STRONG_SELL", "SELL": return .isdRed
        default: return .isdAccent
        }
    }
}

struct ScreenerRow: View {
    let stock: ScreenerStock

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(stock.symbol)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(.isdTextPrimary)

                    if let rec = stock.recommendation {
                        Text(rec.replacingOccurrences(of: "_", with: " "))
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .foregroundColor(recColor(rec))
                            .background(recColor(rec).opacity(0.10))
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(recColor(rec).opacity(0.30), lineWidth: 1))
                            .cornerRadius(4)
                    }

                    Spacer()
                }

                Text(stock.company_name)
                    .font(.subheadline)
                    .foregroundColor(.isdTextSecondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let sector = stock.sector {
                        Text(sector.uppercased())
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.isdTextMuted)
                            .tracking(0.3)
                    }
                    if let rsi = stock.rsi_14 {
                        Text(String(format: "RSI %.1f", rsi))
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.isdTextMuted)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let price = stock.close_price {
                    Text(String(format: "₹%.2f", price))
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(.isdTextPrimary)
                }

                if let change = stock.change_percent {
                    Text(String(format: "%+.2f%%", change))
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(change >= 0 ? .isdGreen : .isdRed)
                }

                if let score = stock.ai_score {
                    Text(String(format: "AI %.0f", score))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.isdAccent)
                }
            }
        }
        .padding(.vertical, 8)
        .background(Color.isdCard)
    }

    private func recColor(_ rec: String) -> Color {
        switch rec {
        case "STRONG_BUY", "BUY": return .isdGreen
        case "STRONG_SELL", "SELL": return .isdRed
        default: return .isdAccent
        }
    }
}

struct StatBadge: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.isdTextMuted)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(color.opacity(0.25), lineWidth: 1))
        .cornerRadius(4)
    }
}

#Preview {
    ScreenerView()
}
