//
//  SettingsView.swift
//  ISDStockDashboard
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var settings: NotificationSettings?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isSaving = false
    @State private var saveMessage: String?
    @State private var telegramChatId = ""

    private let api = APIClient.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.isdBackground.ignoresSafeArea()
                List {
                    if isLoading {
                    Section {
                        ProgressView("Loading settings...")
                            .tint(Color(hex: "#94A3B8"))
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
                                Task { await loadSettings() }
                            }
                        }
                    }
                } else if let settingsBinding = Binding($settings) {
                    emailSection(settings: settingsBinding)
                    pushSection(settings: settingsBinding)
                    telegramSection(settings: settingsBinding)
                    quietHoursSection(settings: settingsBinding)

                    Section {
                        Button {
                            Task {
                                await saveSettings(settingsBinding.wrappedValue)
                            }
                        } label: {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .tint(.white)
                                }
                                Text("Save Settings")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .disabled(isSaving)
                        .listRowBackground(Color.isdAccent)
                        .foregroundStyle(.white)
                    }

                    if let message = saveMessage {
                        Section {
                            Text(message)
                                .font(.caption)
                                .foregroundColor(.isdGreen)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }

                Section {
                    Button {
                        Task {
                            await authManager.logout()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .foregroundColor(.isdRed)
                }

                if let user = authManager.currentUser {
                    Section("Account") {
                        LabeledContent("Username", value: user.username)
                            .foregroundColor(.isdTextPrimary)
                        LabeledContent("Email", value: user.email)
                            .foregroundColor(.isdTextPrimary)
                        if let fullName = user.full_name {
                            LabeledContent("Name", value: fullName)
                                .foregroundColor(.isdTextPrimary)
                        }
                        LabeledContent("Role", value: user.role.capitalized)
                            .foregroundColor(.isdTextPrimary)
                    }
                }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .refreshable {
                await loadSettings()
            }
            .task {
                await loadSettings()
            }
        }
    }

    private func emailSection(settings: Binding<NotificationSettings>) -> some View {
        Section {
            Toggle("Enable Email Notifications", isOn: settings.email_enabled)

            if settings.wrappedValue.email_enabled {
                Toggle("Price Alerts", isOn: settings.email_for_price_alerts)
                Toggle("Volume Alerts", isOn: settings.email_for_volume_alerts)
                Toggle("Sentiment Alerts", isOn: settings.email_for_sentiment_alerts)
                Toggle("IPO Alerts", isOn: settings.email_for_ipo_alerts)

                DatePicker("Daily Digest Time",
                          selection: digestTimeBinding(settings),
                          displayedComponents: .hourAndMinute)
            }
        } header: {
            Label("Email Notifications", systemImage: "envelope.fill")
        }
    }

    private func pushSection(settings: Binding<NotificationSettings>) -> some View {
        Section {
            Toggle("Enable Push Notifications", isOn: settings.push_enabled)

            if settings.wrappedValue.push_enabled {
                Toggle("Critical Alerts", isOn: settings.push_for_critical)
                Toggle("Price Changes", isOn: settings.push_for_price_changes)
            }
        } header: {
            Label("Push Notifications", systemImage: "bell.fill")
        }
    }

    private func telegramSection(settings: Binding<NotificationSettings>) -> some View {
        Section {
            Toggle("Enable Telegram Alerts", isOn: settings.telegram_enabled)

            if settings.wrappedValue.telegram_enabled {
                TextField("Telegram Chat ID", text: $telegramChatId)
                    .keyboardType(.numberPad)
                    .onChange(of: telegramChatId) { _, newValue in
                        settings.telegram_chat_id.wrappedValue = newValue.isEmpty ? nil : newValue
                    }

                Button {
                    Task {
                        await testTelegram()
                    }
                } label: {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text("Send Test Message")
                    }
                }
            }
        } header: {
            Label("Telegram", systemImage: "paperplane.fill")
        } footer: {
            Text("Enter your Telegram Chat ID to receive alerts via Telegram bot @Isdaler_bot")
        }
    }

    private func quietHoursSection(settings: Binding<NotificationSettings>) -> some View {
        Section {
            Toggle("Enable Quiet Hours", isOn: settings.quiet_hours_enabled)

            if settings.wrappedValue.quiet_hours_enabled {
                DatePicker("Start",
                          selection: quietHoursStartBinding(settings),
                          displayedComponents: .hourAndMinute)

                DatePicker("End",
                          selection: quietHoursEndBinding(settings),
                          displayedComponents: .hourAndMinute)
            }
        } header: {
            Label("Quiet Hours", systemImage: "moon.fill")
        }
    }

    private func loadSettings() async {
        isLoading = true
        errorMessage = nil
        do {
            settings = try await api.fetchNotificationSettings()
            telegramChatId = settings?.telegram_chat_id ?? ""
        } catch APIError.unauthorized {
            errorMessage = "Please sign in to view settings"
        } catch {
            errorMessage = "Failed to load notification settings"
        }
        isLoading = false
    }

    private func saveSettings(_ newSettings: NotificationSettings) async {
        isSaving = true
        saveMessage = nil
        do {
            settings = try await api.updateNotificationSettings(newSettings)
            saveMessage = "Settings saved successfully!"
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                saveMessage = nil
            }
        } catch {
            saveMessage = "Failed to save settings"
        }
        isSaving = false
    }

    private func testTelegram() async {
        do {
            let message = try await api.testTelegram()
            saveMessage = message
        } catch {
            saveMessage = "Failed to send Telegram test"
        }
    }

    private func digestTimeBinding(_ settings: Binding<NotificationSettings>) -> Binding<Date> {
        Binding(
            get: {
                timeFromString(settings.wrappedValue.email_digest_time) ?? Date()
            },
            set: { newDate in
                settings.wrappedValue.email_digest_time = timeStringFromDate(newDate)
            }
        )
    }

    private func quietHoursStartBinding(_ settings: Binding<NotificationSettings>) -> Binding<Date> {
        Binding(
            get: {
                timeFromString(settings.wrappedValue.quiet_hours_start) ?? Date()
            },
            set: { newDate in
                settings.wrappedValue.quiet_hours_start = timeStringFromDate(newDate)
            }
        )
    }

    private func quietHoursEndBinding(_ settings: Binding<NotificationSettings>) -> Binding<Date> {
        Binding(
            get: {
                timeFromString(settings.wrappedValue.quiet_hours_end) ?? Date()
            },
            set: { newDate in
                settings.wrappedValue.quiet_hours_end = timeStringFromDate(newDate)
            }
        )
    }

    private func timeFromString(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: timeString)
    }

    private func timeStringFromDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthManager())
}
