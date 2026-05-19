//
//  PaperTradingView.swift
//  ISDStockDashboard
//

import SwiftUI

struct PaperTradingView: View {
    @State private var portfolio: PaperPortfolio?
    @State private var trades: [PaperTrade] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingTradeSheet = false
    @State private var showingResetAlert = false

    private let api = APIClient.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.isdBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        if isLoading {
                            ProgressView("Loading portfolio...")
                                .tint(.isdTextSecondary)
                                .padding()
                        } else if let error = errorMessage {
                            ContentUnavailableView {
                                Label("Error", systemImage: "exclamationmark.triangle")
                            } description: {
                                Text(error)
                            } actions: {
                                Button("Retry") {
                                    Task { await loadData() }
                                }
                            }
                        } else if let pf = portfolio {
                            portfolioHeader(pf)
                            if !trades.isEmpty {
                                tradesSection
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Paper Trading")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("New Trade") { showingTradeSheet = true }
                        Button("Reset Portfolio", role: .destructive) { showingResetAlert = true }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.isdAccent)
                    }
                }
            }
            .sheet(isPresented: $showingTradeSheet) {
                NewPaperTradeSheet { _ in
                    Task { await loadData() }
                }
            }
            .alert("Reset Portfolio?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    Task { await resetPortfolio() }
                }
            } message: {
                Text("This will clear all positions and reset to ₹50 Lakhs starting capital.")
            }
            .refreshable { await loadData() }
            .task { await loadData() }
        }
    }

    private func portfolioHeader(_ pf: PaperPortfolio) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                portfolioCard(title: "CASH", value: pf.cash, color: .isdAccent)
                portfolioCard(title: "INVESTED", value: pf.invested, color: .isdGold)
            }

            HStack(spacing: 16) {
                portfolioCard(title: "TOTAL VALUE", value: pf.total_value, color: .isdTextPrimary)
                portfolioCard(title: "P&L", value: pf.total_pnl, color: pf.total_pnl >= 0 ? .isdGreen : .isdRed)
            }

            HStack {
                Text("P&L %")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.isdTextMuted)
                Spacer()
                Text(String(format: "%.2f%%", pf.pnl_percent))
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.profitLossColor(pf.pnl_percent))
            }

            if !pf.positions.isEmpty {
                Text("POSITIONS")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.isdTextMuted)
                    .tracking(0.5)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 0) {
                    ForEach(pf.positions) { pos in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(pos.symbol)
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.isdTextPrimary)
                                Text("\(String(format: "%.0f", pos.quantity)) @ ₹\(String(format: "%.2f", pos.avg_price))")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.isdTextMuted)
                            }
                            Spacer()
                            if let pnl = pos.pnl {
                                VStack(alignment: .trailing, spacing: 2) {
                                    if let val = pos.current_value {
                                        Text(String(format: "₹%.0f", val))
                                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                            .foregroundColor(.isdTextPrimary)
                                    }
                                    Text(String(format: "%.2f%%", pnl))
                                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                                        .foregroundStyle(Color.profitLossColor(pnl))
                                }
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
        .padding()
        .background(Color.isdCard)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
        .cornerRadius(6)
    }

    private func portfolioCard(title: String, value: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.isdTextMuted)
                .tracking(0.3)
            Text(String(format: "₹%.0f", value))
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(color.opacity(0.25), lineWidth: 1))
        .cornerRadius(4)
    }

    private var tradesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECENT TRADES")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.isdTextMuted)
                .tracking(0.5)

            VStack(spacing: 0) {
                ForEach(trades.prefix(10)) { trade in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(trade.symbol)
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.isdTextPrimary)
                                Text(trade.action.uppercased())
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .foregroundColor(trade.action == "BUY" ? .isdGreen : .isdRed)
                                    .background((trade.action == "BUY" ? Color.isdGreen : Color.isdRed).opacity(0.10))
                                    .overlay(RoundedRectangle(cornerRadius: 4).stroke((trade.action == "BUY" ? Color.isdGreen : Color.isdRed).opacity(0.30), lineWidth: 1))
                                    .cornerRadius(4)
                            }
                            Text("\(String(format: "%.0f", trade.quantity)) @ ₹\(String(format: "%.2f", trade.price))")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.isdTextMuted)
                        }
                        Spacer()
                        Text(String(format: "₹%.0f", trade.total_value))
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(.isdTextPrimary)
                    }
                    .padding(.vertical, 8)
                    .background(Color.isdCard)
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
            .cornerRadius(6)
        }
    }

    private func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            portfolio = try await api.fetchPaperPortfolio()
            trades = try await api.fetchPaperTrades()
        } catch APIError.unauthorized {
            errorMessage = "Please sign in to use paper trading"
        } catch {
            errorMessage = "Failed to load portfolio"
        }
        isLoading = false
    }

    private func resetPortfolio() async {
        do {
            try await api.resetPaperPortfolio()
            await loadData()
        } catch {
            errorMessage = "Failed to reset portfolio"
        }
    }
}

struct NewPaperTradeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var symbol = ""
    @State private var action = "BUY"
    @State private var quantity = ""
    @State private var price = ""
    @State private var notes = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    let onCreate: (PaperTrade) -> Void
    private let api = APIClient.shared
    private let actions = ["BUY", "SELL"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Stock") {
                    TextField("Symbol (e.g. RELIANCE)", text: $symbol)
                        .textInputAutocapitalization(.characters)
                        .foregroundColor(.isdTextPrimary)
                }

                Section("Action") {
                    Picker("Action", selection: $action) {
                        ForEach(actions, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Quantity") {
                    TextField("Shares", text: $quantity)
                        .keyboardType(.numberPad)
                        .foregroundColor(.isdTextPrimary)
                }

                Section("Price") {
                    TextField("Price per share", text: $price)
                        .keyboardType(.decimalPad)
                        .foregroundColor(.isdTextPrimary)
                }

                Section("Notes (Optional)") {
                    TextField("Notes", text: $notes)
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
            .navigationTitle("New Trade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await createTrade() }
                    } label: {
                        if isSaving { ProgressView().tint(.isdAccent) } else { Text("Execute") }
                    }
                    .disabled(symbol.isEmpty || quantity.isEmpty || price.isEmpty || isSaving)
                }
            }
        }
    }

    private func createTrade() async {
        isSaving = true
        errorMessage = nil
        do {
            guard let qty = Double(quantity), let pr = Double(price) else {
                errorMessage = "Invalid quantity or price"
                isSaving = false
                return
            }
            try await api.createPaperTrade(symbol: symbol, action: action, quantity: qty, price: pr, notes: notes.isEmpty ? nil : notes)
            dismiss()
        } catch {
            errorMessage = "Failed to execute trade"
        }
        isSaving = false
    }
}

#Preview {
    PaperTradingView()
}
