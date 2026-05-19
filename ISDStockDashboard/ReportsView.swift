//
//  ReportsView.swift
//  ISDStockDashboard
//

import SwiftUI

struct ReportsView: View {
    @State private var reports: [ResearchReport] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let api = APIClient.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.isdBackground.ignoresSafeArea()
                List {
                    if isLoading {
                        Section {
                            ProgressView("Loading reports...")
                                .tint(.isdTextSecondary)
                                .padding()
                        }
                    } else if let error = errorMessage {
                        Section {
                            ContentUnavailableView {
                                Label("Error", systemImage: "exclamationmark.triangle")
                            } description: { Text(error) }
                        }
                    } else if reports.isEmpty {
                        Section {
                            ContentUnavailableView {
                                Label("No Reports", systemImage: "document")
                            } description: {
                                Text("No research reports available")
                            }
                        }
                    } else {
                        ForEach(reports) { report in
                            ReportRow(report: report)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Research Reports")
            .refreshable { await loadData() }
            .task { await loadData() }
        }
    }

    private func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            reports = try await api.fetchResearchReports()
        } catch {
            errorMessage = "Failed to load reports"
        }
        isLoading = false
    }
}

struct ReportRow: View {
    let report: ResearchReport

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if let symbol = report.symbol {
                    Text(symbol)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.isdAccent)
                }
                if let rating = report.rating {
                    Text(rating.uppercased())
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .foregroundColor(ratingColor)
                        .background(ratingColor.opacity(0.10))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(ratingColor.opacity(0.30), lineWidth: 1))
                        .cornerRadius(4)
                }
                Spacer()
            }

            Text(report.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.isdTextPrimary)
                .lineLimit(2)

            if let broker = report.broker {
                Text(broker)
                    .font(.caption)
                    .foregroundColor(.isdTextMuted)
            }

            HStack {
                if let target = report.target_price {
                    Text("Target: ₹\(String(format: "%.0f", target))")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.isdGold)
                }
                Spacer()
                if let date = report.date {
                    Text(date.prefix(10))
                        .font(.caption)
                        .foregroundColor(.isdTextMuted)
                }
            }

            if let summary = report.summary {
                Text(summary)
                    .font(.caption)
                    .foregroundColor(.isdTextSecondary)
                    .lineLimit(3)
            }
        }
        .padding(.vertical, 8)
        .background(Color.isdCard)
    }

    private var ratingColor: Color {
        guard let rating = report.rating?.lowercased() else { return .isdAccent }
        if rating.contains("buy") { return .isdGreen }
        if rating.contains("sell") { return .isdRed }
        if rating.contains("hold") { return .isdGold }
        return .isdAccent
    }
}

#Preview {
    ReportsView()
}
