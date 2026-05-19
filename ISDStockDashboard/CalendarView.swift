//
//  CalendarView.swift
//  ISDStockDashboard
//

import SwiftUI

struct CalendarView: View {
    @State private var events: [EarningsEvent] = []
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
                            ProgressView("Loading calendar...")
                                .tint(.isdTextSecondary)
                                .padding()
                        }
                    } else if let error = errorMessage {
                        Section {
                            ContentUnavailableView {
                                Label("Error", systemImage: "exclamationmark.triangle")
                            } description: { Text(error) }
                        }
                    } else if events.isEmpty {
                        Section {
                            ContentUnavailableView {
                                Label("No Events", systemImage: "calendar")
                            } description: {
                                Text("No upcoming earnings or economic events")
                            }
                        }
                    } else {
                        ForEach(groupedEvents.keys.sorted(), id: \.self) { date in
                            Section(date) {
                                ForEach(groupedEvents[date] ?? []) { event in
                                    EventRow(event: event)
                                }
                            }
                            .listRowBackground(Color.isdCard)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Earnings Calendar")
            .refreshable { await loadData() }
            .task { await loadData() }
        }
    }

    private var groupedEvents: [String: [EarningsEvent]] {
        Dictionary(grouping: events) { event in
            String(event.event_date.prefix(10))
        }
    }

    private func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            events = try await api.fetchEarningsCalendar()
        } catch {
            errorMessage = "Failed to load calendar"
        }
        isLoading = false
    }
}

struct EventRow: View {
    let event: EarningsEvent

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(event.symbol)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(.isdTextPrimary)
                    Text(event.event_type.uppercased())
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .foregroundColor(.isdAccentLight)
                        .background(Color.isdAccent.opacity(0.10))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.isdAccent.opacity(0.30), lineWidth: 1))
                        .cornerRadius(4)
                }
                if let name = event.company_name {
                    Text(name)
                        .font(.subheadline)
                        .foregroundColor(.isdTextSecondary)
                        .lineLimit(1)
                }
                if let eps = event.eps_estimate {
                    Text("EPS est: \(String(format: "%.2f", eps))")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.isdTextMuted)
                }
            }
            Spacer()
            if let quarter = event.fiscal_quarter {
                Text(quarter)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.isdGold)
            }
        }
        .padding(.vertical, 6)
        .background(Color.isdCard)
    }
}

#Preview {
    CalendarView()
}
