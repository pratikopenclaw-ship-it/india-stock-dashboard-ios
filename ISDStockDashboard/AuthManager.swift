//
//  AuthManager.swift
//  ISDStockDashboard
//

import SwiftUI
import Combine

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isCheckingAuth = true
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api = APIClient.shared
    private var refreshTask: Task<Void, Never>?

    init() {
        Task {
            await checkAuthStatus()
        }
    }

    func checkAuthStatus() async {
        isCheckingAuth = true
        defer { isCheckingAuth = false }
        do {
            let user = try await api.fetchCurrentUser()
            self.currentUser = user
            self.isAuthenticated = true
            startTokenRefresh()
        } catch {
            self.isAuthenticated = false
            self.currentUser = nil
        }
    }

    func login(username: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await api.login(username: username, password: password)
            // Login POST succeeded and cookies + bearer token are set.
            // Now fetch user profile — retry once if cookies need a moment to sync.
            do {
                let user = try await api.fetchCurrentUser()
                self.currentUser = user
                self.isAuthenticated = true
                startTokenRefresh()
            } catch APIError.unauthorized {
                try await Task.sleep(nanoseconds: 300_000_000)
                let user = try await api.fetchCurrentUser()
                self.currentUser = user
                self.isAuthenticated = true
                startTokenRefresh()
            }
            self.isLoading = false
        } catch APIError.unauthorized {
            self.errorMessage = "Invalid username or password"
            self.isLoading = false
        } catch APIError.serverError(let detail) {
            self.errorMessage = detail
            self.isLoading = false
        } catch {
            self.errorMessage = "Network error. Please try again."
            self.isLoading = false
        }
    }

    func logout() async {
        refreshTask?.cancel()
        _ = try? await api.logout()
        isAuthenticated = false
        currentUser = nil
    }

    private func startTokenRefresh() {
        refreshTask?.cancel()
        refreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 10 * 60 * 1_000_000_000) // 10 minutes
                guard !Task.isCancelled else { return }
                let success = try? await api.refreshToken()
                if success == false {
                    await MainActor.run {
                        self.isAuthenticated = false
                        self.currentUser = nil
                    }
                    return
                }
            }
        }
    }
}
