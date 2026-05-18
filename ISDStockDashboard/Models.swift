//
//  Models.swift
//  ISDStockDashboard
//

import Foundation

struct User: Codable, Identifiable {
    let id: Int
    let username: String
    let email: String
    let full_name: String?
    let role: String
}

struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct LoginResponse: Codable {
    let access_token: String
    let token_type: String
    let user: User
}

struct StockSearchResult: Codable, Identifiable, Hashable {
    var id: String { symbol }
    let symbol: String
    let name: String
    let exchange: String
    let sector: String?
    let price: Double?
    let change: Double?
    let change_percent: Double?
}

struct StockDetail: Codable {
    let symbol: String
    let name: String
    let exchange: String
    let sector: String?
    let industry: String?
    let current_price: Double?
    let previous_close: Double?
    let day_high: Double?
    let day_low: Double?
    let volume: Int?
    let market_cap: Double?
    let pe_ratio: Double?
    let dividend_yield: Double?
    let fifty_two_week_high: Double?
    let fifty_two_week_low: Double?
}

struct Watchlist: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let is_default: Bool
    let is_public: Bool?
    let stock_count: Int?
    let stocks: [WatchlistStock]?
    let created_at: String?
    let updated_at: String?
}

struct WatchlistStock: Codable, Identifiable {
    let id: Int
    let symbol: String
    let exchange: String
    let added_at: String?
}

struct IndexData: Codable, Identifiable {
    var id: String { symbol }
    let symbol: String
    let name: String
    let value: Double?
    let change: Double?
    let change_percent: Double?
}

struct IndicesResponse: Codable {
    let indices: [IndexData]
    let last_updated: String?
}

struct NotificationSettings: Codable {
    let id: Int
    var email_enabled: Bool
    var email_for_price_alerts: Bool
    var email_for_volume_alerts: Bool
    var email_for_sentiment_alerts: Bool
    var email_for_ipo_alerts: Bool
    var email_digest_time: String
    var webhook_enabled: Bool
    var webhook_url: String?
    var webhook_events: [String]?
    var push_enabled: Bool
    var push_for_critical: Bool
    var push_for_price_changes: Bool
    var in_app_enabled: Bool
    var in_app_sound: Bool
    var in_app_badge: Bool
    var quiet_hours_enabled: Bool
    var quiet_hours_start: String
    var quiet_hours_end: String
    var quiet_hours_timezone: String
    var telegram_enabled: Bool
    var telegram_chat_id: String?
}

struct FCMDevice: Codable, Identifiable {
    let id: Int
    let device_name: String?
    let device_type: String
    let is_active: Bool
    let subscribed_topics: [String]
    let created_at: String
}

struct NewsItem: Codable, Identifiable {
    let id: String
    let title: String
    let source: String
    let published_at: String?
    let sentiment: String?
    let url: String?
}

struct AlertItem: Codable, Identifiable {
    let id: Int
    let symbol: String
    let alert_type: String
    let condition: String
    let threshold: Double
    let is_active: Bool
    let created_at: String
}
