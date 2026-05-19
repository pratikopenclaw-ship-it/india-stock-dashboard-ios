//
//  SmartMoneyView.swift
//  ISDStockDashboard
//

import SwiftUI

struct SmartMoneyView: View {
    @State private var fiiDii: FiiDiiSummary?
    @State private var bulkDeals: [BulkDeal] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedTab = 0

    private let api = APIClient.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.isdBackground.ignoresSafeArea()
                List {
                    if isLoading {
                        Section {
                            ProgressView("Loading smart money...")
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
                            fiiDiiSection
                        } else {
                            bulkDealsSection
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Smart Money")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("", selection: $selectedTab) {
                        Text("FII/DII").tag(0)
                        Text("Bulk Deals").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
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

    private var fiiDiiSection: some View {
        Group {
            if let data = fiiDii {
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        // Summary cards
                        HStack(spacing: 16) {
                            SmartMoneyCard(
                                title: "FII NET",
                                value: formatCurrency(data.fii_net),
                                color: (data.fii_net ?? 0) >= 0 ? .isdGreen : .isdRed
                            )
                            SmartMoneyCard(
                                title: "DII NET",
                                value: formatCurrency(data.dii_net),
                                color: (data.dii_net ?? 0) >= 0 ? .isdGreen : .isdRed
                            )
                        }

                        // Animated ratio bars
                        if let fiiBuy = data.fii_buy, let fiiSell = data.fii_sell {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("FII BUY / SELL RATIO")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(.isdTextMuted)
                                    .tracking(0.3)

                                ratioBar(buy: fiiBuy, sell: fiiSell)

                                HStack(spacing: 16) {
                                    DetailBadge(title: "FII BUY", value: formatCurrency(fiiBuy), color: .isdGreen)
                                    DetailBadge(title: "FII SELL", value: formatCurrency(fiiSell), color: .isdRed)
                                }
                            }
                        }

                        if let diiBuy = data.dii_buy, let diiSell = data.dii_sell {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("DII BUY / SELL RATIO")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(.isdTextMuted)
                                    .tracking(0.3)

                                ratioBar(buy: diiBuy, sell: diiSell)

                                HStack(spacing: 16) {
                                    DetailBadge(title: "DII BUY", value: formatCurrency(diiBuy), color: .isdGreen)
                                    DetailBadge(title: "DII SELL", value: formatCurrency(diiSell), color: .isdRed)
                                }
                            }
                        }

                        // 7-day trend summary
                        if let fiiTrend = data.fii_trend, let diiTrend = data.dii_trend {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("7-DAY TREND")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(.isdTextMuted)
                                    .tracking(0.3)

                                HStack(spacing: 16) {
                                    TrendBadge(label: "FII", trend: fiiTrend)
                                    TrendBadge(label: "DII", trend: diiTrend)
                                }
                            }
                        }

                        if let date = data.date {
                            Text("Data as of \(date)")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.isdTextMuted)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 8)
                    .background(Color.isdCard)
                }
            } else {
                Section {
                    ContentUnavailableView {
                        Label("No Data", systemImage: "chart.bar")
                    } description: {
                        Text("FII/DII data unavailable")
                    }
                }
            }
        }
    }

    private func ratioBar(buy: Double, sell: Double) -> some View {
        let total = buy + sell
        let buyPct = total > 0 ? buy / total : 0.5
        GeometryReader { geo in
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.isdGreen)
                    .frame(width: geo.size.width * CGFloat(buyPct))
                Rectangle()
                    .fill(Color.isdRed)
                    .frame(width: geo.size.width * CGFloat(1 - buyPct))
            }
        }
        .frame(height: 8)
        .cornerRadius(4)
    }

    private var bulkDealsSection: some View {
        Section {
            if bulkDeals.isEmpty {
                ContentUnavailableView {
                    Label("No Deals", systemImage: "doc.text")
                } description: {
                    Text("No bulk or block deals found")
                }
            } else {
                ForEach(bulkDeals) { deal in
                    BulkDealRow(deal: deal)
                }
            }
        }
    }

    private func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            async let fiiTask = api.fetchFiiDiiSummary()
            async let dealsTask = api.fetchBulkDeals()
            let (fiiResult, dealsResult) = try await (fiiTask, dealsTask)
            fiiDii = fiiResult
            bulkDeals = dealsResult
        } catch APIError.unauthorized {
            errorMessage = "Please sign in to view smart money data"
        } catch {
            errorMessage = "Failed to load smart money data"
        }
        isLoading = false
    }

    private func formatCurrency(_ value: Double?) -> String {
        guard let value = value else { return "--" }
        if abs(value) >= 1_000_000_000 {
            return String(format: "₹%.1fB", value / 1_000_000_000)
        } else if abs(value) >= 1_000_000 {
            return String(format: "₹%.1fM", value / 1_000_000)
        } else if abs(value) >= 1_000 {
            return String(format: "₹%.1fK", value / 1_000)
        }
        return String(format: "₹%.0f", value)
    }
}

struct SmartMoneyCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.isdTextMuted)
                .tracking(0.3)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(color.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.25), lineWidth: 1))
        .cornerRadius(6)
    }
}

struct DetailBadge: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.isdTextMuted)
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(color.opacity(0.06))
        .cornerRadius(4)
    }
}

struct TrendBadge: View {
    let label: String
    let trend: String

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.isdTextMuted)
            Text(trend.uppercased())
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(trendColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(trendColor.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(trendColor.opacity(0.25), lineWidth: 1))
        .cornerRadius(4)
    }

    private var trendColor: Color {
        let lower = trend.lowercased()
        if lower.contains("buy") || lower.contains("pos") || lower.contains("up") { return .isdGreen }
        if lower.contains("sell") || lower.contains("neg") || lower.contains("down") { return .isdRed }
        return .isdGold
    }
}

struct BulkDealRow: View {
    let deal: BulkDeal

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(deal.symbol)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(.isdTextPrimary)

                    if let type = deal.deal_type {
                        Text(type.uppercased())
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .foregroundColor(.isdAccent)
                            .background(Color.isdAccent.opacity(0.10))
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.isdAccent.opacity(0.30), lineWidth: 1))
                            .cornerRadius(4)
                    }

                    Spacer()
                }

                if let client = deal.client_name {
                    Text(client)
                        .font(.subheadline)
                        .foregroundColor(.isdTextSecondary)
                        .lineLimit(1)
                }

                if let date = deal.date {
                    Text(date.prefix(10))
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.isdTextMuted)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let qty = deal.deal_quantity {
                    Text(String(format: "%.0f shares", qty))
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(.isdTextPrimary)
                }

                if let price = deal.deal_price {
                    Text(String(format: "₹%.2f", price))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.isdTextSecondary)
                }

                if let exchange = deal.exchange {
                    Text(exchange.uppercased())
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.isdTextMuted)
                }
            }
        }
        .padding(.vertical, 8)
        .background(Color.isdCard)
    }
}

#Preview {
    SmartMoneyView()
}
