# Hisaab — Project Summary

**As of 2 June 2026**  
Personal finance iOS app. Built with SwiftUI + SwiftData. Target: iOS 17+, tested on iPhone 16e (iOS 26.2 simulator).

---

## Architecture at a Glance

```
Hisaab/
├── App/
│   └── HisaabApp.swift          — @main, GoogleSignIn config, BGTaskScheduler
├── Models/
│   ├── Expense.swift            — Core transaction model
│   ├── Category.swift           — ExpenseCategory (name, emoji, monthlyBudget, sortOrder)
│   ├── FinancialProfile.swift   — monthlyIncome, monthlySavings, familyTransferAmount
│   ├── GmailSyncState.swift     — Sync metadata (unused beyond state tracking)
│   └── MerchantCategoryRule.swift — Auto-categorisation rules (merchant → category)
├── Services/
│   ├── GmailService.swift       — @Observable OAuth + Gmail REST sync
│   ├── EmailParser.swift        — Extracts amount/merchant from bank email bodies
│   └── VoiceParser.swift        — Parses natural-language voice input into Expense fields
└── Views/
    ├── Components/
    │   ├── HisaabTheme.swift     — All design tokens, shared components
    │   ├── ExpenseRow.swift      — Single transaction row widget
    │   ├── MainTabView.swift     — Root tab shell (Home | + | Spendings)
    │   └── MetricInputSheet.swift— Bottom sheet for setting income/savings
    ├── Home/
    │   ├── HomeView.swift        — Main dashboard
    │   ├── RecentTransactionsList.swift
    │   ├── HomeBreakdownBar.swift
    │   ├── CategoryBreakdownChart.swift
    │   └── MonthlySummaryCard.swift
    ├── AddExpense/
    │   ├── AddExpenseView.swift  — Create OR edit expense (fullScreenCover)
    │   └── VoiceCaptureView.swift— Mic FAB → voice → parsed expense
    ├── Gmail/
    │   ├── GmailSyncView.swift   — Connect/sync Gmail UI
    │   └── ReviewQueueView.swift — Review imported transactions
    └── Settings/
        ├── SettingsView.swift
        └── CategoryManagementView.swift
```

---

## Data Models

### Expense
```swift
@Model final class Expense {
    var id: UUID
    var amount: Double
    var category: String          // matches ExpenseCategory.name
    var note: String?
    var date: Date
    var source: ExpenseSource     // .manual | .voice | .gmail
    var gmailMessageId: String?   // dedup key
    var merchant: String?         // from email parser
    var isReviewed: Bool          // gmail imports start false
}
```

### ExpenseCategory
```swift
@Model final class ExpenseCategory {
    var name: String; var emoji: String
    var monthlyBudget: Double?; var sortOrder: Int
}
// Defaults: Food, Transport, Groceries, Family Transfer,
//           Entertainment, Health, Shopping, Utilities, Other
```

### MerchantCategoryRule
Stores `merchant (lowercase) → category` rules built from approved Gmail imports.  
`usageCount` + `lastUsed` tracked for future ML/priority ranking.

### FinancialProfile
Single-row singleton: `monthlyIncome`, `monthlySavings`, `familyTransferAmount`.

---

## Design System — HisaabTheme

**Font:** Chivo Mono (custom, bundled)  
**Colour palette (light only):**
| Token | Value |
|-------|-------|
| `hBackground` | #F7F3ED (warm cream) |
| `hPrimary` | #352918 (dark brown) |
| `hSecondary` | #837A6D (mid grey-brown) |
| `hBorder` | #D0CBC2 |
| `hAccent` | #FE5000 (orange-red) |

**Layout tokens:** `pagePadding=20`, `sectionGap=32`, `itemGap=16`, `rowPaddingV=14`, `headerTopPad=16`

**Shared components:** `HisaabHeader`, `HisaabChip`, `HisaabPrimaryButton`, `PressScaleButtonStyle`

**Remix Icon images** used throughout (rendered as `.template` for tinting).

---

## Key Features Implemented

### Home Screen (`HomeView`)
- Total spending (sum of ALL expenses — not month-filtered)
- `HomeBreakdownBar`: proportional category bar across all expenses
- Income / Savings quick-edit cells (tap → `MetricInputSheet`)
- Recent Transactions list (last 15, grouped by day, tappable to edit)
- Empty state: tray icon + "No expenses yet. Tap + to log your first expense."
- Settings gear with orange dot badge when Gmail review queue is non-empty
- Mic FAB (bottom-right) → voice capture sheet

### Add / Edit Expense (`AddExpenseView`)
- Opened as `.fullScreenCover` from the `+` tab button (create mode)
- Opened as `.sheet` from tapping any transaction row in HomeView (edit mode)
- `editingExpense: Expense? = nil` — `nil` = create, non-nil = edit
- Fields: amount (₹, decimal pad), category chips, note, date (collapsible date picker)
- **Delete Expense** button appears in edit mode only (red outline, destructive)
- Save: inserts new Expense (create) or mutates existing + `modelContext.save()` (edit)

### Gmail Import
- **Auth:** Google Sign-In SDK, `gmail.readonly` scope, tokens stored via GIDSignIn SDK (Keychain-backed), `REVERSED_CLIENT_ID` URL scheme for OAuth callback
- **Sync:** queries Gmail REST API for bank/transaction emails (30-day window), parses via `EmailParser`, deduplicates by `gmailMessageId`
- **`EmailParser`:** regex-extracts amount, merchant, bank name from SMS-forwarded and bank email bodies
- **`MerchantCategoryRule`:** auto-applies known merchant→category on import; user can override in review
- **Review Queue:** approve/edit/delete each import; approving saves a `MerchantCategoryRule`
- Background sync registered via `BGTaskScheduler` (`com.hisaab.gmailsync`, hourly interval)

### Voice Capture (`VoiceCaptureView` + `VoiceParser`)
- Mic FAB → speech recognition → `VoiceParser` extracts amount, category, note
- Creates manual `Expense` on confirmation

### Spendings Tab (`SpendingsView`)
- Period filter: This Month / Last Month / 3 Months / All Time
- Category filter chips
- Source filter (.manual / .voice / .gmail)
- Sort: Newest / Oldest / Highest / Lowest

### Settings
- Gmail connect/disconnect, sync now, last sync time
- Review queue shortcut with pending count badge
- Category management (add name+emoji, delete, reorder by sortOrder)
- App version

---

## iOS 26 Modal Safe-Area Fix

**Problem:** iOS 26 injects ~236pt of `additionalSafeAreaInsets.top` into all modal presentations (`.sheet` and `.fullScreenCover`), pushing content ~290pt down. SwiftUI's `ignoresSafeArea` cannot override this.

**Fix (in `HisaabTheme.swift`):** `ModalSafeAreaFixer` — a `UIViewControllerRepresentable` that accesses `parent` (the direct `UIHostingController`) and zeroes `parent.additionalSafeAreaInsets.top` on each `viewDidLayoutSubviews`. Applied as `.background(ModalSafeAreaFixer())` on every modal `ZStack`.

```swift
struct ModalSafeAreaFixer: UIViewControllerRepresentable { ... }
// Applied to: SettingsView, AddExpenseView, ReviewQueueView,
//             EditImportedExpenseView, CategoryManagementView, GmailSyncView
```

**Status:** Implemented, build succeeds. Real-device/simulator visual confirmation still needed after session restart.

---

## Known Issues / Open Items

1. **iOS 26 blank space** — `ModalSafeAreaFixer` (UIViewControllerRepresentable) is implemented but not yet visually confirmed fixed. This is the top priority on restart.

2. **Spendings tab** — full implementation exists but hasn't been reviewed/tested this session.

3. **Voice capture** — implemented but not deeply tested.

4. **No month label on Home total** — "Total Spending" now sums all-time (changed from this-month to fix ₹0.00 bug when month has no new entries). Consider adding "All Time" sub-label or date range.

5. **Phase 2 (planned):** Enhanced voice capture, budget alerts, widgets.

---

## Simulator Target

- Device: iPhone 16e
- UDID: `F8A37578-DA4D-40CB-A66E-0F0A6D9CDDA2`
- OS: iOS 26.2
- Bundle ID: `com.hisaab.app`
- Scheme: `Hisaab`

**Build command:**
```bash
xcodebuild -scheme Hisaab \
  -destination 'id=F8A37578-DA4D-40CB-A66E-0F0A6D9CDDA2' \
  -configuration Debug build
```

---

## Security Notes

- OAuth tokens managed by GIDSignIn SDK (Keychain-backed) — never UserDefaults
- Gmail scope is read-only (`gmail.readonly`)
- No email content is sent to external services
- `REVERSED_CLIENT_ID` URL scheme registered in Info.plist for OAuth callback
