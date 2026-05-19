//
//  IPOCalendarView.swift
//  ISDStockDashboard
//

import SwiftUI

struct IPOCalendarView: View {
    @State private var activeIPOs: [IPOItem] = []
    @State private var upcomingIPOs: [IPOItem] = []
    @State private var pastIPOs: [IPOItem] = []
    @State private var stats: IPOStatistics?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedTab = 0

    private let api = APIClient.shared
    private let tabs = ["Active", "Upcoming", "Listed"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.isdBackground.ignoresSafeArea()
                List {
                    if isLoading {
                        Section {
                            ProgressView("Loading IPOs...")
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
                                    Task { await loadData() }
                                }
                            }
                        }
                    } else {
                        if let stats = stats {
                            statsSection(stats: stats)
                        }

                        if selectedTab == 0 {
                            ipoSection(title: "ACTIVE IPOs", ipos: activeIPOs)
                        } else if selectedTab == 1 {
                            ipoSection(title: "UPCOMING IPOs", ipos: upcomingIPOs)
                        } else {
                            ipoSection(title: "RECENTLY LISTED", ipos: pastIPOs)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("IPO Calendar")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("", selection: $selectedTab) {
                        ForEach(0..<tabs.count, id: \.self) { i in
                            Text(tabs[i]).tag(i)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                }
            }
            .refreshable {
                await loadData()
            }
            .task {
                await loadData()
            }
        }
    }

    private func statsSection(stats: IPOStatistics) -> some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    StatBadge(title: "ACTIVE", value: "\(stats.active_count)", color: .isdGreen)
                    StatBadge(title: "UPCOMING", value: "\(stats.upcoming_count)", color: .isdAccent)
                    StatBadge(title: "LISTED", value: "\(stats.listed_count)", color: .isdGold)
                    if let avg = stats.avg_listing_gain {
                        StatBadge(title: "AVG GAIN", value: String(format: "%+.1f%%", avg), color: avg >= 0 ? .isdGreen : .isdRed)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .background(Color.isdCard)
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
        }
    }

    private func ipoSection(title: String, ipos: [IPOItem]) -> some View {
        Section {
            if ipos.isEmpty {
                ContentUnavailableView {
                    Label("No IPOs", systemImage: "doc.text")
                } description: {
                    Text("No IPOs in this category")
                }
            } else {
                ForEach(ipos) { ipo in
                    IPORow(ipo: ipo)
                        .listRowSeparator(.hidden)
                }
            }
        } header: {
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.isdTextMuted)
                .tracking(0.3)
        }
    }

    private func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            async let activeTask = api.fetchIPOs(category: "active", limit: 20)
            async let upcomingTask = api.fetchIPOs(category: "upcoming", limit: 20)
            async let pastTask = api.fetchIPOs(category: "past", limit: 20)
            async let statsTask = api.fetchIPOStats()
            let (activeResult, upcomingResult, pastResult, statsResult) = try await (activeTask, upcomingTask, pastTask, statsTask)
            activeIPOs = activeResult.data
            upcomingIPOs = upcomingResult.data
            pastIPOs = pastResult.data
            stats = statsResult
        } catch APIError.unauthorized {
            errorMessage = "Please sign in to view IPO data"
        } catch {
            errorMessage = "Failed to load IPO data"
        }
        isLoading = false
    }
}

struct IPORow: View {
    let ipo: IPOItem

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(ipo.symbol)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(.isdTextPrimary)

                    Text(ipo.status.uppercased())
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .foregroundColor(statusColor)
                        .background(statusColor.opacity(0.10))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(statusColor.opacity(0.30), lineWidth: 1))
                        .cornerRadius(6)
                        .tracking(0.3)

                    Spacer()
                }

                Text(ipo.company_name)
                    .font(.subheadline)
                    .foregroundColor(.isdTextSecondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let open = ipo.open_date, let close = ipo.close_date {
                        Text("\(formatDate(open)) - \(formatDate(close))")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.isdTextMuted)
                            .tracking(0.3)
                    }
                    if let pe = ipo.pe_ratio {
                        Text(String(format: "P/E %.1f", pe))
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.isdTextMuted)
                            .tracking(0.3)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let priceLow = ipo.issue_price_low, let priceHigh = ipo.issue_price_high {
                    if priceLow == priceHigh {
                        Text(String(format: "₹%.0f", priceLow))
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundColor(.isdTextPrimary)
                    } else {
                        Text(String(format: "₹%.0f-%.0f", priceLow, priceHigh))
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(.isdTextPrimary)
                    }
                }

                if let gmp = ipo.current_gmp, let gmpPct = ipo.gmp_percent {
                    Text(String(format: "GMP %+.0f (%.1f%%)", gmp, gmpPct))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(gmp >= 0 ? .isdGreen : .isdRed)
                }

                if let sub = ipo.total_subscription {
                    Text(String(format: "Sub %.1fx", sub))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(sub >= 10 ? .isdGreen : .isdTextMuted)
                        .tracking(0.3)
                }
            }
        }
        .padding(.vertical, 8)
        .background(Color.isdCard)
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
    }

    private var statusColor: Color {
        switch ipo.status {
        case "active": return .isdGreen
        case "upcoming": return .isdAccent
        case "listed": return .isdGold
        case "closed": return .isdRed
        default: return .isdTextMuted
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = formatter.date(from: dateString) {
            let display = DateFormatter()
            display.dateFormat = "dd MMM"
            return display.string(from: date)
        }
        return String(dateString.prefix(10))
    }
}

#Preview {
    IPOCalendarView()
}
