//
//  PushNotificationManager.swift
//  ISDStockDashboard
//

import SwiftUI
import UserNotifications

@MainActor
class PushNotificationManager: ObservableObject {
    static let shared = PushNotificationManager()

    @Published var isRegistered = false
    @Published var deviceToken: String?
    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined

    private let api = APIClient.shared

    func requestPermission() async -> Bool {
        do {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            permissionStatus = settings.authorizationStatus

            if settings.authorizationStatus == .notDetermined {
                let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
                permissionStatus = granted ? .authorized : .denied
                return granted
            }

            return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
        } catch {
            return false
        }
    }

    func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    func registerDeviceToken(_ token: Data) async {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        deviceToken = tokenString

        do {
            let deviceName = UIDevice.current.name
            try await api.registerFCMDevice(token: tokenString, deviceName: deviceName)
            isRegistered = true
        } catch {
            print("Failed to register FCM device: \(error)")
        }
    }

    func unregister() async {
        isRegistered = false
        deviceToken = nil
    }
}

// MARK: - App Delegate for Push Notifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task {
            await PushNotificationManager.shared.registerDeviceToken(deviceToken)
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .badge, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
