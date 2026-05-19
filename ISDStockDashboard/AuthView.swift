//
//  AuthView.swift
//  ISDStockDashboard
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var username = ""
    @State private var password = ""
    @State private var isRegistering = false
    @State private var email = ""
    @State private var fullName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.isdBackground
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Logo
                    VStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 64))
                            .foregroundColor(.isdGreen)

                        Text("India Stock Dashboard")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.isdTextPrimary)

                        Text(isRegistering ? "Create your account" : "Sign in to continue")
                            .font(.subheadline)
                            .foregroundColor(.isdTextSecondary)
                    }
                    .padding(.top, 40)

                    // Form
                    VStack(spacing: 16) {
                        TextField("Username", text: $username)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color.isdCard)
                            .foregroundColor(.isdTextPrimary)
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))

                        if isRegistering {
                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding()
                                .background(Color.isdCard)
                                .foregroundColor(.isdTextPrimary)
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))

                            TextField("Full Name", text: $fullName)
                                .padding()
                                .background(Color.isdCard)
                                .foregroundColor(.isdTextPrimary)
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
                        }

                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color.isdCard)
                            .foregroundColor(.isdTextPrimary)
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
                    }

                    if let error = authManager.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.isdRed)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        Task {
                            if isRegistering {
                                // Registration not implemented in API client yet
                            } else {
                                await authManager.login(username: username, password: password)
                            }
                        }
                    } label: {
                        HStack {
                            if authManager.isLoading {
                                ProgressView()
                                    .tint(.isdTextPrimary)
                            }
                            Text(isRegistering ? "Create Account" : "Sign In")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.isdAccent)
                        .foregroundStyle(.isdTextPrimary)
                        .cornerRadius(6)
                    }
                    .disabled(username.isEmpty || password.isEmpty || authManager.isLoading)

                    // Demo credentials
                    VStack(spacing: 4) {
                        Text("DEMO CREDENTIALS")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.isdTextMuted)
                            .tracking(0.3)
                        Text("User: demo / demo123")
                            .font(.caption2)
                            .foregroundColor(.isdTextSecondary)
                        Text("Admin: admin / admin123")
                            .font(.caption2)
                            .foregroundColor(.isdTextSecondary)
                    }
                    .padding(.top, 8)

                    Spacer()
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthManager())
}
