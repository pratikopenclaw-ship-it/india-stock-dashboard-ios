//
//  StockDetailView.swift
//  ISDStockDashboard
//

import SwiftUI

struct StockDetailView: View {
    let symbol: String
    let name: String

    @State private var stockDetail: StockDetail?
    @State private var sentiment: StockSentiment?
    @State private var srLevels: SupportResistance?
    @State private var deepAnalysis: DeepAnalysis?
    @State private var news: [NewsItem] = []
    @State private var livePrice: LivePriceData?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingAddAlert = false
    @State private var selectedTab = 0
    @State private var priceUpdateTask: Task<Void, Never>?

    private let api = APIClient.shared
    private let tabs = ["Overview", "Analysis", "News"]

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
                    StockChartView(symbol: symbol)

                    if let sentiment = sentiment {
                        sentimentSection(sentiment)
                    }

                    if let sr = srLevels {
                        supportResistanceSection(sr)
                    }

                    tabPicker

                    tabContent(stock)
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
                let displayPrice = livePrice?.price ?? stock.current_price
                if let price = displayPrice {
                    Text(String(format: "₹%.2f", price))
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(.isdTextPrimary)
                } else {
                    Text("₹--")
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(.isdTextMuted)
                }

                let current = livePrice?.price ?? stock.current_price
                let previous = stock.previous_close
                if let previous = previous, let current = current {
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

            if livePrice != nil {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.isdGreen)
                        .frame(width: 6, height: 6)
                    Text("LIVE")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.isdGreen)
                }
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

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button {
                    selectedTab = index
                } label: {
                    Text(tabs[index])
                        .font(.system(size: 13, weight: selectedTab == index ? .semibold : .medium))
                        .foregroundColor(selectedTab == index ? .isdAccent : .isdTextMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selectedTab == index ? Color.isdAccent.opacity(0.10) : Color.clear)
                }
            }
        }
        .background(Color.isdCard)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
        .cornerRadius(6)
    }

    private func tabContent(_ stock: StockDetail) -> some View {
        Group {
            switch selectedTab {
            case 0:
                statsGrid(stock)
                actionButtons
            case 1:
                analysisTab
            case 2:
                newsTab
            default:
                EmptyView()
            }
        }
    }

    private var analysisTab: some View {
        VStack(spacing: 16) {
            if let analysis = deepAnalysis {
                deepAnalysisSection(analysis)
            } else {
                ContentUnavailableView {
                    Label("No Analysis", systemImage: "brain")
                } description: {
                    Text("Deep analysis not available for this stock")
                }
            }
        }
    }

    private var newsTab: some View {
        VStack(spacing: 12) {
            if news.isEmpty {
                ContentUnavailableView {
                    Label("No News", systemImage: "newspaper")
                } description: {
                    Text("No recent news for this stock")
                }
            } else {
                ForEach(news.prefix(10)) { item in
                    StockNewsRow(item: item)
                }
            }
        }
    }

    private func sentimentSection(_ sentiment: StockSentiment) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SENTIMENT")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.isdTextMuted)
                .tracking(0.5)

            HStack(spacing: 16) {
                if let bullish = sentiment.bullish_pct {
                    sentimentBar(label: "BULLISH", value: bullish, color: .isdGreen)
                }
                if let bearish = sentiment.bearish_pct {
                    sentimentBar(label: "BEARISH", value: bearish, color: .isdRed)
                }
                if let neutral = sentiment.neutral_pct {
                    sentimentBar(label: "NEUTRAL", value: neutral, color: .isdTextMuted)
                }
            }

            if let overall = sentiment.overall {
                HStack {
                    Text("OVERALL")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.isdTextMuted)
                    Spacer()
                    Text(overall.uppercased())
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(sentimentColor(overall))
                }
            }
        }
        .padding()
        .background(Color.isdCard)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
        .cornerRadius(6)
    }

    private func sentimentBar(label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.isdTextMuted)
            Text(String(format: "%.0f%%", value))
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: geo.size.width * CGFloat(value / 100), height: 4)
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity)
    }

    private func sentimentColor(_ sentiment: String) -> Color {
        let lower = sentiment.lowercased()
        if lower.contains("bull") { return .isdGreen }
        if lower.contains("bear") { return .isdRed }
        return .isdGold
    }

    private func supportResistanceSection(_ sr: SupportResistance) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SUPPORT & RESISTANCE")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.isdTextMuted)
                .tracking(0.5)

            if !sr.resistance_levels.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("RESISTANCE")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.isdRed)
                    ForEach(sr.resistance_levels) { level in
                        levelRow(level, color: .isdRed)
                    }
                }
            }

            if !sr.support_levels.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("SUPPORT")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.isdGreen)
                    ForEach(sr.support_levels) { level in
                        levelRow(level, color: .isdGreen)
                    }
                }
            }
        }
        .padding()
        .background(Color.isdCard)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
        .cornerRadius(6)
    }

    private func levelRow(_ level: PriceLevel, color: Color) -> some View {
        HStack {
            Text(String(format: "₹%.2f", level.price))
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(color)
            Spacer()
            if let strength = level.strength {
                Text(strength.uppercased())
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.isdTextMuted)
            }
            if let touches = level.touches {
                Text("\(touches) touches")
                    .font(.caption)
                    .foregroundColor(.isdTextMuted)
            }
        }
    }

    private func deepAnalysisSection(_ analysis: DeepAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if let rec = analysis.recommendation {
                HStack {
                    Text("RECOMMENDATION")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.isdTextMuted)
                    Spacer()
                    Text(rec.uppercased())
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(recColor(rec))
                }
            }

            if let conf = analysis.confidence {
                HStack {
                    Text("CONFIDENCE")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.isdTextMuted)
                    Spacer()
                    Text(String(format: "%.0f%%", conf * 100))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(conf >= 0.7 ? .isdGreen : conf >= 0.5 ? .isdGold : .isdRed)
                }
            }

            if let summary = analysis.summary {
                analysisBlock(title: "SUMMARY", items: [summary])
            }
            if let strengths = analysis.strengths {
                analysisBlock(title: "STRENGTHS", items: strengths)
            }
            if let weaknesses = analysis.weaknesses {
                analysisBlock(title: "WEAKNESSES", items: weaknesses)
            }
            if let opportunities = analysis.opportunities {
                analysisBlock(title: "OPPORTUNITIES", items: opportunities)
            }
            if let threats = analysis.threats {
                analysisBlock(title: "THREATS", items: threats)
            }
            if let valuation = analysis.valuation {
                analysisBlock(title: "VALUATION", items: [valuation])
            }
        }
        .padding()
        .background(Color.isdCard)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
        .cornerRadius(6)
    }

    private func analysisBlock(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(.isdTextMuted)
                .tracking(0.3)
            ForEach(items, id: \.self) { item in
                Text("• \(item)")
                    .font(.subheadline)
                    .foregroundColor(.isdTextSecondary)
            }
        }
    }

    private func recColor(_ rec: String) -> Color {
        let lower = rec.lowercased()
        if lower.contains("buy") { return .isdGreen }
        if lower.contains("sell") { return .isdRed }
        return .isdGold
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
            async let detail = api.fetchStockDetail(symbol: symbol)
            async let sent = api.fetchStockSentiment(symbol: symbol)
            async let sr = api.fetchSupportResistance(symbol: symbol)
            async let analysis = api.fetchDeepAnalysis(symbol: symbol)
            async let newsData = api.fetchNews(symbol: symbol)

            stockDetail = try await detail
            sentiment = try? await sent
            srLevels = try? await sr
            deepAnalysis = try? await analysis
            news = (try? await newsData) ?? []

            startLivePricePolling()
        } catch {
            errorMessage = "Failed to load stock details"
        }
        isLoading = false
    }

    private func startLivePricePolling() {
        priceUpdateTask?.cancel()
        priceUpdateTask = Task {
            while !Task.isCancelled {
                do {
                    let price = try await api.fetchLivePrice(symbol: symbol)
                    await MainActor.run {
                        livePrice = price
                    }
                } catch {
                    // Silently fail on polling errors
                }
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            }
        }
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

struct StockNewsRow: View {
    let item: NewsItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(item.source)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .foregroundColor(.isdAccentLight)
                    .background(Color.isdAccent.opacity(0.10))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.isdAccent.opacity(0.30), lineWidth: 1))
                    .cornerRadius(4)

                if let sentiment = item.sentiment {
                    Text(sentiment.uppercased())
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(sentimentColor(sentiment))
                }

                Spacer()

                if let date = item.published_at {
                    Text(date.prefix(10))
                        .font(.caption)
                        .foregroundColor(.isdTextMuted)
                }
            }

            Text(item.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.isdTextPrimary)
                .lineLimit(3)
        }
        .padding(.vertical, 8)
        .background(Color.isdCard)
    }

    private func sentimentColor(_ sentiment: String) -> Color {
        let lower = sentiment.lowercased()
        if lower.contains("bull") || lower.contains("pos") { return .isdGreen }
        if lower.contains("bear") || lower.contains("neg") { return .isdRed }
        return .isdTextMuted
    }
}

#Preview {
    NavigationStack {
        StockDetailView(symbol: "RELIANCE", name: "Reliance Industries")
    }
}
