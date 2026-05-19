//
//  NewsView.swift
//  ISDStockDashboard
//

import SwiftUI

struct NewsView: View {
    @State private var newsItems: [NewsItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedSentiment: String? = nil
    @State private var selectedSymbol: String? = nil

    private let api = APIClient.shared
    private let sentiments = ["bullish", "bearish", "neutral"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.isdBackground.ignoresSafeArea()
                List {
                    if isLoading {
                        Section {
                            ProgressView("Loading news...")
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
                                    Task { await loadNews() }
                                }
                            }
                        }
                    } else if newsItems.isEmpty {
                        Section {
                            ContentUnavailableView {
                                Label("No News", systemImage: "newspaper")
                            } description: {
                                Text("No articles found for the selected filters")
                            }
                        }
                    } else {
                        ForEach(newsItems) { item in
                            NewsRow(item: item)
                                .listRowSeparator(.hidden)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("News Intelligence")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("All") {
                            selectedSentiment = nil
                            Task { await loadNews() }
                        }
                        ForEach(sentiments, id: \.self) { s in
                            Button(s.capitalized) {
                                selectedSentiment = s
                                Task { await loadNews() }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(.isdAccent)
                    }
                }
            }
            .refreshable {
                await loadNews()
            }
            .task {
                await loadNews()
            }
        }
    }

    private func loadNews() async {
        isLoading = true
        errorMessage = nil
        do {
            newsItems = try await api.fetchNews(symbol: selectedSymbol, sentiment: selectedSentiment)
        } catch APIError.unauthorized {
            errorMessage = "Please sign in to view news"
        } catch {
            errorMessage = "Failed to load news"
        }
        isLoading = false
    }
}

struct NewsRow: View {
    let item: NewsItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if let sentiment = item.sentiment {
                    SentimentBadge(sentiment: sentiment)
                }

                Text(item.source.uppercased())
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.isdTextMuted)
                    .tracking(0.3)

                Spacer()

                if let date = item.published_at {
                    Text(formattedDate(date))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.isdTextMuted)
                }
            }

            Text(item.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.isdTextPrimary)
                .lineLimit(3)

            if let url = item.url {
                Link("Read full article", destination: URL(string: url)!)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.isdAccent)
            }
        }
        .padding(.vertical, 8)
        .background(Color.isdCard)
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
    }

    private func formattedDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = RelativeDateTimeFormatter()
            displayFormatter.unitsStyle = .abbreviated
            return displayFormatter.localizedString(for: date, relativeTo: Date())
        }
        return dateString
    }
}

struct SentimentBadge: View {
    let sentiment: String

    var body: some View {
        let (color, label, icon) = sentimentProps

        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 8))
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .tracking(0.3)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .foregroundColor(color)
        .background(color.opacity(0.10))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.30), lineWidth: 1))
        .cornerRadius(6)
    }

    private var sentimentProps: (Color, String, String) {
        switch sentiment.lowercased() {
        case "bullish", "positive":
            return (.isdGreen, "BULLISH", "arrow.up")
        case "bearish", "negative":
            return (.isdRed, "BEARISH", "arrow.down")
        default:
            return (.isdAccent, "NEUTRAL", "minus")
        }
    }
}

#Preview {
    NewsView()
}
