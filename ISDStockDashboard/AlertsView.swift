//
//  AlertsView.swift
//  ISDStockDashboard
//

import SwiftUI

struct AlertsView: View {
    @State private var alerts: [AlertItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingCreateSheet = false

    private let api = APIClient.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.isdBackground.ignoresSafeArea()
                List {
                    if isLoading {
                        Section {
                            ProgressView("Loading alerts...")
                                .foregroundColor(.isdTextSecondary)
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
                                    Task { await loadAlerts() }
                                }
                            }
                        }
                    } else if alerts.isEmpty {
                        Section {
                            ContentUnavailableView {
                                Label("No Alerts", systemImage: "bell.slash")
                            } description: {
                                Text("Create an alert to get notified when a stock hits your target price")
                            }
                        }
                    } else {
                        ForEach(alerts) { alert in
                            AlertRow(alert: alert)
                                .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: deleteAlerts)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Price Alerts")
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
                CreateAlertView { newAlert in
                    alerts.append(newAlert)
                }
            }
            .refreshable {
                await loadAlerts()
            }
            .task {
                await loadAlerts()
            }
        }
    }

    private func loadAlerts() async {
        isLoading = true
        errorMessage = nil
        do {
            alerts = try await api.fetchAlerts()
        } catch APIError.unauthorized {
            errorMessage = "Please sign in to view alerts"
        } catch {
            errorMessage = "Failed to load alerts"
        }
        isLoading = false
    }

    private func deleteAlerts(at offsets: IndexSet) {
        Task {
            for index in offsets {
                _ = alerts[index]
                // API delete not implemented yet
            }
            alerts.remove(atOffsets: offsets)
        }
    }
}

struct AlertRow: View {
    let alert: AlertItem

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(alert.symbol)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(.isdTextPrimary)

                    Text(alert.alert_type.uppercased())
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .foregroundColor(.isdAccent)
                        .background(Color.isdAccent.opacity(0.10))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdAccent.opacity(0.30), lineWidth: 1))
                        .cornerRadius(6)
                        .tracking(0.3)

                    Spacer()
                }

                HStack(spacing: 4) {
                    Text(alert.condition.uppercased())
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.isdTextMuted)
                        .tracking(0.3)

                    Text(String(format: "₹%.2f", alert.threshold))
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(.isdTextPrimary)
                }
            }

            Spacer()

            Circle()
                .fill(alert.is_active ? Color.isdGreen : Color.isdTextMuted)
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 8)
        .background(Color.isdCard)
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
    }
}

struct CreateAlertView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var symbol = ""
    @State private var alertType = "price_above"
    @State private var condition = "above"
    @State private var threshold = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    let onCreate: (AlertItem) -> Void

    private let api = APIClient.shared
    private let alertTypes = ["price_above", "price_below", "percent_change", "volume_spike"]
    private let conditions = ["above", "below", "equals"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Symbol (e.g. RELIANCE)", text: $symbol)
                        .textInputAutocapitalization(.characters)
                        .foregroundColor(.isdTextPrimary)
                } header: {
                    Text("STOCK")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.isdTextMuted)
                        .tracking(0.3)
                }

                Section {
                    Picker("Type", selection: $alertType) {
                        ForEach(alertTypes, id: \.self) { type in
                            Text(type.replacingOccurrences(of: "_", with: " ").capitalized)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("ALERT TYPE")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.isdTextMuted)
                        .tracking(0.3)
                }

                Section {
                    Picker("Condition", selection: $condition) {
                        ForEach(conditions, id: \.self) { c in
                            Text(c.capitalized)
                                .tag(c)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("CONDITION")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.isdTextMuted)
                        .tracking(0.3)
                }

                Section {
                    TextField("Price / %", text: $threshold)
                        .keyboardType(.decimalPad)
                        .foregroundColor(.isdTextPrimary)
                } header: {
                    Text("THRESHOLD")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.isdTextMuted)
                        .tracking(0.3)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.isdRed)
                    }
                }
            }
            .navigationTitle("New Alert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await createAlert()
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .tint(.isdAccent)
                        } else {
                            Text("Create")
                        }
                    }
                    .disabled(symbol.isEmpty || threshold.isEmpty || isSaving)
                }
            }
        }
    }

    private func createAlert() async {
        isSaving = true
        errorMessage = nil
        do {
            guard let thresholdValue = Double(threshold) else {
                errorMessage = "Invalid threshold value"
                isSaving = false
                return
            }
            try await api.createAlert(
                symbol: symbol.uppercased(),
                alertType: alertType,
                condition: condition,
                threshold: thresholdValue
            )
            let newAlert = AlertItem(
                id: Int.random(in: 1000...9999),
                symbol: symbol.uppercased(),
                alert_type: alertType,
                condition: condition,
                threshold: thresholdValue,
                is_active: true,
                created_at: ISO8601DateFormatter().string(from: Date())
            )
            onCreate(newAlert)
            dismiss()
        } catch {
            errorMessage = "Failed to create alert"
        }
        isSaving = false
    }
}

#Preview {
    AlertsView()
}
