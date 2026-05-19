//
//  SearchView.swift
//  ISDStockDashboard
//

import SwiftUI

struct SearchView: View {
    @State private var searchQuery = ""
    @State private var searchResults: [StockSearchResult] = []
    @State private var isSearching = false
    @State private var selectedStock: StockSearchResult?

    private let api = APIClient.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.isdBackground.ignoresSafeArea()
                List {
                    if isSearching {
                        Section {
                            ForEach(searchResults) { stock in
                                NavigationLink(value: stock) {
                                    StockSearchRow(stock: stock)
                                }
                            }
                        }
                        .listRowBackground(Color.isdCard)
                    } else if !searchQuery.isEmpty && searchResults.isEmpty {
                        Section {
                            ContentUnavailableView {
                                Label("No Results", systemImage: "magnifyingglass")
                            } description: {
                                Text("Try searching for a different stock")
                            }
                        }
                    } else if searchQuery.isEmpty {
                        Section {
                            ContentUnavailableView {
                                Label("Search Stocks", systemImage: "magnifyingglass")
                            } description: {
                                Text("Enter a stock symbol or company name")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Search")
            .navigationDestination(for: StockSearchResult.self) { stock in
                StockDetailView(symbol: stock.symbol, name: stock.name)
            }
            .searchable(text: $searchQuery, prompt: "Search stocks...")
            .onChange(of: searchQuery) { _, newValue in
                Task {
                    await performSearch(query: newValue)
                }
            }
        }
    }

    private func performSearch(query: String) async {
        guard query.count >= 2 else {
            searchResults = []
            return
        }
        isSearching = true
        do {
            searchResults = try await api.searchStocks(query: query)
        } catch {
            searchResults = []
        }
        isSearching = false
    }
}

struct StockSearchRow: View {
    let stock: StockSearchResult

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.symbol)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(.isdTextPrimary)

                Text(stock.name)
                    .font(.subheadline)
                    .foregroundColor(.isdTextSecondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(stock.exchange.uppercased())
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.isdAccent.opacity(0.10))
                        .foregroundColor(.isdAccent)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.isdAccent.opacity(0.30), lineWidth: 1))
                        .cornerRadius(4)

                    if let sector = stock.sector {
                        Text(sector)
                            .font(.caption)
                            .foregroundColor(.isdTextMuted)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let price = stock.price {
                    Text(String(format: "₹%.2f", price))
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundColor(.isdTextPrimary)
                }

                if let changePercent = stock.change_percent {
                    HStack(spacing: 2) {
                        Image(systemName: changePercent >= 0 ? "arrow.up" : "arrow.down")
                            .font(.caption2)
                        Text(String(format: "%+.2f%%", changePercent))
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                    }
                    .foregroundStyle(Color.profitLossColor(changePercent))
                }
            }
        }
        .padding(.vertical, 4)
        .background(Color.isdCard)
    }
}

#Preview {
    SearchView()
}
