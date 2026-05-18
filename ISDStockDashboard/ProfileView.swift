//
//  ProfileView.swift
//  ISDStockDashboard
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var profile: UserProfile?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showSignOutConfirmation = false

    private let api = APIClient.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.isdBackground.ignoresSafeArea()
                List {
                    if isLoading {
                        Section {
                            ProgressView("Loading profile...")
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
                                    Task { await loadProfile() }
                                }
                            }
                        }
                    } else if let user = profile {
                        profileSection(user: user)
                        accountActionsSection
                        appInfoSection
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Profile")
            .refreshable {
                await loadProfile()
            }
            .task {
                await loadProfile()
            }
            .confirmationDialog("Sign Out", isPresented: $showSignOutConfirmation, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) {
                    Task { await authManager.logout() }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }

    private func profileSection(user: UserProfile) -> some View {
        Section {
            VStack(alignment: .center, spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.isdAccent)

                Text(user.username)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.isdTextPrimary)

                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.isdTextSecondary)

                if let fullName = user.full_name {
                    Text(fullName)
                        .font(.subheadline)
                        .foregroundColor(.isdTextSecondary)
                }

                Text(user.role.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .foregroundColor(.isdAccentLight)
                    .background(Color.isdAccent.opacity(0.10))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.isdAccent.opacity(0.30), lineWidth: 1))
                    .cornerRadius(4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.isdCard)
        }
    }

    private var accountActionsSection: some View {
        Section("Account") {
            Button {
                showSignOutConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.isdRed)
                    Text("Sign Out")
                        .foregroundColor(.isdRed)
                    Spacer()
                }
            }
        }
    }

    private var appInfoSection: some View {
        Section("App Info") {
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

            LabeledContent("Version", value: "\(version) (\(build))")
                .foregroundColor(.isdTextPrimary)

            LabeledContent("Platform", value: "iOS \(UIDevice.current.systemVersion)")
                .foregroundColor(.isdTextPrimary)
        }
    }

    private func loadProfile() async {
        isLoading = true
        errorMessage = nil
        do {
            profile = try await api.fetchUserProfile()
        } catch APIError.unauthorized {
            errorMessage = "Please sign in to view profile"
        } catch {
            errorMessage = "Failed to load profile"
        }
        isLoading = false
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
}
