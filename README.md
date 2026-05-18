# ISD Stock Dashboard - iOS App

Native SwiftUI iOS app for the India Stock Dashboard platform.

## Architecture

- **SwiftUI** - Native UI framework (no web wrapper)
- **Cookie-based auth** - HttpOnly cookies via `URLSession` cookie storage
- **APIClient** - Centralized async/await networking layer
- **Push Notifications** - APNs + FCM device token registration

## Features

- Dashboard with market indices (NIFTY 50, SENSEX, BANKNIFTY)
- Stock search with real-time results
- Watchlist management
- Notification settings (Email, Push, Telegram)
- Native push notification support
- Stock detail view with key metrics

## Setup

1. Open `ISDStockDashboard.xcodeproj` in Xcode 15+
2. Set your Team in Signing & Capabilities
3. Add Push Notifications capability
4. Build and run on device or simulator

## API Configuration

Update `baseURL` in `APIClient.swift`:
```swift
private let baseURL = "https://india-stock-dashboard.tailffeb2f.ts.net"
```

## Push Notifications

1. Enable Push Notifications in app capabilities
2. Configure APNs certificate or key in Apple Developer portal
3. The app auto-registers device tokens with the backend `/api/fcm/register`

## Project Structure

```
ISDStockDashboard/
├── ISDApp.swift              - App entry point with auth routing
├── APIClient.swift           - Network layer with cookie auth
├── AuthManager.swift         - Authentication state management
├── Models.swift              - Data models (User, Stock, Watchlist, etc.)
├── PushNotificationManager.swift - APNs/FCM integration
├── Views/
│   ├── AuthView.swift        - Login screen
│   ├── ContentView.swift     - Main tab navigation
│   ├── DashboardView.swift   - Market overview
│   ├── SearchView.swift      - Stock search
│   ├── StockDetailView.swift - Stock detail
│   ├── WatchlistView.swift   - Watchlists
│   └── SettingsView.swift    - Notification settings
```
