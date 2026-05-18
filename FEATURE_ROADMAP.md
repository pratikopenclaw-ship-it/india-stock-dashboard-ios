# iOS Feature Roadmap — India Stock Dashboard

This document maps every web app feature to its iOS native equivalent.
Charts are intentionally deferred to a later phase (requires `DGCharts` or native `SwiftUI Charts` integration).

---

## Phase 1: Foundation (Already Built)

| # | Feature | Web Route | iOS Status | Notes |
|---|---------|-----------|------------|-------|
| 1 | Auth (Login) | `/auth/login` | Done | Cookie-based auth via URLSession |
| 2 | Dashboard | `/dashboard` | Done | Market indices grid with live values |
| 3 | Search | `/` (header) | Done | Real-time stock search with symbol/name/exchange |
| 4 | Stock Detail | `/stock/[symbol]` | Done | Price, day high/low, stats grid, add to watchlist |
| 5 | Watchlist | `/watchlist` | Done | List + detail + create new |
| 6 | Notifications Settings | `/notifications` | Done | Email/Push/Telegram/Quiet Hours |
| 7 | FCM Push Registration | `/api/fcm/register` | Done | Device token + topic subscription |

---

## Phase 2: High-Value Additions (No Charts Required)

| # | Feature | Web Route | iOS Priority | Why |
|---|---------|-----------|-------------|-----|
| 8 | News Feed | `/news` | High | Pure list view — sentiment, impact, topic filters |
| 9 | Alerts (Create + List) | `/alerts` | High | Push notification triggers from app |
| 10 | AI News Intelligence | `/news` (AI Insights bar) | Medium | Trending stocks, topics, sectors summary |
| 11 | Insider Trading Tracker | `/insider-screener` | Medium | Table view with filters (date, type, value) |
| 12 | Signals (Signal Lab) | `/signals` | High | Entry/exit signals, trade intelligence panel |
| 13 | Smart Money / FII DII Flow | `/smart-money` | Medium | Institutional flow, buy/sell ratios |
| 14 | Portfolio Holdings | `/holdings` | High | Real-time P&L, BUY/HOLD/SELL signals |
| 15 | Paper Trading | `/paper-trading` | Medium | Virtual portfolio, backtesting |
| 16 | Reports Portal | `/reports` | Low | Market intelligence + portfolio health |
| 17 | Screener (Basic) | `/screener` | Medium | Preset filters, results table (no charts) |
| 18 | IPO Calendar | `/ipo` | Low | List of upcoming IPOs with GMP data |
| 19 | Economic Calendar | `/calendar` | Low | Events list with impact ratings |
| 20 | War Room / Multi-Agent Debate | `/agents/debate` | Low | Bull vs bear text debate view |
| 21 | Risk Dashboard | `/agents/risk` | Low | Radial gauges for risk metrics |
| 22 | Profile / Preferences | `/profile` | Medium | Theme, timezone, language, password change |
| 23 | Admin Dashboard | `/admin/*` | Low | System stats, user management, logs |

---

## Phase 3: Charts + Advanced Visualizations

| # | Feature | Web Route | Blocker |
|---|---------|-----------|---------|
| 24 | Stock Charts (OHLCV) | `/stock/[symbol]` | Requires DGCharts or Swift Charts |
| 25 | NIFTY 50 Chart | `/nifty` | Requires charting library |
| 26 | Chart360 | `/chart360` | Multi-timeframe chart switching |
| 27 | Options Chain | `/options` | Complex table + Greeks visualization |
| 28 | GeoRisk Map | Dashboard widget | MapKit integration |
| 29 | Correlation Matrix | `/holdings` | Heatmap visualization |

---

## Phase 4: Platform-Specific iOS Enhancements

| # | Feature | Notes |
|---|---------|-------|
| 30 | Widgets (Home Screen + Lock Screen) | Live index prices, watchlist glance |
| 31 | Siri Shortcuts | "What's NIFTY 50 doing?" |
| 32 | Apple Watch Companion | Price alerts on wrist |
| 33 | Live Activities | Track active trade signals |
| 34 | Spotlight Search | Search stocks from iOS home screen |
| 35 | Universal Links | `/stock/RELIANCE` opens in app |
| 36 | Background Refresh | Keep watchlist prices fresh |
| 37 | Share Extension | Save news articles to watchlist |

---

## Design System Applied to iOS

### Colors
| Token | Hex | SwiftUI Usage |
|-------|-----|---------------|
| `bg-primary` | `#0B1120` | `Color(ISDColor.background)` |
| `bg-card` | `#1E293B` | `Color(ISDColor.card)` |
| `bg-elevated` | `#243042` | `Color(ISDColor.elevated)` |
| `accent-blue` | `#3B82F6` | `Color(ISDColor.accent)` |
| `accent-green` | `#10B981` | `.green` overridden |
| `accent-red` | `#EF4444` | `.red` overridden |
| `accent-gold` | `#F59E0B` | `Color(ISDColor.gold)` |
| `text-primary` | `#F1F5F9` | `.primary` in dark mode |
| `text-secondary` | `#94A3B8` | `.secondary` |
| `border-subtle` | `#334155` | `Color(ISDColor.border)` |

### Typography
- **Inter** → SF Pro (system default, closest match)
- **JetBrains Mono** → `SF Mono` or `Courier` for numbers/tickers
- All-caps + monospace for labels (`MARKET_SENTIMENT`, `BULLISH`)
- Tabular numerals for prices
- `₹` prefix for INR

### Layout
- Cards: 6px corner radius (SwiftUI `.cornerRadius(6)`)
- 1px subtle borders on cards
- No shadows by default
- 12px / 16px / 24px spacing rhythm

---

## API Endpoints Already Available

All of the following backend endpoints exist and are ready for iOS consumption:

- `GET /api/indices` — Market indices
- `GET /api/search?query=` — Stock search
- `GET /api/stock/{symbol}` — Stock detail
- `GET /api/watchlists` — User watchlists
- `POST /api/watchlists` — Create watchlist
- `POST /api/alerts` — Create alert
- `GET /api/alerts` — List alerts
- `GET /api/news` — News feed
- `GET /api/notifications/settings` — Notification config
- `PUT /api/notifications/settings` — Update config
- `POST /api/fcm/register` — Push token registration
- `GET /api/fcm/devices` — Registered devices
- `POST /api/notifications/test-telegram` — Test Telegram
- `POST /api/notifications/test-email` — Test Email
