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

    init() {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = cookieStorage
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        self.session = URLSession(configuration: config)
    }

    // MARK: - Auth

    func login(username: String, password: String) async throws -> User {
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
            return loginResponse.user
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
        do {
            let (data, response) = try await session.data(for: request)

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
