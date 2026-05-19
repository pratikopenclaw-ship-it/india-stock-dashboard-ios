//
//  HoldingsView.swift
//  ISDStockDashboard
//

import SwiftUI

struct HoldingsView: View {
    @State private var holdings: [UserHolding] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingCreateSheet = false
    @State private var correlation: CorrelationMatrix?

    private let api = APIClient.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.isdBackground.ignoresSafeArea()
                List {
                    if isLoading {
                        Section {
                            ProgressView("Loading holdings...")
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
                                    Task { await loadHoldings() }
                                }
                            }
                        }
                    } else if holdings.isEmpty {
                        Section {
                            ContentUnavailableView {
                                Label("No Holdings", systemImage: "briefcase")
                            } description: {
                                Text("Add your first stock holding to track P&L")
                            }
                        }
                    } else {
                        portfolioSummarySection
                        holdingsListSection
                        if let corr = correlation {
                            sectorSection(sectors: corr.sectors)
                            if !corr.correlations.isEmpty {
                                correlationMatrixSection(corr)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Portfolio")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.isdAccent)
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateHoldingView { newHolding in
                    holdings.append(newHolding)
                }
            }
            .refreshable {
                await loadHoldings()
            }
            .task {
                await loadHoldings()
            }
        }
    }

    private var portfolioSummarySection: some View {
        let totalValue = holdings.reduce(0) { $0 + ($1.quantity * $1.buy_price) }
        return Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("PORTFOLIO VALUE")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.isdTextMuted)
                    .tracking(0.3)

                Text(String(format: "₹%.2f", totalValue))
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.isdTextPrimary)

                Text("\(holdings.count) STOCKS")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.isdTextMuted)
                    .tracking(0.3)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.isdCard)
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
        }
    }

    private var holdingsListSection: some View {
        Section {
            ForEach(holdings) { holding in
                HoldingRow(holding: holding)
            }
            .onDelete(perform: deleteHoldings)
        } header: {
            Text("HOLDINGS")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.isdTextMuted)
                .tracking(0.3)
        }
    }

    private func sectorSection(sectors: [SectorAllocation]) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(sectors.prefix(5), id: \.sector) { sector in
                    HStack {
                        Text(sector.sector.uppercased())
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.isdTextMuted)

                        Spacer()

                        Text(String(format: "₹%.2f (%+.1f%%)", sector.value, sector.pct))
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.isdTextPrimary)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.isdCard)
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
        } header: {
            Text("SECTOR ALLOCATION")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.isdTextMuted)
                .tracking(0.3)
        }
    }

    private func correlationMatrixSection(_ corr: CorrelationMatrix) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                let symbols = corr.correlations.map { $0.symbol }
                let cellWidth: CGFloat = max(50, 280 / CGFloat(max(symbols.count + 1, 2)))

                // Header row
                HStack(spacing: 2) {
                    Text("")
                        .font(.system(size: 8, design: .monospaced))
                        .frame(width: cellWidth, alignment: .center)
                    ForEach(symbols, id: \.self) { sym in
                        Text(sym)
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundColor(.isdTextMuted)
                            .frame(width: cellWidth, alignment: .center)
                            .lineLimit(1)
                    }
                }

                ForEach(corr.correlations) { row in
                    HStack(spacing: 2) {
                        Text(row.symbol)
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundColor(.isdTextMuted)
                            .frame(width: cellWidth, alignment: .center)
                            .lineLimit(1)

                        ForEach(row.values) { val in
                            if let c = val.corr {
                                Text(String(format: "%.2f", c))
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundColor(correlationColor(c))
                                    .frame(width: cellWidth, alignment: .center)
                                    .background(correlationColor(c).opacity(0.08))
                            } else {
                                Text("--")
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundColor(.isdTextMuted)
                                    .frame(width: cellWidth, alignment: .center)
                            }
                        }
                    }
                }

                if corr.concentration_warning {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.isdGold)
                            .font(.caption)
                        Text("Concentration warning: max sector \(String(format: "%.1f%%", corr.max_sector_pct))")
                            .font(.caption)
                            .foregroundColor(.isdGold)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.isdCard)
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
        } header: {
            Text("CORRELATION MATRIX")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.isdTextMuted)
                .tracking(0.3)
        }
    }

    private func correlationColor(_ corr: Double) -> Color {
        if corr >= 0.7 { return .isdRed }
        if corr >= 0.3 { return .isdGold }
        if corr <= -0.3 { return .isdGreen }
        return .isdTextSecondary
    }

    private func loadHoldings() async {
        isLoading = true
        errorMessage = nil
        do {
            holdings = try await api.fetchHoldings()
            correlation = try? await api.fetchHoldingsCorrelation()
        } catch APIError.unauthorized {
            errorMessage = "Please sign in to view holdings"
        } catch {
            errorMessage = "Failed to load holdings"
        }
        isLoading = false
    }

    private func deleteHoldings(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let holding = holdings[index]
                do {
                    try await api.deleteHolding(symbol: holding.symbol)
                } catch {
                    // silently ignore deletion errors
                }
            }
            holdings.remove(atOffsets: offsets)
        }
    }
}

struct HoldingRow: View {
    let holding: UserHolding

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(holding.symbol)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(.isdTextPrimary)

                HStack(spacing: 4) {
                    Text("QTY")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.isdTextMuted)
                        .tracking(0.3)

                    Text(String(format: "%.0f", holding.quantity))
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(.isdTextPrimary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "₹%.2f", holding.buy_price))
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.isdTextPrimary)

                Text(String(format: "₹%.2f", holding.quantity * holding.buy_price))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.isdTextSecondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.isdCard)
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
    }
}

struct CreateHoldingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var symbol = ""
    @State private var quantity = ""
    @State private var buyPrice = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    let onCreate: (UserHolding) -> Void

    private let api = APIClient.shared

    var body: some View {
        NavigationStack {
            Form {
                Section("Stock") {
                    TextField("Symbol (e.g. RELIANCE)", text: $symbol)
                        .textInputAutocapitalization(.characters)
                        .foregroundColor(.isdTextPrimary)
                }

                Section("Quantity") {
                    TextField("Number of shares", text: $quantity)
                        .keyboardType(.numberPad)
                        .foregroundColor(.isdTextPrimary)
                }

                Section("Buy Price") {
                    TextField("Price per share", text: $buyPrice)
                        .keyboardType(.decimalPad)
                        .foregroundColor(.isdTextPrimary)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.isdRed)
                    }
                }
            }
            .navigationTitle("Add Holding")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await createHolding() }
                    } label: {
                        if isSaving {
                            ProgressView().tint(.isdAccent)
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(symbol.isEmpty || quantity.isEmpty || buyPrice.isEmpty || isSaving)
                }
            }
        }
    }

    private func createHolding() async {
        isSaving = true
        errorMessage = nil
        do {
            guard let qty = Double(quantity), let price = Double(buyPrice) else {
                errorMessage = "Invalid quantity or price"
                isSaving = false
                return
            }
            let holding = try await api.createHolding(symbol: symbol.uppercased(), quantity: qty, buyPrice: price, buyDate: nil, notes: nil)
            onCreate(holding)
            dismiss()
        } catch {
            errorMessage = "Failed to add holding"
        }
        isSaving = false
    }
}

#Preview {
    HoldingsView()
}
