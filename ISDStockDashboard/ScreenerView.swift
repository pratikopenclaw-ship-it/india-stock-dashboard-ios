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
    @State private var showingFilters = false
    @State private var aiScoreMin: Double = 0
    @State private var sortBy = "composite_score"
    @State private var sortOptions = ["composite_score", "change_percent", "ai_score", "rsi_14", "pe_ratio"]
    @State private var page = 1
    @State private var hasMore = false

    private let api = APIClient.shared
    private let filters = ["STRONG_BUY", "BUY", "HOLD", "SELL", "STRONG_SELL"]
    private let sectors = ["Financials", "IT", "Healthcare", "Energy", "Consumer", "Auto", "Metals", "Real Estate", "Telecom"]

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
                        sortBar
                        stocksSection
                        if hasMore {
                            loadMoreButton
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Screener")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingFilters = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(.isdAccent)
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                FilterPanel(
                    sectors: sectors,
                    selectedSector: $selectedSector,
                    aiScoreMin: $aiScoreMin,
                    sortBy: $sortBy,
                    onApply: {
                        page = 1
                        Task { await loadData() }
                    }
                )
            }
            .refreshable {
                page = 1
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
                            .foregroundColor(selectedFilter == nil ? .isdTextPrimary : .isdAccent)
                            .background(selectedFilter == nil ? Color.isdAccent : Color.isdAccent.opacity(0.10))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdAccent.opacity(selectedFilter == nil ? 0 : 0.30), lineWidth: 1))
                            .cornerRadius(6)
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
                                .foregroundColor(selectedFilter == filter ? .isdTextPrimary : recommendationColor(filter))
                                .background(selectedFilter == filter ? recommendationColor(filter) : recommendationColor(filter).opacity(0.10))
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(recommendationColor(filter).opacity(selectedFilter == filter ? 0 : 0.30), lineWidth: 1))
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            }
            .background(Color.isdCard)
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
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
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
        }
    }

    private var stocksSection: some View {
        ForEach(stocks) { stock in
            ScreenerRow(stock: stock)
        }
    }

    private var sortBar: some View {
        HStack(spacing: 12) {
            Text("SORT")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.isdTextMuted)
                .tracking(0.3)
            Picker("Sort", selection: $sortBy) {
                ForEach(sortOptions, id: \.self) { option in
                    Text(formatSortLabel(option)).tag(option)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: sortBy) { _, _ in
                page = 1
                Task { await loadData() }
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.isdCard)
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
    }

    private var loadMoreButton: some View {
        Button {
            page += 1
            Task { await loadData() }
        } label: {
            HStack {
                if isLoading {
                    ProgressView().tint(.isdAccent)
                } else {
                    Text("Load More")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.isdAccent)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .disabled(isLoading)
    }

    private func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            async let statsTask = api.fetchScreenerStats()
            async let stocksTask = api.fetchScreenerStocks(
                recommendation: selectedFilter,
                sector: selectedSector,
                aiScoreMin: aiScoreMin > 0 ? aiScoreMin : nil,
                sortBy: sortBy,
                page: page,
                limit: 50
            )
            let (statsResult, stocksResult) = try await (statsTask, stocksTask)
            stats = statsResult
            if page == 1 {
                stocks = stocksResult.data
            } else {
                stocks.append(contentsOf: stocksResult.data)
            }
            hasMore = stocksResult.pagination.page < stocksResult.pagination.total_pages
        } catch APIError.unauthorized {
            errorMessage = "Please sign in to view screener"
        } catch {
            errorMessage = "Failed to load screener data"
        }
        isLoading = false
    }

    private func formatSortLabel(_ option: String) -> String {
        switch option {
        case "composite_score": return "AI Score"
        case "change_percent": return "Change %"
        case "ai_score": return "AI Raw"
        case "rsi_14": return "RSI"
        case "pe_ratio": return "P/E"
        default: return option
        }
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
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .foregroundColor(recColor(rec))
                            .background(recColor(rec).opacity(0.10))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(recColor(rec).opacity(0.30), lineWidth: 1))
                            .tracking(0.3)
                            .cornerRadius(6)
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
        .padding(.horizontal, 12)
        .background(Color.isdCard)
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
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
        .background(color.opacity(0.10))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.30), lineWidth: 1))
        .cornerRadius(6)
    }
}

struct FilterPanel: View {
    let sectors: [String]
    @Binding var selectedSector: String?
    @Binding var aiScoreMin: Double
    @Binding var sortBy: String
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Sector") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Button {
                                selectedSector = nil
                            } label: {
                                Text("All")
                                    .font(.system(size: 11, weight: .semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .foregroundColor(selectedSector == nil ? .isdTextPrimary : .isdAccent)
                                    .background(selectedSector == nil ? Color.isdAccent : Color.isdAccent.opacity(0.10))
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdAccent.opacity(selectedSector == nil ? 0 : 0.30), lineWidth: 1))
                                    .cornerRadius(6)
                            }
                            ForEach(sectors, id: \.self) { sector in
                                Button {
                                    selectedSector = sector
                                } label: {
                                    Text(sector)
                                        .font(.system(size: 11, weight: .semibold))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .foregroundColor(selectedSector == sector ? .isdTextPrimary : .isdAccent)
                                        .background(selectedSector == sector ? Color.isdAccent : Color.isdAccent.opacity(0.10))
                                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdAccent.opacity(selectedSector == sector ? 0 : 0.30), lineWidth: 1))
                                        .cornerRadius(6)
                                }
                            }
                        }
                    }
                }

                Section("AI Score Minimum") {
                    VStack {
                        HStack {
                            Text("0")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.isdTextMuted)
                            Spacer()
                            Text(String(format: "%.0f", aiScoreMin))
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                                .foregroundColor(.isdAccent)
                            Spacer()
                            Text("100")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.isdTextMuted)
                        }
                        Slider(value: $aiScoreMin, in: 0...100, step: 1)
                            .tint(.isdAccent)
                    }
                }

                Section("Sort By") {
                    Picker("Sort", selection: $sortBy) {
                        Text("AI Score").tag("composite_score")
                        Text("Change %").tag("change_percent")
                        Text("AI Raw").tag("ai_score")
                        Text("RSI").tag("rsi_14")
                        Text("P/E").tag("pe_ratio")
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply()
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ScreenerView()
}
