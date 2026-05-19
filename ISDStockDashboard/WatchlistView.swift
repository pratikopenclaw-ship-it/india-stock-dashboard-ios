//
//  WatchlistView.swift
//  ISDStockDashboard
//

import SwiftUI

struct WatchlistView: View {
    @State private var watchlists: [Watchlist] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingCreateSheet = false
    @State private var newWatchlistName = ""
    @State private var newWatchlistDescription = ""

    private let api = APIClient.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.isdBackground.ignoresSafeArea()
                List {
                    if isLoading {
                        Section {
                            ProgressView("Loading watchlists...")
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
                                    Task { await loadWatchlists() }
                                }
                            }
                        }
                    } else if watchlists.isEmpty {
                        Section {
                            ContentUnavailableView {
                                Label("No Watchlists", systemImage: "star")
                            } description: {
                                Text("Create a watchlist to track your favorite stocks")
                            }
                        }
                    } else {
                        ForEach(watchlists) { watchlist in
                            NavigationLink(destination: WatchlistDetailView(watchlistId: watchlist.id)) {
                                WatchlistRow(watchlist: watchlist)
                            }
                            .listRowSeparator(.hidden)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Watchlists")
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
                NavigationStack {
                    Form {
                        Section {
                            TextField("My Watchlist", text: $newWatchlistName)
                                .foregroundColor(.isdTextPrimary)
                        } header: {
                            Text("WATCHLIST NAME")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.isdTextMuted)
                                .tracking(0.3)
                        }
                        Section {
                            TextField("Description", text: $newWatchlistDescription)
                                .foregroundColor(.isdTextPrimary)
                        } header: {
                            Text("DESCRIPTION (OPTIONAL)")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.isdTextMuted)
                                .tracking(0.3)
                        }
                    }
                    .navigationTitle("New Watchlist")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingCreateSheet = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Create") {
                                Task {
                                    await createWatchlist()
                                }
                            }
                            .disabled(newWatchlistName.isEmpty)
                        }
                    }
                }
            }
            .refreshable {
                await loadWatchlists()
            }
            .task {
                await loadWatchlists()
            }
        }
    }

    private func loadWatchlists() async {
        isLoading = true
        errorMessage = nil
        do {
            watchlists = try await api.fetchWatchlists()
        } catch APIError.unauthorized {
            errorMessage = "Please sign in to view watchlists"
        } catch {
            errorMessage = "Failed to load watchlists"
        }
        isLoading = false
    }

    private func createWatchlist() async {
        do {
            let newList = try await api.createWatchlist(name: newWatchlistName, description: newWatchlistDescription.isEmpty ? nil : newWatchlistDescription)
            watchlists.append(newList)
            showingCreateSheet = false
            newWatchlistName = ""
            newWatchlistDescription = ""
        } catch {
            errorMessage = "Failed to create watchlist"
        }
    }
}

struct WatchlistRow: View {
    let watchlist: Watchlist

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(watchlist.name)
                    .font(.headline)
                    .foregroundColor(.isdTextPrimary)

                if watchlist.is_default {
                    Text("DEFAULT")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.isdAccent.opacity(0.10))
                        .foregroundColor(.isdAccent)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdAccent.opacity(0.30), lineWidth: 1))
                        .cornerRadius(6)
                        .tracking(0.3)
                }

                Spacer()
            }

            if let description = watchlist.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.isdTextSecondary)
                    .lineLimit(1)
            }

            HStack {
                Image(systemName: "number")
                    .font(.caption)
                    .foregroundColor(.isdTextMuted)
                Text("\(watchlist.stock_count ?? 0) STOCKS")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.isdTextMuted)
                    .tracking(0.3)
            }
        }
        .padding(.vertical, 4)
        .background(Color.isdCard)
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
    }
}

struct WatchlistDetailView: View {
    let watchlistId: Int
    @State private var watchlist: Watchlist?
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let api = APIClient.shared

    var body: some View {
        ZStack {
            Color.isdBackground.ignoresSafeArea()
            List {
                if isLoading {
                    Section {
                        ProgressView("Loading...")
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
                                Task { await loadWatchlist() }
                            }
                        }
                    }
                } else if let watchlist = watchlist {
                    if let stocks = watchlist.stocks, !stocks.isEmpty {
                        Section {
                            ForEach(stocks) { stock in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(stock.symbol)
                                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                                            .foregroundColor(.isdTextPrimary)
                                        Text(stock.exchange.uppercased())
                                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                                            .foregroundColor(.isdTextMuted)
                                            .tracking(0.3)
                                    }
                                    Spacer()
                                    if let addedAt = stock.added_at {
                                        Text(formattedDate(addedAt))
                                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                                            .foregroundColor(.isdTextMuted)
                                            .tracking(0.3)
                                    }
                                }
                                .padding(.vertical, 8)
                                .background(Color.isdCard)
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
                                .listRowSeparator(.hidden)
                            }
                        }
                    } else {
                        Section {
                            ContentUnavailableView {
                                Label("Empty Watchlist", systemImage: "star.slash")
                            } description: {
                                Text("No stocks in this watchlist yet")
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(watchlist?.name ?? "Watchlist")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await loadWatchlist()
        }
        .task {
            await loadWatchlist()
        }
    }

    private func loadWatchlist() async {
        isLoading = true
        errorMessage = nil
        do {
            watchlist = try await api.fetchWatchlistDetail(id: watchlistId)
        } catch APIError.unauthorized {
            errorMessage = "Please sign in to view watchlist"
        } catch {
            errorMessage = "Failed to load watchlist"
        }
        isLoading = false
    }

    private func formattedDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

#Preview {
    WatchlistView()
}
