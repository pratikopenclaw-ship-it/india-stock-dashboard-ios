//
//  SignalAccuracyView.swift
//  ISDStockDashboard
//

import SwiftUI

struct SignalAccuracyView: View {
    @State private var accuracy: SignalAccuracyResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var days = 5

    private let api = APIClient.shared
    private let dayOptions = [5, 10, 15, 30]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.isdBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        if isLoading {
                            ProgressView("Loading accuracy data...")
                                .tint(.isdTextSecondary)
                                .padding()
                        } else if let error = errorMessage {
                            ContentUnavailableView {
                                Label("Error", systemImage: "exclamationmark.triangle")
                            } description: { Text(error) }
                        } else if let acc = accuracy {
                            overallSection(acc)
                            breakdownSection(acc)
                            if !acc.recent_results.isEmpty {
                                recentResultsSection(acc)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Signal Accuracy")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("Days", selection: $days) {
                        ForEach(dayOptions, id: \.self) { d in
                            Text("\(d)D").tag(d)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: days) { _, _ in
                        Task { await loadData() }
                    }
                }
            }
            .refreshable { await loadData() }
            .task { await loadData() }
        }
    }

    private func overallSection(_ acc: SignalAccuracyResponse) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                statBox(title: "ACCURACY", value: String(format: "%.1f%%", acc.overall_accuracy), color: accColor(acc.overall_accuracy))
                statBox(title: "EVALUATED", value: "\(acc.evaluated)", color: .isdAccent)
            }
            HStack(spacing: 16) {
                statBox(title: "CORRECT", value: "\(acc.correct)", color: .isdGreen)
                statBox(title: "INCORRECT", value: "\(acc.evaluated - acc.correct)", color: .isdRed)
            }
        }
        .padding()
        .background(Color.isdCard)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
        .cornerRadius(6)
    }

    private func breakdownSection(_ acc: SignalAccuracyResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SIGNAL BREAKDOWN")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.isdTextMuted)
                .tracking(0.5)

            VStack(spacing: 8) {
                ForEach(Array(acc.signal_breakdown.keys.sorted()), id: \.self) { key in
                    if let stat = acc.signal_breakdown[key] {
                        HStack {
                            Text(key.replacingOccurrences(of: "_", with: " ").uppercased())
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(.isdTextPrimary)
                            Spacer()
                            Text("\(stat.correct)/\(stat.total)")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.isdTextSecondary)
                            Text(String(format: "%.0f%%", stat.accuracy))
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundStyle(accColor(stat.accuracy))
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding()
            .background(Color.isdCard)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
            .cornerRadius(6)
        }
    }

    private func recentResultsSection(_ acc: SignalAccuracyResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECENT RESULTS")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.isdTextMuted)
                .tracking(0.5)

            VStack(spacing: 0) {
                ForEach(acc.recent_results.prefix(10), id: \.ticker) { result in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.ticker)
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.isdTextPrimary)
                            Text(result.signal.uppercased())
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundColor(.isdTextMuted)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%.2f%%", result.pct_change))
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Color.profitLossColor(result.pct_change))
                            Image(systemName: result.correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(result.correct ? .isdGreen : .isdRed)
                                .font(.caption)
                        }
                    }
                    .padding(.vertical, 8)
                    .background(Color.isdCard)
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
            .cornerRadius(6)
        }
    }

    private func statBox(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.isdTextMuted)
                .tracking(0.3)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(color.opacity(0.25), lineWidth: 1))
        .cornerRadius(4)
    }

    private func accColor(_ acc: Double) -> Color {
        if acc >= 70 { return .isdGreen }
        if acc >= 50 { return .isdGold }
        return .isdRed
    }

    private func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            accuracy = try await api.fetchSignalAccuracy(days: days)
        } catch {
            errorMessage = "Failed to load accuracy data"
        }
        isLoading = false
    }
}

#Preview {
    SignalAccuracyView()
}
