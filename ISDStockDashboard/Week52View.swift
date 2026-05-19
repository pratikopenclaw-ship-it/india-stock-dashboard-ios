//
//  Week52View.swift
//  ISDStockDashboard
//

import SwiftUI

struct Week52View: View {
    @State private var type = "high"
    @State private var response: Week52Response?
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let api = APIClient.shared
    private let types = ["high", "low"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.isdBackground.ignoresSafeArea()
                List {
                    if isLoading {
                        Section {
                            ProgressView("Loading...")
                                .tint(.isdTextSecondary)
                                .padding()
                        }
                    } else if let error = errorMessage {
                        Section {
                            ContentUnavailableView {
                                Label("Error", systemImage: "exclamationmark.triangle")
                            } description: { Text(error) }
                        }
                    } else if let stocks = response?.data {
                        ForEach(stocks) { stock in
                            Week52Row(stock: stock, type: type)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("52-Week Scanner")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("Type", selection: $type) {
                        Text("High").tag("high")
                        Text("Low").tag("low")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: type) { _, _ in
                        Task { await loadData() }
                    }
                }
            }
            .refreshable { await loadData() }
            .task { await loadData() }
        }
    }

    private func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            response = try await api.fetch52WeekData(type: type)
        } catch {
            errorMessage = "Failed to load data"
        }
        isLoading = false
    }
}

struct Week52Row: View {
    let stock: Week52Stock
    let type: String

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.symbol)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(.isdTextPrimary)
                Text(stock.company_name)
                    .font(.subheadline)
                    .foregroundColor(.isdTextSecondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let price = stock.close_price {
                    Text(String(format: "₹%.2f", price))
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundColor(.isdTextPrimary)
                }
                if type == "high", let dist = stock.distance_from_high {
                    Text(String(format: "%.1f%% from high", dist))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.isdRed)
                } else if type == "low", let dist = stock.distance_from_low {
                    Text(String(format: "%.1f%% from low", dist))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.isdGreen)
                }
            }
        }
        .padding(.vertical, 6)
        .background(Color.isdCard)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
        .cornerRadius(6)
    }
}

#Preview {
    Week52View()
}
