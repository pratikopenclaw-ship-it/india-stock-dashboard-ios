//
//  TradePlannerView.swift
//  ISDStockDashboard
//

import SwiftUI

struct TradePlannerView: View {
    @State private var symbol = ""
    @State private var plan: TradePlan?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let api = APIClient.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.isdBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        searchBar

                        if isLoading {
                            ProgressView("Loading plan...")
                                .tint(.isdTextSecondary)
                                .padding()
                        } else if let error = errorMessage {
                            ContentUnavailableView {
                                Label("Error", systemImage: "exclamationmark.triangle")
                            } description: { Text(error) }
                        } else if let p = plan {
                            planSection(p)
                        } else if !symbol.isEmpty {
                            ContentUnavailableView {
                                Label("No Plan", systemImage: "doc.text")
                            } description: {
                                Text("Enter a symbol to generate a trade plan")
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Trade Planner")
        }
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            TextField("Symbol (e.g. RELIANCE)", text: $symbol)
                .textInputAutocapitalization(.characters)
                .padding()
                .background(Color.isdCard)
                .foregroundColor(.isdTextPrimary)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
                .cornerRadius(6)

            Button {
                Task { await loadPlan() }
            } label: {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(.isdAccent)
            }
        }
    }

    private func planSection(_ p: TradePlan) -> some View {
        VStack(spacing: 16) {
            if let rec = p.recommendation {
                HStack {
                    Text(rec.uppercased())
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(recColor(rec))
                    Spacer()
                }
                .padding()
                .background(recColor(rec).opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(recColor(rec).opacity(0.25), lineWidth: 1))
                .cornerRadius(6)
            }

            HStack(spacing: 16) {
                planCard(label: "POSITION SIZE", value: p.position_size != nil ? String(format: "%.0f", p.position_size!) : "--", color: .isdAccent)
                planCard(label: "RISK/TRADE", value: p.risk_per_trade != nil ? String(format: "%.1f%%", p.risk_per_trade! * 100) : "--", color: .isdGold)
            }

            HStack(spacing: 16) {
                planCard(label: "STOP LOSS", value: p.stop_loss != nil ? String(format: "₹%.2f", p.stop_loss!) : "--", color: .isdRed)
                planCard(label: "TAKE PROFIT", value: p.take_profit != nil ? String(format: "₹%.2f", p.take_profit!) : "--", color: .isdGreen)
            }

            if let rr = p.risk_reward {
                HStack {
                    Text("RISK : REWARD")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.isdTextMuted)
                    Spacer()
                    Text(String(format: "1 : %.2f", rr))
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(rr >= 2 ? .isdGreen : rr >= 1 ? .isdGold : .isdRed)
                }
                .padding()
                .background(Color.isdCard)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
                .cornerRadius(6)
            }

            if let max = p.max_position_value {
                HStack {
                    Text("MAX POSITION")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.isdTextMuted)
                    Spacer()
                    Text(String(format: "₹%.0f", max))
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(.isdTextPrimary)
                }
                .padding()
                .background(Color.isdCard)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
                .cornerRadius(6)
            }
        }
    }

    private func planCard(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.isdTextMuted)
                .tracking(0.3)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(color.opacity(0.25), lineWidth: 1))
        .cornerRadius(4)
    }

    private func recColor(_ rec: String) -> Color {
        let lower = rec.lowercased()
        if lower.contains("buy") { return .isdGreen }
        if lower.contains("sell") { return .isdRed }
        return .isdGold
    }

    private func loadPlan() async {
        guard !symbol.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        do {
            plan = try await api.fetchTradePlanner(symbol: symbol)
        } catch {
            errorMessage = "Failed to load trade plan"
        }
        isLoading = false
    }
}

#Preview {
    TradePlannerView()
}
