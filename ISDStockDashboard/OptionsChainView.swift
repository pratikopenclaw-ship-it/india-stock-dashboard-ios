//
//  OptionsChainView.swift
//  ISDStockDashboard
//

import SwiftUI

struct OptionsChainView: View {
    @State private var symbol = "NIFTY"
    @State private var expiryDates: [String] = []
    @State private var selectedExpiry: String?
    @State private var chain: OptionsChain?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let api = APIClient.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.isdBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    searchBar
                    if let summary = chain?.summary {
                        summaryBar(summary)
                    }
                    chainTable
                }
            }
            .navigationTitle("Options Chain")
            .toolbar {
                if !expiryDates.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Picker("Expiry", selection: $selectedExpiry) {
                            ForEach(expiryDates, id: \.self) { date in
                                Text(date).tag(date as String?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            TextField("Symbol (e.g. NIFTY, RELIANCE)", text: $symbol)
                .textInputAutocapitalization(.characters)
                .padding()
                .background(Color.isdCard)
                .foregroundColor(.isdTextPrimary)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
                .cornerRadius(6)

            Button {
                Task { await loadData() }
            } label: {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.isdAccent)
                    .padding()
            }
        }
        .padding()
    }

    private func summaryBar(_ summary: OptionsSummary) -> some View {
        HStack(spacing: 12) {
            summaryItem(label: "CE OI", value: String(format: "%.1fM", Double(summary.total_ce_oi) / 1_000_000), color: .isdRed)
            summaryItem(label: "PE OI", value: String(format: "%.1fM", Double(summary.total_pe_oi) / 1_000_000), color: .isdGreen)
            summaryItem(label: "PCR", value: String(format: "%.2f", summary.pcr), color: summary.pcr > 1 ? .isdGreen : .isdRed)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private func summaryItem(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.isdTextMuted)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.10))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(color.opacity(0.30), lineWidth: 1))
        .cornerRadius(4)
    }

    private var chainTable: some View {
        ScrollView {
            if isLoading {
                ProgressView("Loading...")
                    .tint(.isdTextSecondary)
                    .padding()
            } else if let error = errorMessage {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: { Text(error) }
            } else if let strikes = chain?.strikes {
                VStack(spacing: 0) {
                    headerRow
                    ForEach(strikes) { strike in
                        strikeRow(strike)
                    }
                }
                .padding(.horizontal)
            } else {
                ContentUnavailableView {
                    Label("Search", systemImage: "magnifyingglass")
                } description: {
                    Text("Enter a symbol to view options chain")
                }
            }
        }
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            headerCell("CE OI", width: 70)
            headerCell("CE IV", width: 50)
            headerCell("STRIKE", width: 70, highlight: true)
            headerCell("PE IV", width: 50)
            headerCell("PE OI", width: 70)
        }
        .font(.system(size: 9, weight: .medium, design: .monospaced))
        .foregroundColor(.isdTextMuted)
        .padding(.vertical, 6)
        .background(Color.isdCard)
    }

    private func headerCell(_ text: String, width: CGFloat, highlight: Bool = false) -> some View {
        Text(text)
            .frame(width: width, alignment: .center)
            .foregroundColor(highlight ? .isdAccent : .isdTextMuted)
    }

    private func strikeRow(_ strike: StrikeData) -> some View {
        HStack(spacing: 0) {
            dataCell(String(format: "%.0f", Double(strike.ce_oi) / 1000), width: 70, color: .isdRed)
            dataCell(String(format: "%.1f", strike.ce_iv), width: 50, color: .isdTextSecondary)
            strikeCell(strike)
            dataCell(String(format: "%.1f", strike.pe_iv), width: 50, color: .isdTextSecondary)
            dataCell(String(format: "%.0f", Double(strike.pe_oi) / 1000), width: 70, color: .isdGreen)
        }
        .padding(.vertical, 4)
        .background(strike.is_atm ? Color.isdAccent.opacity(0.10) : Color.isdCard)
    }

    private func strikeCell(_ strike: StrikeData) -> some View {
        Text(String(format: "%.0f", Double(strike.strike)))
            .font(.system(size: 12, weight: strike.is_atm ? .bold : .semibold, design: .monospaced))
            .foregroundColor(strike.is_atm ? .isdAccent : .isdTextPrimary)
            .frame(width: 70, alignment: .center)
    }

    private func dataCell(_ text: String, width: CGFloat, color: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundColor(color)
            .frame(width: width, alignment: .center)
    }

    private func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            expiryDates = try await api.fetchOptionsExpiryDates(symbol: symbol)
            selectedExpiry = expiryDates.first
            chain = try await api.fetchOptionsChain(symbol: symbol, expiry: selectedExpiry)
        } catch {
            errorMessage = "Failed to load options chain"
        }
        isLoading = false
    }
}

#Preview {
    OptionsChainView()
}
