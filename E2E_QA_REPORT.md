# E2E QA Report: iOS App vs Web App
## India Stock Dashboard — 2026-05-18

---

## Executive Summary

| Metric | iOS App | Web App | Gap |
|--------|---------|---------|-----|
| **Pages/Screens** | 12 tabs | 25+ pages | **13+ pages missing** |
| **API Coverage** | ~18 endpoints | ~40+ endpoints | **~22 endpoints not wired** |
| **Real-time Features** | Polling only | WebSocket live prices | **No WebSocket on iOS** |
| **Admin Features** | None | Full admin panel | **100% missing** |
| **Overall Status** | Core MVP | Production | **Substantial gaps remain** |

---

## 1. MISSING PAGES (Not Implemented on iOS)

These web app pages have **no iOS equivalent**:

| # | Web Page | Description | Priority |
|---|----------|-------------|----------|
| 1 | `/nifty` | NIFTY 50 detailed view with sector breakdown, heatmap, sentiment | **High** |
| 2 | `/paper-trading` | Virtual portfolio, trade simulator, P&L tracking | **High** |
| 3 | `/options` | Options chain, strike prices, OI, Greeks | **High** |
| 4 | `/calendar` | Earnings calendar, economic events, IPO dates | **Medium** |
| 5 | `/52week` | 52-Week High/Low scanner with filters | **Medium** |
| 6 | `/additional-market-info` | Market breadth, advance-decline, sector performance | **Medium** |
| 7 | `/reports` | Equity research reports, PDF download, ratings | **Medium** |
| 8 | `/signal-accuracy` | Signal backtesting, accuracy tracker, win rate | **Medium** |
| 9 | `/trade-planner` | Trade planning tool, position sizing, risk calculator | **Medium** |
| 10 | `/chart360` | 360-degree stock chart with multiple overlays | **Low** |
| 11 | `/agents/risk` | Agent risk analysis dashboard | **Low** |
| 12 | `/agents` | Agent hub/main page | **Low** |
| 13 | `/news` | Dedicated news feed page (iOS has view but no tab) | **Low** |
| 14 | `/professional-screener` | Advanced screener with 50+ filters | **Medium** |
| 15 | `/insider-screener` | Insider trading screener with filters | **Medium** |
| 16 | `/admin/*` | Admin panel (users, logs, security, system, content) | **Low** |
| 17 | `/profile/memory` | User memory/preferences storage | **Low** |

---

## 2. PARTIALLY IMPLEMENTED PAGES

### 2.1 Dashboard
| Feature | Web | iOS | Gap |
|---------|-----|-----|-----|
| Market indices cards | ✅ | ✅ | — |
| Quick action buttons | ✅ | ✅ (limited) | Missing: Paper Trading, Options quick links |
| Sector heatmap | ✅ | ❌ | **Missing** |
| Market breadth widget | ✅ | ❌ | **Missing** |
| Top stock picks | ✅ | ❌ | **Missing** |
| Index ticker scroll | ✅ | ❌ | **Missing** |
| AI chat widget | ✅ | ❌ | **Missing** |
| WebSocket live prices | ✅ | ❌ | **Missing** (polling only) |
| **Status** | | | **Partial** |

### 2.2 Stock Detail (`/stock/[symbol]`)
| Feature | Web | iOS | Gap |
|---------|-----|-----|-----|
| Basic info (price, change, stats) | ✅ | ✅ | — |
| Candlestick chart | ✅ | ✅ | — |
| Timeframe picker (1D-MAX) | ✅ | ✅ | — |
| WebSocket live price updates | ✅ | ❌ | **Missing** |
| Sentiment distribution gauge | ✅ | ❌ | **Missing** |
| Support/Resistance levels | ✅ | ❌ | **Missing** |
| Deep Analysis tab | ✅ | ❌ | **Missing** |
| Multi-timeframe signal strip | ✅ | ❌ | **Missing** |
| Holdings-aware recommendation banner | ✅ | ❌ | **Missing** |
| News section | ✅ | ❌ | **Missing** |
| Add to watchlist with selection | ✅ | ❌ | Button exists but not implemented |
| Create alert from stock | ✅ | ❌ | Sheet shows "Coming Soon" |
| **Status** | | | **Partial** |

### 2.3 Signals
| Feature | Web | iOS | Gap |
|---------|-----|-----|-----|
| Signal list with badges | ✅ | ✅ | — |
| Confidence score display | ✅ | ✅ | — |
| Signal counts summary | ✅ | ✅ | — |
| Source toggle (Market vs Watchlist) | ✅ | ❌ | **Missing** |
| Watchlist dropdown selector | ✅ | ❌ | **Missing** |
| Trade planner slide-over | ✅ | ❌ | **Missing** |
| PM decision modal | ✅ | ❌ | **Missing** |
| Insider confidence strip | ✅ | ❌ | **Missing** |
| Candlestick patterns | ✅ | ❌ | **Missing** |
| Chart patterns | ✅ | ❌ | **Missing** |
| News sentiment score | ✅ | ❌ | **Missing** |
| **Status** | | | **Partial** |

### 2.4 Screener
| Feature | Web | iOS | Gap |
|---------|-----|-----|-----|
| Filter chips (BUY/HOLD/SELL) | ✅ | ✅ | — |
| Stock list with price/change | ✅ | ✅ | — |
| AI score display | ✅ | ✅ | — |
| Filter sidebar (50+ filters) | ✅ | ❌ | **Missing** |
| Sortable table headers | ✅ | ❌ | **Missing** |
| Save filter presets | ✅ | ❌ | **Missing** |
| CSV export | ✅ | ❌ | **Missing** |
| Data source toggle (Live/Database) | ✅ | ❌ | **Missing** |
| Universe toggle (Nifty 500/All) | ✅ | ❌ | **Missing** |
| Pagination controls | ✅ | ❌ | **Missing** |
| Professional presets (Warren Buffett, CANSLIM) | ✅ | ❌ | **Missing** |
| **Status** | | | **Partial** |

### 2.5 Smart Money
| Feature | Web | iOS | Gap |
|---------|-----|-----|-----|
| FII/DII summary cards | ✅ | ✅ | — |
| Bulk/Block deals list | ✅ | ✅ | — |
| 7-day rolling averages | ✅ | ❌ | **Missing** |
| Animated FII/DII ratio bars | ✅ | ❌ | **Missing** |
| AI sentiment summary cards | ✅ | ❌ | **Missing** |
| **Status** | | | **Partial** |

### 2.6 Agent Debate
| Feature | Web | iOS | Gap |
|---------|-----|-----|-----|
| Analysis history list | ✅ | ✅ | — |
| Bull/Bear debate view | ✅ | ✅ | — |
| Investment plan | ✅ | ✅ | — |
| Start new analysis | ✅ | ✅ | — |
| Risk tab | ✅ | ❌ | **Missing** |
| Memory tab | ✅ | ❌ | **Missing** |
| Holdings context badge | ✅ | ❌ | **Missing** |
| Analyst cards | ✅ | ❌ | **Missing** |
| Portfolio Manager recommendation | ✅ | ❌ | **Missing** |
| Agent accuracy stats | ✅ | ✅ | — |
| **Status** | | | **Partial** |

### 2.7 Alerts
| Feature | Web | iOS | Gap |
|---------|-----|-----|-----|
| Alert list | ✅ | ✅ | — |
| Create alert | ✅ | ✅ | — |
| Delete alert | ✅ | ❌ | Swipe-to-delete UI exists but API not wired |
| Combo conditions (AND/OR) | ✅ | ❌ | **Missing** |
| Webhook URL support | ✅ | ❌ | **Missing** |
| Cooldown period | ✅ | ❌ | **Missing** |
| Push/Email/Telegram toggles per alert | ✅ | ❌ | **Missing** |
| Price target visualization | ✅ | ❌ | **Missing** |
| **Status** | | | **Partial** |

### 2.8 Profile
| Feature | Web | iOS | Gap |
|---------|-----|-----|-----|
| User info display | ✅ | ✅ | — |
| Security tab (password change, 2FA) | ✅ | ❌ | **Missing** |
| Preferences tab | ✅ | ❌ | **Missing** |
| Activity log | ✅ | ❌ | **Missing** |
| Notification settings | ✅ | ✅ | — |
| FCM device management | ✅ | ✅ | — |
| **Status** | | | **Partial** |

### 2.9 Holdings (Portfolio)
| Feature | Web | iOS | Gap |
|---------|-----|-----|-----|
| Holdings list | ✅ | ✅ | — |
| P&L calculation | ✅ | ✅ | — |
| Add/Delete holding | ✅ | ✅ | — |
| Correlation matrix | ✅ | ❌ | **Missing** |
| AI recommendation per holding | ✅ | ❌ | **Missing** |
| Sector allocation chart | ✅ | ❌ | **Missing** |
| **Status** | | | **Partial** |

### 2.10 Watchlist
| Feature | Web | iOS | Gap |
|---------|-----|-----|-----|
| Watchlist list | ✅ | ✅ | — |
| Stock detail per watchlist | ✅ | ✅ | — |
| Add to watchlist | ✅ | ❌ | API exists but UI not wired in stock detail |
| Remove from watchlist | ✅ | ✅ | — |
| Create/Delete watchlist | ✅ | ✅ | — |
| Kite live prices via WebSocket | ✅ | ❌ | **Missing** |
| **Status** | | | **Partial** |

### 2.11 IPO Calendar
| Feature | Web | iOS | Gap |
|---------|-----|-----|-----|
| Active/Upcoming/Listed tabs | ✅ | ✅ | — |
| IPO cards with GMP | ✅ | ✅ | — |
| Statistics | ✅ | ✅ | — |
| Subscription tracking | ✅ | ❌ | **Missing** |
| Allotment status check | ✅ | ❌ | **Missing** |
| **Status** | | | **Partial** |

### 2.12 Insider Trading
| Feature | Web | iOS | Gap |
|---------|-----|-----|-----|
| Trade list | ✅ | ✅ | — |
| Promoter confidence | ✅ | ✅ | — |
| Filter by transaction type | ✅ | ❌ | **Missing** |
| Summary per symbol | ✅ | ❌ | **Missing** |
| **Status** | | | **Partial** |

---

## 3. API ENDPOINTS NOT WIRED ON iOS

| Endpoint | Used By | Status |
|----------|---------|--------|
| `POST /api/auth/register` | Registration | ❌ Not implemented |
| `GET /api/kite/prices/unified/{symbol}` | Live prices | ❌ Not wired |
| `GET /api/stock/{symbol}/sentiment` | Stock detail | ❌ Not wired |
| `GET /api/stock/{symbol}/support-resistance` | Stock detail | ❌ Not wired |
| `GET /api/stock/{symbol}/deep-analysis` | Stock detail | ❌ Not wired |
| `GET /api/nifty` / `POST /api/nifty/analyze` | NIFTY 50 page | ❌ Page missing |
| `GET /api/options/chain/{symbol}` | Options | ❌ Page missing |
| `GET /api/calendar/earnings` | Calendar | ❌ Page missing |
| `GET /api/52week` | 52-Week scanner | ❌ Page missing |
| `GET /api/market/breadth` | Market info | ❌ Page missing |
| `GET /api/reports` | Reports | ❌ Page missing |
| `GET /api/signals/accuracy` | Signal accuracy | ❌ Page missing |
| `GET /api/trade-planner` | Trade planner | ❌ Page missing |
| `GET /api/agents/risk/{symbol}` | Agent risk | ❌ Not wired |
| `GET /api/agents/memory` | Agent memory | ❌ Not wired |
| `GET /api/holdings/recommendations` | Holdings AI recs | ❌ Not wired |
| `DELETE /api/alerts/{id}` | Alert deletion | ❌ Not wired |
| `PUT /api/alerts/{id}` | Alert editing | ❌ Not wired |
| `GET /api/news?symbol=` | News on stock detail | ❌ Not wired |
| `GET /api/websocket/prices` | Live WebSocket | ❌ Not implemented |
| Admin endpoints (`/api/admin/*`) | Admin panel | ❌ Not applicable |

---

## 4. UI/UX GAPS

| Issue | Web | iOS | Severity |
|-------|-----|-----|----------|
| **Tab bar overflow** | Sidebar nav (scalable) | 12 tabs — iOS groups extras into "More" | Medium |
| **Card shadows** | No shadows (flat design) | No shadows ✅ | — |
| **Border radius** | 6px | 6px ✅ | — |
| **Font: JetBrains Mono** | Used for numbers/labels | Used ✅ | — |
| **Font: Inter** | UI text | System font (close) | Low |
| **Lucide icons** | Outline style, 2px | SF Symbols (close but not exact) | Low |
| **toLocaleString('en-IN')** | Used everywhere | `String(format:)` used | Low |
| **Scrollable lists** | Native scrolling | `List` + `scrollContentBackground(.hidden)` ✅ | — |
| **Pull-to-refresh** | Implemented | `.refreshable` ✅ | — |
| **Dark mode** | Always dark | Always dark ✅ | — |
| **AI Chat** | Floating widget | Not present | Medium |
| **Cookie consent** | Banner shown | Not applicable (native) | — |

---

## 5. PERFORMANCE COMPARISON

| Aspect | Web | iOS | Notes |
|--------|-----|-----|-------|
| Initial load | ~2-3s (lazy chunks) | ~1-2s (native) | iOS faster |
| Chart rendering | amCharts 5 (WebGL) | Core Graphics Canvas | Web smoother |
| Live price updates | WebSocket (<100ms) | Polling (N/A) | **Web significantly better** |
| Search | Debounced API | Debounced API | Comparable |
| List scrolling | Virtualized | Native | iOS smoother |
| Data caching | SWR + localStorage | No caching layer | **Web better** |
| Offline support | Service Worker | None | Web better |

---

## 6. AUTH & SECURITY

| Feature | Web | iOS | Status |
|---------|-----|-----|--------|
| HttpOnly cookies | ✅ | ✅ | — |
| Bearer token | ✅ | ✅ | — |
| Auto token refresh | ✅ | ✅ (10min) | — |
| Registration | ✅ | ❌ Button exists but no-op | **Gap** |
| Password reset | ✅ | ❌ Not present | **Gap** |
| Biometric auth | N/A | ❌ Not implemented | Future |
| Keychain token storage | N/A | ❌ In-memory only | **Security gap** |

---

## 7. RECOMMENDATION: IMPLEMENTATION PRIORITY

### Phase 1: Critical Gaps (Highest Impact)
1. **WebSocket Live Prices** — Wire Kite WebSocket or polling for stock detail + watchlist
2. **NIFTY 50 Page** — High-value dedicated index page
3. **Stock Detail Enhancements** — Sentiment, S/R levels, Deep Analysis, News
4. **Paper Trading** — High user engagement feature
5. **Options Chain** — High demand feature

### Phase 2: Important Features
6. **Screener Filter Sidebar** — Full filter panel with save/export
7. **Signal Accuracy Page** — Build trust with users
8. **52-Week High/Low Scanner**
9. **Calendar/Earnings Page**
10. **Reports Page**

### Phase 3: Polish & Depth
11. **Trade Planner**
12. **Additional Market Info**
13. **Agent Risk & Memory Tabs**
14. **AI Chat Widget**
15. **Correlation Matrix in Holdings**
16. **Keychain token storage**

### Phase 4: Nice-to-Have
17. Admin panel (tablet only)
18. Chart 360
19. Profile memory
20. Biometric authentication

---

## 8. SUMMARY METRICS

```
Features Implemented:        ~45%
Features Partially Done:     ~30%
Features Missing:            ~25%

API Coverage:               ~45% (18/40 endpoints)
Page Coverage:              ~48% (12/25 pages)
Real-time Capability:       ~20% (no WebSocket)
```

**Verdict:** The iOS app is a solid MVP covering core functionality (Dashboard, Search, Watchlist, Signals, Holdings, Alerts, Profile). However, it is missing ~13 entire pages and many sub-features within existing pages. The biggest functional gaps are: **no WebSocket live prices**, **no NIFTY 50 page**, **no Paper Trading**, **no Options Chain**, and **limited Stock Detail depth**.
