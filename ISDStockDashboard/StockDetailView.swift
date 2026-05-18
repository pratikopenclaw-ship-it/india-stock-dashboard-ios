//
//  StockDetailView.swift
//  ISDStockDashboard
//

import SwiftUI

struct StockDetailView: View {
    let symbol: String
    let name: String

    @State private var stockDetail: StockDetail?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingAddAlert = false

    private let api = APIClient.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("Loading...")
                        .foregroundColor(.isdTextSecondary)
                        .padding()
                } else if let error = errorMessage {
                    ContentUnavailableView {
                        Label("Error", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    }
                } else if let stock = stockDetail {
                    headerSection(stock)
                    priceSection(stock)
                    statsGrid(stock)
                    actionButtons
                }
            }
            .padding()
        }
        .background(Color.isdBackground.ignoresSafeArea())
        .navigationTitle(symbol)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddAlert = true
                } label: {
                    Image(systemName: "bell.badge")
                        .foregroundColor(.isdAccent)
                }
            }
        }
        .sheet(isPresented: $showingAddAlert) {
            Text("Create Alert - Coming Soon")
                .foregroundColor(.isdTextPrimary)
                .presentationDetents([.medium])
        }
        .task {
            await loadStockDetail()
        }
        .refreshable {
            await loadStockDetail()
        }
    }

    private func headerSection(_ stock: StockDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(stock.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.isdTextPrimary)

            HStack(spacing: 8) {
                Text(stock.exchange.uppercased())
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.isdAccent.opacity(0.10))
                    .foregroundColor(.isdAccentLight)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdAccent.opacity(0.30), lineWidth: 1))
                    .cornerRadius(6)

                if let sector = stock.sector {
                    Text(sector)
                        .font(.caption)
                        .foregroundColor(.isdTextSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func priceSection(_ stock: StockDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .lastTextBaseline, spacing: 12) {
                if let price = stock.current_price {
                    Text(String(format: "₹%.2f", price))
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(.isdTextPrimary)
                } else {
                    Text("₹--")
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(.isdTextMuted)
                }

                if let previous = stock.previous_close, let current = stock.current_price {
                    let change = current - previous
                    let changePercent = (change / previous) * 100

                    HStack(spacing: 4) {
                        Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                        Text(String(format: "%.2f (%.2f%%)", change, changePercent))
                    }
                    .font(.system(size: 17, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.profitLossColor(change))
                }
            }

            if let high = stock.day_high, let low = stock.day_low {
                HStack {
                    Text("DAY LOW: ₹\(String(format: "%.2f", low))")
                    Spacer()
                    Text("DAY HIGH: ₹\(String(format: "%.2f", high))")
                }
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.isdTextMuted)
                .tracking(0.3)
            }
        }
        .padding()
        .background(Color.isdCard)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
        .cornerRadius(6)
    }

    private func statsGrid(_ stock: StockDetail) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(title: "VOLUME", value: formatNumber(stock.volume))
            StatCard(title: "MARKET CAP", value: formatCurrency(stock.market_cap))
            StatCard(title: "P/E RATIO", value: stock.pe_ratio != nil ? String(format: "%.2f", stock.pe_ratio!) : "--")
            StatCard(title: "DIV YIELD", value: stock.dividend_yield != nil ? String(format: "%.2f%%", stock.dividend_yield! * 100) : "--")
            StatCard(title: "52W HIGH", value: stock.fifty_two_week_high != nil ? String(format: "₹%.2f", stock.fifty_two_week_high!) : "--")
            StatCard(title: "52W LOW", value: stock.fifty_two_week_low != nil ? String(format: "₹%.2f", stock.fifty_two_week_low!) : "--")
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    await addToWatchlist()
                }
            } label: {
                HStack {
                    Image(systemName: "star.fill")
                    Text("Add to Watchlist")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.isdAccent)
                .foregroundStyle(.white)
                .cornerRadius(6)
            }
        }
    }

    private func loadStockDetail() async {
        isLoading = true
        errorMessage = nil
        do {
            stockDetail = try await api.fetchStockDetail(symbol: symbol)
        } catch {
            errorMessage = "Failed to load stock details"
        }
        isLoading = false
    }

    private func addToWatchlist() async {
        // Simplified - would need watchlist selection UI
    }

    private func formatNumber(_ number: Int?) -> String {
        guard let number = number else { return "--" }
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fK", Double(number) / 1_000)
        }
        return String(number)
    }

    private func formatCurrency(_ value: Double?) -> String {
        guard let value = value else { return "--" }
        if value >= 1_000_000_000_000 {
            return String(format: "₹%.1fT", value / 1_000_000_000_000)
        } else if value >= 1_000_000_000 {
            return String(format: "₹%.1fB", value / 1_000_000_000)
        } else if value >= 1_000_000 {
            return String(format: "₹%.1fM", value / 1_000_000)
        }
        return String(format: "₹%.0f", value)
    }
}

struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.isdTextMuted)
                .tracking(0.5)

            Text(value)
                .font(.system(size: 17, weight: .semibold, design: .monospaced))
                .foregroundColor(.isdTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.isdCard)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
        .cornerRadius(6)
    }
}

#Preview {
    NavigationStack {
        StockDetailView(symbol: "RELIANCE", name: "Reliance Industries")
    }
}
