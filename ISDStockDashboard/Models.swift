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
    let refresh_token: String
    let token_type: String
    let expires_in: Int
    let role: String
    let user_id: String?
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

// MARK: - Signals

struct IndicatorScore: Codable {
    let name: String
    let score: Double
    let weight: Double
}

struct TradingSignal: Codable, Identifiable {
    var id: String { symbol }
    let symbol: String
    let signal: String
    let confidence: Double
    let confidence_level: String
    let direction: String
    let current_price: Double
    let timestamp: String
    let indicators: [IndicatorScore]
    let recommendation: String
    let entry_price: Double?
    let exit_target: Double?
    let stop_loss: Double?
    let risk_reward: Double?
    let time_horizon: String?
    let news_sentiment_score: Double?
    let news_sentiment_label: String?
}

struct MarketSignalsResponse: Codable {
    let timestamp: String
    let signals: [TradingSignal]
    let summary: MarketSignalSummary
}

struct MarketSignalSummary: Codable {
    let strong_buy: Int
    let buy: Int
    let hold: Int
    let sell: Int
    let strong_sell: Int
    let total: Int
}

// MARK: - Holdings

struct UserHolding: Codable, Identifiable {
    let id: String
    let symbol: String
    let quantity: Double
    let buy_price: Double
    let buy_date: String?
    let notes: String?
    let created_at: String
    let updated_at: String
}

struct CorrelationMatrix: Codable {
    let correlations: [CorrelationRow]
    let sectors: [SectorAllocation]
    let portfolio_value: Double
    let concentration_warning: Bool
    let max_sector_pct: Double
}

struct CorrelationRow: Codable, Identifiable {
    var id: String { symbol }
    let symbol: String
    let values: [CorrelationValue]
}

struct CorrelationValue: Codable, Identifiable {
    var id: String { symbol }
    let symbol: String
    let corr: Double?
}

struct SectorAllocation: Codable {
    let sector: String
    let value: Double
    let pct: Double
}

// MARK: - Insider Trading

struct InsiderTrade: Codable, Identifiable {
    let id: Int
    let symbol: String
    let company_name: String?
    let insider_name: String
    let designation: String
    let transaction_type: String
    let transaction_type_display: String?
    let transaction_date: String
    let quantity: Double?
    let price: Double?
    let value: Double?
    let exchange: String?
}

struct InsiderTradeListResponse: Codable {
    let trades: [InsiderTrade]
    let total: Int
    let page: Int
    let page_size: Int
}

struct PromoterConfidenceSummary: Codable, Identifiable {
    var id: String { symbol }
    let symbol: String
    let companyName: String
    let score: Int
    let signal: String
    let trendDirection: String
    let trendPercentage: Double
}

struct PromoterConfidenceResponse: Codable {
    let summaries: [PromoterConfidenceSummary]
}

// MARK: - User Profile

struct UserProfile: Codable {
    let id: Int
    let username: String
    let email: String
    let full_name: String?
    let role: String
    let created_at: String?
    let updated_at: String?
}

struct UserPreferences: Codable {
    let timezone: String?
    let language: String?
    let theme: String?
}

// MARK: - Chart

struct ChartDataPoint: Codable {
    let time: Double
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double?
}

struct StockChartResponse: Codable {
    let symbol: String
    let timeframe: String
    let data: [ChartDataPoint]
    let current_price: Double?
    let source: String?
}

// MARK: - Screener

struct ScreenerStock: Codable, Identifiable {
    var id: String { symbol }
    let symbol: String
    let company_name: String
    let close_price: Double?
    let change_percent: Double?
    let market_cap: Int?
    let pe_ratio: Double?
    let pb_ratio: Double?
    let roe: Double?
    let debt_equity: Double?
    let dividend_yield: Double?
    let eps: Double?
    let industry: String?
    let sector: String?
    let rsi_14: Double?
    let macd_signal_type: String?
    let above_sma_20: Bool?
    let above_sma_50: Bool?
    let above_sma_200: Bool?
    let ai_score: Double?
    let technical_score: Double?
    let fundamental_score: Double?
    let ai_rank: Int?
    let recommendation: String?
    let category: String?
}

struct ScreenerResponse: Codable {
    let data: [ScreenerStock]
    let pagination: ScreenerPagination
    let filters_applied: ScreenerFiltersApplied?
    let stats: ScreenerStats?
}

struct ScreenerPagination: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let total_pages: Int
}

struct ScreenerFiltersApplied: Codable {
    let total_results: Int
    let filtered_from: Int
}

struct ScreenerStats: Codable {
    let average_ai_score: Double?
}

struct ScreenerQuickStats: Codable {
    let total_stocks: Int
    let recommendation_distribution: [String: Int]
    let category_distribution: [String: Int]
    let top_gainers: [ScreenerTopGainer]
}

struct ScreenerTopGainer: Codable {
    let symbol: String
    let company_name: String
    let change_percent: Double
}

// MARK: - IPO

struct IPOItem: Codable, Identifiable {
    var id: String { symbol }
    let symbol: String
    let company_name: String
    let status: String
    let issue_type: String?
    let issue_size_crores: Double?
    let issue_price_low: Double?
    let issue_price_high: Double?
    let issue_price_final: Double?
    let lot_size: Int?
    let open_date: String?
    let close_date: String?
    let basis_date: String?
    let listing_date: String?
    let total_subscription: Double?
    let qib_subscription: Double?
    let nii_subscription: Double?
    let retail_subscription: Double?
    let current_gmp: Double?
    let gmp_percent: Double?
    let listing_gain_percent: Double?
    let current_gain_percent: Double?
    let pe_ratio: Double?
    let market_cap_crores: Double?
}

struct IPOListResponse: Codable {
    let data: [IPOItem]
    let total: Int
    let page: Int
    let per_page: Int
    let has_more: Bool
}

struct IPOStatistics: Codable {
    let total_ipos: Int
    let active_count: Int
    let upcoming_count: Int
    let closed_count: Int
    let listed_count: Int
    let avg_listing_gain: Double?
    let total_fund_raised: Double?
}

// MARK: - Smart Money

struct FiiDiiSummary: Codable {
    let fii_net: Double?
    let dii_net: Double?
    let fii_buy: Double?
    let fii_sell: Double?
    let dii_buy: Double?
    let dii_sell: Double?
    let date: String?
    let source: String?
    let fii_trend: String?
    let dii_trend: String?
}

struct BulkDeal: Codable, Identifiable {
    var id: String { "\(symbol)_\(date ?? "")" }
    let symbol: String
    let company_name: String?
    let deal_type: String?
    let client_name: String?
    let deal_quantity: Double?
    let deal_price: Double?
    let date: String?
    let exchange: String?
}

struct BulkDealsResponse: Codable {
    let deals: [BulkDeal]
    let total: Int
}

// MARK: - Agent Debate

struct AgentAnalysisRecord: Codable, Identifiable {
    let id: Int
    let ticker: String
    let trade_date: String
    let signal: String
    let analyst_reports: [String: String]?
    let debate: AgentDebate?
    let risk_debate: AgentRiskDebate?
    let investment_plan: String?
    let trader_proposal: String?
    let final_decision: String?
    let holdings_aware_decision: String?
    let created_at: String?
}

struct AgentDebate: Codable {
    let bull_history: String?
    let bear_history: String?
    let history: String?
    let judge_decision: String?
}

struct AgentRiskDebate: Codable {
    let aggressive: String?
    let conservative: String?
    let neutral: String?
    let judge_decision: String?
}

struct AgentJobResponse: Codable {
    let job_id: String
    let status: String
    let ticker: String?
    let date: String?
    let detail: String?
    let signal: String?
    let analyst_reports: [String: String]?
    let debate: AgentDebate?
    let risk_debate: AgentRiskDebate?
    let investment_plan: String?
    let trader_proposal: String?
    let final_decision: String?
    let holdings_aware_decision: String?
}

struct AgentAccuracy: Codable {
    let overall_accuracy: Double
    let evaluated: Int
    let correct: Int
    let days_forward: Int
    let signal_breakdown: [String: AgentSignalStat]
    let recent_results: [AgentAccuracyResult]
}

struct AgentSignalStat: Codable {
    let correct: Int
    let total: Int
    let accuracy: Double
}

struct AgentAccuracyResult: Codable {
    let ticker: String
    let signal: String
    let signal_date: String
    let start_price: Double
    let end_price: Double
    let pct_change: Double
    let correct: Bool
}

// MARK: - Live Price

struct LivePriceData: Codable {
    let price: Double
    let change: Double?
    let changePercent: Double?
    let volume: Int?
    let market_cap: Double?
    let pe_ratio: Double?
    let pb_ratio: Double?
    let roe: Double?
    let dividend_yield: Double?
}

// MARK: - NIFTY 50

struct NiftySummary: Codable {
    let price: Double?
    let change: Double?
    let change_percent: Double?
    let sector_performance: [SectorPerformance]?
    let top_gainers: [StockSearchResult]?
    let top_losers: [StockSearchResult]?
    let sentiment: String?
}

struct SectorPerformance: Codable, Identifiable {
    var id: String { sector }
    let sector: String
    let change_percent: Double
}

// MARK: - Options Chain

struct OptionsChain: Codable {
    let symbol: String
    let spot_price: Double
    let expiry_date: String?
    let strikes: [StrikeData]
    let summary: OptionsSummary?
}

struct StrikeData: Codable, Identifiable {
    var id: Int { strike }
    let strike: Int
    let ce_oi: Int
    let ce_oi_change: Int
    let ce_volume: Int
    let ce_iv: Double
    let pe_oi: Int
    let pe_oi_change: Int
    let pe_volume: Int
    let pe_iv: Double
    let pcr: Double
    let is_atm: Bool
}

struct OptionsSummary: Codable {
    let total_ce_oi: Int
    let total_pe_oi: Int
    let total_ce_volume: Int
    let total_pe_volume: Int
    let pcr: Double
}

// MARK: - Paper Trading

struct PaperPortfolio: Codable {
    let cash: Double
    let invested: Double
    let total_value: Double
    let total_pnl: Double
    let pnl_percent: Double
    let positions: [PaperPosition]
    let starting_capital: Double
}

struct PaperPosition: Codable, Identifiable {
    let id: String { symbol }
    let symbol: String
    let quantity: Double
    let avg_price: Double
    let current_price: Double?
    let invested: Double
    let current_value: Double?
    let pnl: Double?
    let pnl_percent: Double?
}

struct PaperTrade: Codable, Identifiable {
    let id: String
    let symbol: String
    let action: String
    let quantity: Double
    let price: Double
    let total_value: Double
    let notes: String?
    let created_at: String
}

// MARK: - Calendar

struct EarningsEvent: Codable, Identifiable {
    let id: String
    let symbol: String
    let company_name: String?
    let event_type: String
    let event_date: String
    let eps_estimate: Double?
    let revenue_estimate: Double?
    let fiscal_quarter: String?
}

// MARK: - 52-Week

struct Week52Response: Codable {
    let data: [Week52Stock]
    let total: Int
}

struct Week52Stock: Codable, Identifiable {
    var id: String { symbol }
    let symbol: String
    let company_name: String
    let close_price: Double?
    let change_percent: Double?
    let week_52_high: Double?
    let week_52_low: Double?
    let distance_from_high: Double?
    let distance_from_low: Double?
}

// MARK: - Reports

struct ResearchReport: Codable, Identifiable {
    let id: String
    let title: String
    let broker: String?
    let rating: String?
    let target_price: Double?
    let symbol: String?
    let date: String?
    let summary: String?
}

// MARK: - Signal Accuracy

struct SignalAccuracyResponse: Codable {
    let overall_accuracy: Double
    let evaluated: Int
    let correct: Int
    let days_forward: Int
    let signal_breakdown: [String: AgentSignalStat]
    let recent_results: [AgentAccuracyResult]
}

// MARK: - Trade Planner

struct TradePlan: Codable {
    let symbol: String
    let position_size: Double?
    let risk_per_trade: Double?
    let stop_loss: Double?
    let take_profit: Double?
    let risk_reward: Double?
    let max_position_value: Double?
    let recommendation: String?
}

// MARK: - Market Breadth

struct MarketBreadth: Codable {
    let advances: Int
    let declines: Int
    let unchanged: Int
    let advance_decline_ratio: Double?
    let new_52w_high: Int
    let new_52w_low: Int
}

// MARK: - Stock Detail Enhancements

struct StockSentiment: Codable {
    let overall: String?
    let score: Double?
    let bullish_pct: Double?
    let bearish_pct: Double?
    let neutral_pct: Double?
    let news_score: Double?
    let social_score: Double?
    let technical_score: Double?
}

struct SupportResistance: Codable {
    let support_levels: [PriceLevel]
    let resistance_levels: [PriceLevel]
    let current_price: Double?
}

struct PriceLevel: Codable, Identifiable {
    var id: UUID = UUID()
    let price: Double
    let strength: String?
    let touches: Int?

    enum CodingKeys: String, CodingKey {
        case price, strength, touches
    }
}

struct DeepAnalysis: Codable {
    let symbol: String
    let summary: String?
    let strengths: [String]?
    let weaknesses: [String]?
    let opportunities: [String]?
    let threats: [String]?
    let valuation: String?
    let recommendation: String?
    let confidence: Double?
}

