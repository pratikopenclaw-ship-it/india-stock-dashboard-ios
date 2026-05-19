//
//  StockChartView.swift
//  ISDStockDashboard
//

import SwiftUI

struct StockChartView: View {
    let symbol: String

    @State private var chartData: StockChartResponse?
    @State private var selectedTimeframe = "1M"
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let api = APIClient.shared
    private let timeframes = ["1D", "1W", "1M", "3M", "1Y", "MAX"]

    var body: some View {
        VStack(spacing: 12) {
            timeframePicker

            if isLoading {
                ProgressView("Loading chart...")
                    .tint(.isdTextSecondary)
                    .padding()
            } else if let error = errorMessage {
                ContentUnavailableView {
                    Label("Chart Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Retry") {
                        Task { await loadChart() }
                    }
                }
            } else if let chart = chartData, !chart.data.isEmpty {
                CandlestickChart(data: chart.data)
                    .frame(height: 240)
                    .padding(.horizontal, 4)

                chartStats(chart: chart)
            } else {
                ContentUnavailableView {
                    Label("No Data", systemImage: "chart.line.uptrend.xyaxis")
                } description: {
                    Text("No chart data available for this symbol")
                }
            }
        }
        .padding(.vertical, 8)
        .background(Color.isdCard)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
        .cornerRadius(6)
        .task {
            await loadChart()
        }
    }

    private var timeframePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(timeframes, id: \.self) { tf in
                    Button {
                        selectedTimeframe = tf
                        Task { await loadChart() }
                    } label: {
                        Text(tf)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .foregroundColor(selectedTimeframe == tf ? .isdTextPrimary : .isdAccent)
                            .background(selectedTimeframe == tf ? Color.isdAccent : Color.isdAccent.opacity(0.10))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdAccent.opacity(selectedTimeframe == tf ? 0 : 0.30), lineWidth: 1))
                            .cornerRadius(6)
                    }
                }
            }
            .padding(.horizontal, 12)
        }
    }

    @ViewBuilder
    private func chartStats(chart: StockChartResponse) -> some View {
        let data = chart.data
        if let first = data.first, let last = data.last {
            let high = data.map(\.high).max() ?? 0
            let low = data.map(\.low).min() ?? 0
            let change = last.close - first.open
            let changePct = first.open > 0 ? (change / first.open) * 100 : 0

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("HIGH")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.isdTextMuted)
                    Text(String(format: "₹%.2f", high))
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(.isdTextPrimary)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 2) {
                    Text("LOW")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.isdTextMuted)
                    Text(String(format: "₹%.2f", low))
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(.isdTextPrimary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("CHANGE")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.isdTextMuted)
                    Text(String(format: "%+.2f (%+.2f%%)", change, changePct))
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(change >= 0 ? .isdGreen : .isdRed)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 4)
        }
    }

    private func loadChart() async {
        isLoading = true
        errorMessage = nil
        do {
            chartData = try await api.fetchStockChart(symbol: symbol, timeframe: selectedTimeframe)
        } catch {
            errorMessage = "Failed to load chart"
        }
        isLoading = false
    }
}

// MARK: - Candlestick Chart Renderer (Canvas-based)

struct CandlestickChart: View {
    let data: [ChartDataPoint]

    var body: some View {
        Canvas { context, size in
            let width = size.width
            let height = size.height
            let padding: CGFloat = 4
            let chartHeight = height - padding * 2
            let chartWidth = width - padding * 2

            let prices = data.flatMap { [$0.high, $0.low] }
            guard let minPrice = prices.min(), let maxPrice = prices.max(), maxPrice > minPrice else { return }

            let priceRange = maxPrice - minPrice
            let spacing = chartWidth / CGFloat(max(1, data.count))
            let candleWidth = max(1, spacing * 0.65)

            // Draw grid lines
            for i in 0..<5 {
                let y = padding + chartHeight * CGFloat(i) / 4
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: width, y: y))
                context.stroke(path, with: .color(Color.isdBorder.opacity(0.25)), lineWidth: 0.5)
            }

            // Draw candles
            for (index, candle) in data.enumerated() {
                let x = padding + CGFloat(index) * spacing + spacing / 2
                let yHigh = padding + chartHeight - CGFloat((candle.high - minPrice) / priceRange) * chartHeight
                let yLow = padding + chartHeight - CGFloat((candle.low - minPrice) / priceRange) * chartHeight
                let yOpen = padding + chartHeight - CGFloat((candle.open - minPrice) / priceRange) * chartHeight
                let yClose = padding + chartHeight - CGFloat((candle.close - minPrice) / priceRange) * chartHeight

                let isGreen = candle.close >= candle.open
                let color = isGreen ? Color.isdGreen : Color.isdRed

                // Wick
                var wick = Path()
                wick.move(to: CGPoint(x: x, y: yHigh))
                wick.addLine(to: CGPoint(x: x, y: yLow))
                context.stroke(wick, with: .color(color), lineWidth: 1)

                // Body
                let bodyTop = min(yOpen, yClose)
                let bodyBottom = max(yOpen, yClose)
                let bodyHeight = max(1, bodyBottom - bodyTop)
                let bodyRect = CGRect(x: x - candleWidth / 2, y: bodyTop, width: candleWidth, height: bodyHeight)
                context.fill(Path(bodyRect), with: .color(color))
            }
        }
    }
}

#Preview {
    StockChartView(symbol: "RELIANCE")
        .background(Color.isdBackground)
}
