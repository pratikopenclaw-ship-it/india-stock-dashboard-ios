//
//  Nifty50View.swift
//  ISDStockDashboard
//

import SwiftUI

struct Nifty50View: View {
    @State private var summary: NiftySummary?
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let api = APIClient.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.isdBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        if isLoading {
                            ProgressView("Loading NIFTY 50...")
                                .tint(.isdTextSecondary)
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
                        } else if let s = summary {
                            priceHeader(s)
                            if let sectors = s.sector_performance {
                                sectorSection(sectors)
                            }
                            if let gainers = s.top_gainers {
                                topMoversSection(title: "TOP GAINERS", stocks: gainers, color: .isdGreen)
                            }
                            if let losers = s.top_losers {
                                topMoversSection(title: "TOP LOSERS", stocks: losers, color: .isdRed)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("NIFTY 50")
            .refreshable { await loadData() }
            .task { await loadData() }
        }
    }

    private func priceHeader(_ s: NiftySummary) -> some View {
        VStack(spacing: 12) {
            if let price = s.price {
                Text(String(format: "%.2f", price))
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.isdTextPrimary)
            }
            if let change = s.change, let pct = s.change_percent {
                Text(String(format: "%+.2f (%+.2f%%)", change, pct))
                    .font(.system(size: 17, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.profitLossColor(change))
            }
            if let sentiment = s.sentiment {
                Text("SENTIMENT: \(sentiment.uppercased())")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.isdTextMuted)
                    .tracking(0.3)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.isdCard)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
        .cornerRadius(6)
    }

    private func sectorSection(_ sectors: [SectorPerformance]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SECTOR PERFORMANCE")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.isdTextMuted)
                .tracking(0.3)

            VStack(spacing: 8) {
                ForEach(sectors) { sector in
                    HStack {
                        Text(sector.sector)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.isdTextPrimary)

                        Spacer()

                        Text(String(format: "%.2f%%", sector.change_percent))
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.profitLossColor(sector.change_percent))
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color.isdCard)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
            .cornerRadius(6)
        }
    }

    private func topMoversSection(title: String, stocks: [StockSearchResult], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.isdTextMuted)
                .tracking(0.3)

            VStack(spacing: 0) {
                ForEach(stocks.prefix(5)) { stock in
                    HStack {
                        Text(stock.symbol)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.isdTextPrimary)

                        Spacer()

                        if let pct = stock.change_percent {
                            Text(String(format: "%+.2f%%", pct))
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundStyle(color)
                        }
                    }
                    .padding(.vertical, 6)
                    .background(Color.isdCard)
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
            .cornerRadius(6)
        }
    }

    private func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            summary = try await api.fetchNiftySummary()
        } catch {
            errorMessage = "Failed to load NIFTY 50"
        }
        isLoading = false
    }
}

#Preview {
    Nifty50View()
}
