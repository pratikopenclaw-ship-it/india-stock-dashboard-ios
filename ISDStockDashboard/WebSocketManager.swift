//
//  WebSocketManager.swift
//  ISDStockDashboard
//

import Foundation
import Combine

@MainActor
class WebSocketManager: ObservableObject {
    static let shared = WebSocketManager()

    private var webSocketTask: URLSessionWebSocketTask?
    private let baseURL = "wss://india-stock-dashboard.tailffeb2f.ts.net"
    private var reconnectTask: Task<Void, Never>?
    private var isConnecting = false

    @Published var livePrices: [String: LivePrice] = [:]
    @Published var indexPrices: [String: LivePrice] = [:]
    @Published var isConnected = false

    private init() {}

    func connect(symbols: [String]) {
        guard !isConnecting else { return }
        disconnect()
        isConnecting = true

        guard let token = APIClient.shared.accessToken,
              let url = URL(string: "\(baseURL)/ws/stocks") else {
            isConnecting = false
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()

        receiveMessage()

        // Subscribe to symbols
        let subs = ["action": "subscribe", "symbols": symbols]
        if let data = try? JSONSerialization.data(withJSONObject: subs) {
            webSocketTask?.send(.data(data)) { _ in }
        }

        isConnected = true
        isConnecting = false
    }

    func connectIndices() {
        guard !isConnecting else { return }
        disconnect()
        isConnecting = true

        guard let token = APIClient.shared.accessToken,
              let url = URL(string: "\(baseURL)/ws/indices") else {
            isConnecting = false
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()

        receiveMessage()
        isConnected = true
        isConnecting = false
    }

    func disconnect() {
        reconnectTask?.cancel()
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        isConnected = false
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let message):
                    switch message {
                    case .data(let data):
                        self?.handleData(data)
                    case .string(let text):
                        if let data = text.data(using: .utf8) {
                            self?.handleData(data)
                        }
                    @unknown default:
                        break
                    }
                    self?.receiveMessage()
                case .failure:
                    self?.isConnected = false
                    self?.scheduleReconnect()
                }
            }
        }
    }

    private func handleData(_ data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        if let type = json["type"] as? String {
            if type == "index_update", let indices = json["indices"] as? [[String: Any]] {
                for idx in indices {
                    if let symbol = idx["symbol"] as? String {
                        indexPrices[symbol] = LivePrice(
                            symbol: symbol,
                            price: idx["price"] as? Double ?? 0,
                            change: idx["change"] as? Double,
                            changePercent: idx["change_percent"] as? Double,
                            volume: idx["volume"] as? Int,
                            timestamp: idx["timestamp"] as? String
                        )
                    }
                }
            } else if let symbol = json["symbol"] as? String {
                livePrices[symbol] = LivePrice(
                    symbol: symbol,
                    price: json["price"] as? Double ?? 0,
                    change: json["change"] as? Double,
                    changePercent: json["change_percent"] as? Double,
                    volume: json["volume"] as? Int,
                    timestamp: json["timestamp"] as? String
                )
            }
        }
    }

    private func scheduleReconnect() {
        reconnectTask?.cancel()
        reconnectTask = Task {
            try? await Task.sleep(nanoseconds: 5 * 1_000_000_000)
            guard !Task.isCancelled else { return }
            // Reconnect with current subscriptions
        }
    }
}

struct LivePrice: Identifiable {
    let id = UUID()
    let symbol: String
    let price: Double
    let change: Double?
    let changePercent: Double?
    let volume: Int?
    let timestamp: String?
}
