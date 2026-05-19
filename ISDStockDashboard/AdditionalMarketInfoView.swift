//
//  AdditionalMarketInfoView.swift
//  ISDStockDashboard
//

import SwiftUI

struct AdditionalMarketInfoView: View {
    @State private var breadth: MarketBreadth?
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let api = APIClient.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.isdBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        if isLoading {
                            ProgressView("Loading...")
                                .tint(.isdTextSecondary)
                                .padding()
                        } else if let error = errorMessage {
                            ContentUnavailableView {
                                Label("Error", systemImage: "exclamationmark.triangle")
                            } description: { Text(error) }
                        } else if let b = breadth {
                            marketBreadthSection(b)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Market Info")
            .refreshable { await loadData() }
            .task { await loadData() }
        }
    }

    private func marketBreadthSection(_ b: MarketBreadth) -> some View {
        VStack(spacing: 16) {
            Text("MARKET BREADTH")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.isdTextMuted)
                .tracking(0.3)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                statBox(title: "ADVANCES", value: "\(b.advances)", color: .isdGreen)
                statBox(title: "DECLINES", value: "\(b.declines)", color: .isdRed)
            }

            HStack(spacing: 16) {
                statBox(title: "UNCHANGED", value: "\(b.unchanged)", color: .isdTextMuted)
                statBox(title: "A/D RATIO", value: String(format: "%.2f", b.advance_decline_ratio ?? 0), color: (b.advance_decline_ratio ?? 0) >= 1 ? .isdGreen : .isdRed)
            }

            HStack(spacing: 16) {
                statBox(title: "52W HIGH", value: "\(b.new_52w_high)", color: .isdGreen)
                statBox(title: "52W LOW", value: "\(b.new_52w_low)", color: .isdRed)
            }

            // Visual bar
            GeometryReader { geo in
                let total = max(Double(b.advances + b.declines + b.unchanged), 1)
                HStack(spacing: 2) {
                    Rectangle()
                        .fill(Color.isdGreen)
                        .frame(width: geo.size.width * CGFloat(Double(b.advances) / total))
                    Rectangle()
                        .fill(Color.isdRed)
                        .frame(width: geo.size.width * CGFloat(Double(b.declines) / total))
                    Rectangle()
                        .fill(Color.isdTextMuted)
                        .frame(width: geo.size.width * CGFloat(Double(b.unchanged) / total))
                }
            }
            .frame(height: 12)
            .cornerRadius(6)
        }
        .padding()
        .background(Color.isdCard)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
        .cornerRadius(6)
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
        .background(color.opacity(0.10))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.30), lineWidth: 1))
        .cornerRadius(6)
    }

    private func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            breadth = try await api.fetchMarketBreadth()
        } catch {
            errorMessage = "Failed to load market breadth"
        }
        isLoading = false
    }
}

#Preview {
    AdditionalMarketInfoView()
}
