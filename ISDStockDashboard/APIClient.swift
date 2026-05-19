//
//  APIClient.swift
//  ISDStockDashboard
//

import Foundation
import UIKit

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case unauthorized
    case notFound
    case serverError(String)
    case networkError(Error)
    case decodingError(Error)
    case unknown
}

@MainActor
class APIClient: ObservableObject {
    static let shared = APIClient()

    // MARK: - Configuration
    #if DEBUG
    private let baseURL = "https://india-stock-dashboard.tailffeb2f.ts.net"
    #else
    private let baseURL = "https://india-stock-dashboard.tailffeb2f.ts.net"
    #endif

    private let session: URLSession
    private let cookieStorage = HTTPCookieStorage.shared
    private(set) var accessToken: String? {
        didSet { try? KeychainTokenStore.save(token: accessToken ?? "") }
    }

    init() {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = cookieStorage
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        self.session = URLSession(configuration: config)
        self.accessToken = KeychainTokenStore.load()
    }

    // MARK: - Auth

    func login(username: String, password: String) async throws {
        let url = URL(string: "\(baseURL)/api/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(LoginRequest(username: username, password: password))

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
            self.accessToken = loginResponse.access_token
        case 401:
            throw APIError.unauthorized
        default:
            if let errorDetail = try? JSONDecoder().decode([String: String].self, from: data)["detail"] {
                throw APIError.serverError(errorDetail)
            }
            throw APIError.serverError("Login failed (HTTP \(httpResponse.statusCode))")
        }
    }

    func logout() async throws {
        accessToken = nil
        KeychainTokenStore.delete()
        let url = URL(string: "\(baseURL)/api/auth/logout")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        _ = try? await session.data(for: request)
    }

    func refreshToken() async throws -> Bool {
        let url = URL(string: "\(baseURL)/api/auth/refresh-token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { return false }
        return httpResponse.statusCode == 200
    }

    func fetchCurrentUser() async throws -> User {
        let data = try await get("/api/auth/me")
        return try JSONDecoder().decode(User.self, from: data)
    }

    // MARK: - Dashboard

    func fetchIndices() async throws -> [IndexData] {
        let data = try await get("/api/indices")
        let response = try JSONDecoder().decode(IndicesResponse.self, from: data)
        return response.indices
    }

    func fetchTrending() async throws -> [StockSearchResult] {
        let data = try await get("/api/trending")
        let response = try JSONDecoder().decode([String: [StockSearchResult]].self, from: data)
        return response["gainers"] ?? []
    }

    // MARK: - Search

    func searchStocks(query: String) async throws -> [StockSearchResult] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let data = try await get("/api/search?query=\(encodedQuery)")
        let response = try JSONDecoder().decode([String: [StockSearchResult]].self, from: data)
        return response["results"] ?? []
    }

    func fetchStockDetail(symbol: String) async throws -> StockDetail {
        let encodedSymbol = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
        let data = try await get("/api/stock/\(encodedSymbol)")
        return try JSONDecoder().decode(StockDetail.self, from: data)
    }

    // MARK: - Watchlist

    func fetchWatchlists() async throws -> [Watchlist] {
        let data = try await get("/api/watchlists")
        return try JSONDecoder().decode([Watchlist].self, from: data)
    }

    func fetchWatchlistDetail(id: Int) async throws -> Watchlist {
        let data = try await get("/api/watchlists/\(id)")
        return try JSONDecoder().decode(Watchlist.self, from: data)
    }

    func createWatchlist(name: String, description: String?) async throws -> Watchlist {
        var body: [String: String] = ["name": name]
        if let desc = description { body["description"] = desc }
        let data = try await post("/api/watchlists", body: body)
        return try JSONDecoder().decode(Watchlist.self, from: data)
    }

    func addStockToWatchlist(watchlistId: Int, symbol: String, exchange: String) async throws {
        let body: [String: String] = ["symbol": symbol, "exchange": exchange]
        _ = try await post("/api/watchlists/\(watchlistId)/stocks", body: body)
    }

    func removeStockFromWatchlist(watchlistId: Int, symbol: String, exchange: String) async throws {
        let encodedSymbol = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
        _ = try await delete("/api/watchlists/\(watchlistId)/stocks/\(encodedSymbol)?exchange=\(exchange)")
    }

    // MARK: - Alerts

    func fetchAlerts() async throws -> [AlertItem] {
        let data = try await get("/api/alerts")
        return try JSONDecoder().decode([AlertItem].self, from: data)
    }

    func createAlert(symbol: String, alertType: String, condition: String, threshold: Double) async throws {
        struct AlertRequest: Encodable {
            let symbol: String
            let alert_type: String
            let condition: String
            let threshold: Double
            let is_active: Bool = true
        }
        let body = AlertRequest(symbol: symbol, alert_type: alertType, condition: condition, threshold: threshold)
        _ = try await post("/api/alerts", body: body)
    }

    // MARK: - Notifications

    func fetchNotificationSettings() async throws -> NotificationSettings {
        let data = try await get("/api/notifications/settings")
        return try JSONDecoder().decode(NotificationSettings.self, from: data)
    }

    func updateNotificationSettings(_ settings: NotificationSettings) async throws -> NotificationSettings {
        let data = try await put("/api/notifications/settings", body: settings)
        return try JSONDecoder().decode(NotificationSettings.self, from: data)
    }

    func testTelegram() async throws -> String {
        let data = try await post("/api/notifications/test-telegram", body: [String: String]())
        let response = try JSONDecoder().decode([String: String].self, from: data)
        return response["message"] ?? "Test sent"
    }

    func testEmail() async throws -> String {
        let data = try await post("/api/notifications/test-email", body: [String: String]())
        let response = try JSONDecoder().decode([String: String].self, from: data)
        return response["message"] ?? "Test sent"
    }

    // MARK: - FCM Push

    func registerFCMDevice(token: String, deviceName: String) async throws {
        struct FCMRegisterRequest: Encodable {
            let token: String
            let device_type: String
            let device_name: String
            let app_version: String
            let platform_version: String
            let subscribe_to_topics: [String]
        }
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let body = FCMRegisterRequest(
            token: token,
            device_type: "ios",
            device_name: deviceName,
            app_version: appVersion,
            platform_version: UIDevice.current.systemVersion,
            subscribe_to_topics: ["price_alerts", "market_updates"]
        )
        _ = try await post("/api/fcm/register", body: body)
    }

    func fetchFCMDevices() async throws -> [FCMDevice] {
        let data = try await get("/api/fcm/devices")
        let response = try JSONDecoder().decode([String: [FCMDevice]].self, from: data)
        return response["devices"] ?? []
    }

    func sendTestPush() async throws -> String {
        let data = try await post("/api/fcm/send-test", body: [
            "title": "Test Notification",
            "body": "This is a test push from ISD iOS"
        ])
        let response = try JSONDecoder().decode([String: String].self, from: data)
        return response["message"] ?? "Test push sent"
    }

    // MARK: - News

    func fetchNews(symbol: String? = nil, sentiment: String? = nil) async throws -> [NewsItem] {
        var components = URLComponents(string: "\(baseURL)/api/news")!
        var queryItems: [URLQueryItem] = []
        if let symbol = symbol { queryItems.append(URLQueryItem(name: "symbol", value: symbol)) }
        if let sentiment = sentiment { queryItems.append(URLQueryItem(name: "sentiment", value: sentiment)) }
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        let data = try await get(components.url!.absoluteString.replacingOccurrences(of: baseURL, with: ""))
        let response = try JSONDecoder().decode([String: [NewsItem]].self, from: data)
        return response["news"] ?? []
    }

    // MARK: - Signals

    func fetchMarketSignals() async throws -> MarketSignalsResponse {
        let data = try await get("/api/signals/market")
        let response = try JSONDecoder().decode(MarketSignalsResponse.self, from: data)
        return response
    }

    func fetchSignal(for symbol: String) async throws -> TradingSignal {
        let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
        let data = try await get("/api/signals/\(encoded)")
        return try JSONDecoder().decode(TradingSignal.self, from: data)
    }

    func fetchMarketIntelligence() async throws -> [String: Any] {
        let data = try await get("/api/signals/market-intelligence")
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return json
    }

    // MARK: - Holdings

    func fetchHoldings() async throws -> [UserHolding] {
        let data = try await get("/api/holdings")
        return try JSONDecoder().decode([UserHolding].self, from: data)
    }

    func createHolding(symbol: String, quantity: Double, buyPrice: Double, buyDate: String?, notes: String?) async throws -> UserHolding {
        struct CreateHoldingRequest: Encodable {
            let symbol: String
            let quantity: Double
            let buy_price: Double
            let buy_date: String?
            let notes: String?
        }
        let body = CreateHoldingRequest(symbol: symbol.uppercased(), quantity: quantity, buy_price: buyPrice, buy_date: buyDate, notes: notes)
        let data = try await post("/api/holdings", body: body)
        return try JSONDecoder().decode(UserHolding.self, from: data)
    }

    func deleteHolding(symbol: String) async throws {
        let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
        _ = try await delete("/api/holdings/\(encoded)")
    }

    func fetchHoldingsCorrelation() async throws -> CorrelationMatrix {
        let data = try await get("/api/holdings/correlation")
        return try JSONDecoder().decode(CorrelationMatrix.self, from: data)
    }

    // MARK: - Insider Trading

    func fetchInsiderTrades(symbol: String? = nil, transactionType: String? = nil, page: Int = 1, pageSize: Int = 50) async throws -> InsiderTradeListResponse {
        var components = URLComponents(string: "\(baseURL)/api/insider/trading")!
        var queryItems: [URLQueryItem] = [URLQueryItem(name: "page", value: String(page)), URLQueryItem(name: "page_size", value: String(pageSize))]
        if let symbol = symbol { queryItems.append(URLQueryItem(name: "symbol", value: symbol.uppercased())) }
        if let type = transactionType { queryItems.append(URLQueryItem(name: "transaction_type", value: type)) }
        components.queryItems = queryItems

        guard let url = components.url else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let data = try await performRequest(request)
        return try JSONDecoder().decode(InsiderTradeListResponse.self, from: data)
    }

    func fetchPromoterConfidence() async throws -> PromoterConfidenceResponse {
        let data = try await get("/api/insider/promoter-confidence")
        return try JSONDecoder().decode(PromoterConfidenceResponse.self, from: data)
    }

    func fetchInsiderSummary(symbol: String) async throws -> [String: Any] {
        let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
        let data = try await get("/api/insider/summary/\(encoded)")
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [:] }
        return json
    }

    // MARK: - Profile

    func fetchUserProfile() async throws -> UserProfile {
        let data = try await get("/api/auth/me")
        return try JSONDecoder().decode(UserProfile.self, from: data)
    }

    // MARK: - Chart

    func fetchStockChart(symbol: String, timeframe: String = "1D") async throws -> StockChartResponse {
        let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
        let data = try await get("/api/stock/\(encoded)/chart?timeframe=\(timeframe)")
        return try JSONDecoder().decode(StockChartResponse.self, from: data)
    }

    // MARK: - Screener

    func fetchScreenerStocks(
        recommendation: String? = nil,
        sector: String? = nil,
        aiScoreMin: Double? = nil,
        sortBy: String = "composite_score",
        page: Int = 1,
        limit: Int = 50
    ) async throws -> ScreenerResponse {
        var components = URLComponents(string: "\(baseURL)/api/screener/stocks")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "sort_by", value: sortBy),
            URLQueryItem(name: "sort_order", value: "desc"),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        if let rec = recommendation { queryItems.append(URLQueryItem(name: "recommendation", value: rec)) }
        if let sec = sector { queryItems.append(URLQueryItem(name: "sector", value: sec)) }
        if let score = aiScoreMin { queryItems.append(URLQueryItem(name: "ai_score_min", value: String(score))) }
        components.queryItems = queryItems

        guard let url = components.url else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let data = try await performRequest(request)
        return try JSONDecoder().decode(ScreenerResponse.self, from: data)
    }

    func fetchScreenerStats() async throws -> ScreenerQuickStats {
        let data = try await get("/api/screener/stats")
        return try JSONDecoder().decode(ScreenerQuickStats.self, from: data)
    }

    func fetchAIRankings(limit: Int = 50) async throws -> [ScreenerStock] {
        let data = try await get("/api/screener/ai-rankings?limit=\(limit)")
        return try JSONDecoder().decode([ScreenerStock].self, from: data)
    }

    // MARK: - IPO

    func fetchIPOs(category: String, limit: Int = 50) async throws -> IPOListResponse {
        let data = try await get("/api/ipo/category/\(category)?limit=\(limit)")
        return try JSONDecoder().decode(IPOListResponse.self, from: data)
    }

    func fetchIPOStats() async throws -> IPOStatistics {
        let data = try await get("/api/ipo/analytics/statistics")
        return try JSONDecoder().decode(IPOStatistics.self, from: data)
    }

    // MARK: - Smart Money

    func fetchFiiDiiSummary() async throws -> FiiDiiSummary {
        let data = try await get("/api/fii-dii/summary")
        return try JSONDecoder().decode(FiiDiiSummary.self, from: data)
    }

    func fetchBulkDeals(symbol: String? = nil, dealType: String? = nil) async throws -> [BulkDeal] {
        var components = URLComponents(string: "\(baseURL)/api/bulk-deals")!
        var queryItems: [URLQueryItem] = []
        if let symbol = symbol { queryItems.append(URLQueryItem(name: "symbol", value: symbol)) }
        if let type = dealType { queryItems.append(URLQueryItem(name: "dealType", value: type)) }
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let data = try await performRequest(request)
        let response = try JSONDecoder().decode(BulkDealsResponse.self, from: data)
        return response.deals
    }

    // MARK: - NIFTY 50

    func fetchNiftySummary() async throws -> NiftySummary {
        let data = try await get("/api/nifty")
        return try JSONDecoder().decode(NiftySummary.self, from: data)
    }

    // MARK: - Options Chain

    func fetchOptionsChain(symbol: String, expiry: String? = nil) async throws -> OptionsChain {
        var components = URLComponents(string: "\(baseURL)/api/options/chain/\(symbol)")!
        if let expiry = expiry {
            components.queryItems = [URLQueryItem(name: "expiry", value: expiry)]
        }
        guard let url = components.url else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let data = try await performRequest(request)
        return try JSONDecoder().decode(OptionsChain.self, from: data)
    }

    func fetchOptionsExpiryDates(symbol: String) async throws -> [String] {
        let data = try await get("/api/options/expiry/\(symbol)")
        let response = try JSONDecoder().decode([String: [String]].self, from: data)
        return response["expiry_dates"] ?? []
    }

    // MARK: - Paper Trading

    func fetchPaperPortfolio() async throws -> PaperPortfolio {
        let data = try await get("/api/paper-trade/portfolio")
        return try JSONDecoder().decode(PaperPortfolio.self, from: data)
    }

    func fetchPaperTrades() async throws -> [PaperTrade] {
        let data = try await get("/api/paper-trade/trades")
        let response = try JSONDecoder().decode([String: [PaperTrade]].self, from: data)
        return response["trades"] ?? []
    }

    func createPaperTrade(symbol: String, action: String, quantity: Double, price: Double, notes: String?) async throws {
        struct PaperTradeRequest: Encodable {
            let symbol: String
            let action: String
            let quantity: Double
            let price: Double
            let notes: String?
        }
        let body = PaperTradeRequest(symbol: symbol.uppercased(), action: action, quantity: quantity, price: price, notes: notes)
        _ = try await post("/api/paper-trade/trades", body: body)
    }

    func resetPaperPortfolio() async throws {
        _ = try await post("/api/paper-trade/reset", body: [String: String]())
    }

    // MARK: - Calendar

    func fetchEarningsCalendar() async throws -> [EarningsEvent] {
        let data = try await get("/api/calendar/earnings")
        let response = try JSONDecoder().decode([String: [EarningsEvent]].self, from: data)
        return response["events"] ?? []
    }

    // MARK: - 52-Week

    func fetch52WeekData(type: String = "high") async throws -> Week52Response {
        let data = try await get("/api/52week?type=\(type)")
        return try JSONDecoder().decode(Week52Response.self, from: data)
    }

    // MARK: - Reports

    func fetchResearchReports() async throws -> [ResearchReport] {
        let data = try await get("/api/reports")
        let response = try JSONDecoder().decode([String: [ResearchReport]].self, from: data)
        return response["reports"] ?? []
    }

    // MARK: - Signal Accuracy

    func fetchSignalAccuracy(days: Int = 5) async throws -> SignalAccuracyResponse {
        let data = try await get("/api/signals/accuracy?days=\(days)")
        return try JSONDecoder().decode(SignalAccuracyResponse.self, from: data)
    }

    // MARK: - Trade Planner

    func fetchTradePlanner(symbol: String) async throws -> TradePlan {
        let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
        let data = try await get("/api/trade-planner/\(encoded)")
        return try JSONDecoder().decode(TradePlan.self, from: data)
    }

    // MARK: - Market Breadth

    func fetchMarketBreadth(index: String = "nifty 50") async throws -> MarketBreadth {
        let encoded = index.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? index
        let data = try await get("/api/market/breadth?index=\(encoded)")
        return try JSONDecoder().decode(MarketBreadth.self, from: data)
    }

    // MARK: - Stock Detail Enhancements

    func fetchStockSentiment(symbol: String) async throws -> StockSentiment {
        let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
        let data = try await get("/api/stock/\(encoded)/sentiment")
        return try JSONDecoder().decode(StockSentiment.self, from: data)
    }

    func fetchSupportResistance(symbol: String) async throws -> SupportResistance {
        let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
        let data = try await get("/api/stock/\(encoded)/support-resistance")
        return try JSONDecoder().decode(SupportResistance.self, from: data)
    }

    func fetchDeepAnalysis(symbol: String) async throws -> DeepAnalysis {
        let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
        let data = try await get("/api/stock/\(encoded)/deep-analysis")
        return try JSONDecoder().decode(DeepAnalysis.self, from: data)
    }

    // MARK: - Live Price (Polling fallback)

    func fetchLivePrice(symbol: String) async throws -> LivePriceData {
        let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
        let data = try await get("/api/kite/prices/unified/\(encoded)")
        return try JSONDecoder().decode(LivePriceData.self, from: data)
    }

    // MARK: - Agent Debate

    func fetchAgentHistory(ticker: String? = nil) async throws -> [AgentAnalysisRecord] {
        var path = "/api/agents/history"
        if let ticker = ticker {
            path += "?ticker=\(ticker)"
        }
        let data = try await get(path)
        return try JSONDecoder().decode([AgentAnalysisRecord].self, from: data)
    }

    func startAgentAnalysis(ticker: String, date: String? = nil) async throws -> AgentJobResponse {
        struct AnalyzeRequest: Encodable {
            let ticker: String
            let date: String?
        }
        let body = AnalyzeRequest(ticker: ticker.uppercased(), date: date)
        let data = try await post("/api/agents/analyze", body: body)
        return try JSONDecoder().decode(AgentJobResponse.self, from: data)
    }

    func getAgentJobStatus(jobId: String) async throws -> AgentJobResponse {
        let data = try await get("/api/agents/job/\(jobId)")
        return try JSONDecoder().decode(AgentJobResponse.self, from: data)
    }

    func fetchAgentAccuracy(days: Int = 5) async throws -> AgentAccuracy {
        let data = try await get("/api/agents/accuracy?days=\(days)")
        return try JSONDecoder().decode(AgentAccuracy.self, from: data)
    }

    // MARK: - Generic HTTP Methods

    private func get(_ path: String) async throws -> Data {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        return try await performRequest(request)
    }

    private func post(_ path: String, body: Encodable) async throws -> Data {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return try await performRequest(request)
    }

    private func put(_ path: String, body: Encodable) async throws -> Data {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return try await performRequest(request)
    }

    private func delete(_ path: String) async throws -> Data {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        return try await performRequest(request)
    }

    private func performRequest(_ request: URLRequest) async throws -> Data {
        var req = request
        if let token = accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await session.data(for: req)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200...299:
                return data
            case 401:
                throw APIError.unauthorized
            case 404:
                throw APIError.notFound
            case 500...599:
                if let errorDetail = try? JSONDecoder().decode([String: String].self, from: data)["detail"] {
                    throw APIError.serverError(errorDetail)
                }
                throw APIError.serverError("Server error (HTTP \(httpResponse.statusCode))")
            default:
                if let errorDetail = try? JSONDecoder().decode([String: String].self, from: data)["detail"] {
                    throw APIError.serverError(errorDetail)
                }
                throw APIError.serverError("Request failed (HTTP \(httpResponse.statusCode))")
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
}
