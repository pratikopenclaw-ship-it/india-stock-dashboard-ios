//
//  InsiderView.swift
//  ISDStockDashboard
//

import SwiftUI

struct InsiderView: View {
    @State private var trades: [InsiderTrade] = []
    @State private var promoterConfidence: [PromoterConfidenceSummary] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedTab = 0
    @State private var symbolFilter = ""
    @State private var transactionFilter: String? = nil

    private let api = APIClient.shared
    private let transactionTypes = ["P", "S", "G", "E", "A"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.isdBackground.ignoresSafeArea()
                List {
                    if isLoading {
                        Section {
                            ProgressView("Loading insider data...")
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
                        if selectedTab == 0 {
                            promoterSection
                        } else {
                            tradesSection
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Insider Trading")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("", selection: $selectedTab) {
                        Text("Promoter").tag(0)
                        Text("Trades").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
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

    private var promoterSection: some View {
        ForEach(promoterConfidence) { item in
            PromoterRow(item: item)
        }
    }

    private var tradesSection: some View {
        Section {
            HStack(spacing: 8) {
                TextField("Filter by symbol", text: $symbolFilter)
                    .textInputAutocapitalization(.characters)
                    .foregroundColor(.isdTextPrimary)

                Menu {
                    Button("All Types") { transactionFilter = nil }
                    ForEach(transactionTypes, id: \.self) { type in
                        Button(typeName(type)) { transactionFilter = type }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(.isdAccent)
                }
            }
            .padding(.vertical, 4)
            .background(Color.isdCard)

            if filteredTrades.isEmpty {
                ContentUnavailableView {
                    Label("No Trades", systemImage: "doc.text")
                } description: {
                    Text("No insider trades match your filters")
                }
            } else {
                ForEach(filteredTrades) { trade in
                    InsiderTradeRow(trade: trade)
                }
            }
        }
    }

    private var filteredTrades: [InsiderTrade] {
        trades.filter { trade in
            let symbolMatch = symbolFilter.isEmpty || trade.symbol.contains(symbolFilter.uppercased())
            let typeMatch = transactionFilter == nil || trade.transaction_type == transactionFilter
            return symbolMatch && typeMatch
        }
    }

    private func typeName(_ code: String) -> String {
        switch code {
        case "P": return "Purchase"
        case "S": return "Sale"
        case "G": return "Gift"
        case "E": return "ESOP"
        case "A": return "Allotment"
        default: return code
        }
    }

    private func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            async let tradesTask = api.fetchInsiderTrades(symbol: nil, transactionType: nil, page: 1, pageSize: 50)
            async let promoterTask = api.fetchPromoterConfidence()
            let (tradesResult, promoterResult) = try await (tradesTask, promoterTask)
            trades = tradesResult.trades
            promoterConfidence = promoterResult.summaries
        } catch APIError.unauthorized {
            errorMessage = "Please sign in to view insider data"
        } catch {
            errorMessage = "Failed to load insider data"
        }
        isLoading = false
    }
}

struct PromoterRow: View {
    let item: PromoterConfidenceSummary

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(item.symbol)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(.isdTextPrimary)

                    Text(item.signal.uppercased())
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .tracking(0.3)
                        .foregroundColor(signalColor)
                        .background(signalColor.opacity(0.10))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(signalColor.opacity(0.30), lineWidth: 1))
                        .cornerRadius(6)

                    Spacer()
                }

                Text(item.companyName)
                    .font(.subheadline)
                    .foregroundColor(.isdTextSecondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(item.score)")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(signalColor)

                HStack(spacing: 2) {
                    Image(systemName: item.trendDirection == "UP" ? "arrow.up" : "arrow.down")
                        .font(.caption2)
                    Text(String(format: "%+.1f%%", item.trendPercentage))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                }
                .foregroundColor(item.trendDirection == "UP" ? .isdGreen : .isdRed)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.isdCard)
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
    }

    private var signalColor: Color {
        switch item.signal {
        case "STRONG_BUY", "BUY": return .isdGreen
        case "STRONG_SELL", "SELL": return .isdRed
        default: return .isdAccent
        }
    }
}

struct InsiderTradeRow: View {
    let trade: InsiderTrade

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(trade.symbol)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(.isdTextPrimary)

                    Text(trade.transaction_type.uppercased())
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .tracking(0.3)
                        .foregroundColor(typeColor)
                        .background(typeColor.opacity(0.10))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(typeColor.opacity(0.30), lineWidth: 1))
                        .cornerRadius(6)

                    Spacer()
                }

                Text(trade.insider_name)
                    .font(.subheadline)
                    .foregroundColor(.isdTextSecondary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(trade.designation.uppercased())
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.isdTextMuted)
                        .tracking(0.3)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let value = trade.value {
                    Text(String(format: "₹%.2f", value))
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(.isdTextPrimary)
                }

                if let qty = trade.quantity {
                    Text(String(format: "%.0f shares", qty))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.isdTextMuted)
                }

                Text(formattedDate(trade.transaction_date))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.isdTextMuted)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.isdCard)
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
    }

    private var typeColor: Color {
        switch trade.transaction_type {
        case "P", "G", "A": return .isdGreen
        case "S": return .isdRed
        default: return .isdAccent
        }
    }

    private func formattedDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let display = DateFormatter()
            display.dateStyle = .short
            return display.string(from: date)
        }
        return dateString
    }
}

#Preview {
    InsiderView()
}
