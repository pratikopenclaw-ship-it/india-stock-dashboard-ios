//
//  SignalsView.swift
//  ISDStockDashboard
//

import SwiftUI

struct SignalsView: View {
    @State private var signals: [TradingSignal] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedSignal: TradingSignal?

    private let api = APIClient.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.isdBackground.ignoresSafeArea()
                List {
                    if isLoading {
                        Section {
                            ProgressView("Loading signals...")
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
                                    Task { await loadSignals() }
                                }
                            }
                        }
                    } else if signals.isEmpty {
                        Section {
                            ContentUnavailableView {
                                Label("No Signals", systemImage: "chart.line.uptrend.xyaxis")
                            } description: {
                                Text("No trading signals available right now")
                            }
                        }
                    } else {
                        summarySection
                        ForEach(signals) { signal in
                            SignalRow(signal: signal)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedSignal = signal
                                }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("AI Signals")
            .refreshable {
                await loadSignals()
            }
            .task {
                await loadSignals()
            }
            .sheet(item: $selectedSignal) { signal in
                SignalDetailView(signal: signal)
            }
        }
    }

    private var summarySection: some View {
        let counts = signalCounts
        return Section {
            HStack(spacing: 12) {
                SignalCountBadge(count: counts.strongBuy, label: "STRONG BUY", color: .isdGreen)
                SignalCountBadge(count: counts.buy, label: "BUY", color: .isdGreen.opacity(0.7))
                SignalCountBadge(count: counts.hold, label: "HOLD", color: .isdAccent)
                SignalCountBadge(count: counts.sell, label: "SELL", color: .isdRed.opacity(0.7))
                SignalCountBadge(count: counts.strongSell, label: "STRONG SELL", color: .isdRed)
            }
            .padding(.vertical, 8)
        }
        .listRowBackground(Color.isdCard)
    }

    private var signalCounts: (strongBuy: Int, buy: Int, hold: Int, sell: Int, strongSell: Int) {
        let sb = signals.filter { $0.signal == "strong_buy" }.count
        let b = signals.filter { $0.signal == "buy" }.count
        let h = signals.filter { $0.signal == "hold" }.count
        let s = signals.filter { $0.signal == "sell" }.count
        let ss = signals.filter { $0.signal == "strong_sell" }.count
        return (sb, b, h, s, ss)
    }

    private func loadSignals() async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await api.fetchMarketSignals()
            signals = response.signals
        } catch APIError.unauthorized {
            errorMessage = "Please sign in to view signals"
        } catch {
            errorMessage = "Failed to load signals"
        }
        isLoading = false
    }
}

struct SignalRow: View {
    let signal: TradingSignal

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(signal.symbol)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(.isdTextPrimary)

                    SignalBadge(signal: signal.signal)

                    Spacer()
                }

                HStack(spacing: 4) {
                    Text("PRICE")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.isdTextMuted)
                        .tracking(0.3)

                    Text(String(format: "₹%.2f", signal.current_price))
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(.isdTextPrimary)
                }

                if let rr = signal.risk_reward {
                    HStack(spacing: 4) {
                        Text("R:R")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.isdTextMuted)
                            .tracking(0.3)

                        Text(String(format: "%.2f", rr))
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.isdAccent)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.0f%%", signal.confidence))
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(signalColor)

                if let horizon = signal.time_horizon {
                    Text(horizon.uppercased())
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.isdTextMuted)
                        .tracking(0.3)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.isdCard)
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
    }

    private var signalColor: Color {
        switch signal.signal {
        case "strong_buy", "buy": return .isdGreen
        case "strong_sell", "sell": return .isdRed
        default: return .isdAccent
        }
    }
}

struct SignalBadge: View {
    let signal: String

    var body: some View {
        let (color, label) = badgeProps
        Text(label)
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .foregroundColor(color)
            .background(color.opacity(0.10))
            .tracking(0.3)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.30), lineWidth: 1))
            .cornerRadius(6)
    }

    private var badgeProps: (Color, String) {
        switch signal {
        case "strong_buy": return (.isdGreen, "STRONG BUY")
        case "buy": return (.isdGreen.opacity(0.8), "BUY")
        case "strong_sell": return (.isdRed, "STRONG SELL")
        case "sell": return (.isdRed.opacity(0.8), "SELL")
        default: return (.isdAccent, "HOLD")
        }
    }
}

struct SignalCountBadge: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 7, weight: .medium, design: .monospaced))
                .foregroundColor(.isdTextMuted)
                .tracking(0.3)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(color.opacity(0.10))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.30), lineWidth: 1))
        .cornerRadius(6)
    }
}

struct SignalDetailView: View {
    let signal: TradingSignal
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.isdBackground.ignoresSafeArea()
                List {
                    headerSection

                    if let entry = signal.entry_price, let exit = signal.exit_target, let stop = signal.stop_loss {
                        tradeTargetsSection(entry: entry, exit: exit, stop: stop)
                    }

                    indicatorsSection
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(signal.symbol)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SignalBadge(signal: signal.signal)
                    Spacer()
                    Text(String(format: "%.0f%% CONFIDENCE", signal.confidence))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(signalColor)
                        .tracking(0.3)
                }

                Text(String(format: "₹%.2f", signal.current_price))
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.isdTextPrimary)

                if let horizon = signal.time_horizon {
                    Text("Time Horizon: \(horizon)")
                        .font(.subheadline)
                        .foregroundColor(.isdTextSecondary)
                }

                Text(signal.recommendation)
                    .font(.subheadline)
                    .foregroundColor(.isdTextSecondary)
                    .lineLimit(nil)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.isdCard)
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
        }
    }

    private func tradeTargetsSection(entry: Double, exit: Double, stop: Double) -> some View {
        Section {
            HStack(spacing: 16) {
                TargetColumn(label: "ENTRY", value: entry, color: .isdAccent)
                TargetColumn(label: "TARGET", value: exit, color: .isdGreen)
                TargetColumn(label: "STOP", value: stop, color: .isdRed)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.isdCard)
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
        } header: {
            Text("TRADE TARGETS")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.isdTextMuted)
                .tracking(0.3)
        }
    }

    private var indicatorsSection: some View {
        Section {
            ForEach(signal.indicators, id: \.name) { indicator in
                HStack {
                    Text(indicator.name)
                        .font(.subheadline)
                        .foregroundColor(.isdTextPrimary)

                    Spacer()

                    Text(String(format: "%.2f", indicator.score))
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(indicatorColor(indicator.score))
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 12)
                .background(Color.isdCard)
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
            }
        } header: {
            Text("INDICATORS")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.isdTextMuted)
                .tracking(0.3)
        }
    }

    private var signalColor: Color {
        switch signal.signal {
        case "strong_buy", "buy": return .isdGreen
        case "strong_sell", "sell": return .isdRed
        default: return .isdAccent
        }
    }

    private func indicatorColor(_ score: Double) -> Color {
        if score > 0.3 { return .isdGreen }
        if score < -0.3 { return .isdRed }
        return .isdAccent
    }
}

struct TargetColumn: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.isdTextMuted)
                .tracking(0.3)

            Text(String(format: "₹%.2f", value))
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    SignalsView()
}
