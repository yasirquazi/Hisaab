# Hisaab — Features & Functionality Summary

> Personal finance iOS app. SwiftUI + SwiftData. iOS 17+, targeting iPhone.  
> Currency: Indian Rupee (₹). As of June 2026.

---

## What the App Does

Hisaab is a personal expense tracker that lets users log, categorise, and review their spending. It supports three input methods — manual entry, voice capture, and automatic import from Gmail bank transaction emails — and provides a home dashboard with spend breakdowns and a detailed spendings overview page.

---

## Screens & Features

### 1. Home Screen
- **Total Spending** — displays the all-time sum of all expenses (large hero number, animated on change)
- **Category Breakdown Bar** — proportional horizontal bar showing spending split across all categories with a colour-coded legend
- **Income & Savings cells** — tap-to-edit cells for monthly income and monthly savings targets; values stored as a singleton financial profile
- **Recent Transactions** — last 15 expenses grouped by day (Today / Yesterday / date), each showing category, note, and amount; tapping any row opens the edit sheet
- **Settings icon** (top-left) — opens the Settings bottom sheet; shows an orange dot badge when Gmail review queue has pending items
- **Mic FAB** (bottom-right) — opens the voice capture sheet

### 2. Spending Overview Screen
- **Period filter** — This Month / Last Month / 3 Months / All Time
- **Category filter chips** — filter list to one or more categories
- **Source filter** — Manual / Voice / Gmail
- **Sort** — Newest / Oldest / Highest / Lowest
- Full scrollable list of matching expenses

### 3. Add / Edit Expense Sheet
- Opened as **full-screen cover** from the `+` tab button (create mode)
- Opened as a **bottom sheet** from tapping any transaction row (edit mode)
- Fields: amount (₹, decimal pad), category chips (scrollable), optional note, collapsible date picker
- **Delete** button in edit mode only (destructive, confirmation implied by button styling)
- Save: inserts new expense (create) or mutates + saves (edit)

### 4. Voice Capture Sheet
- Mic FAB → speech recognition sheet
- Transcribes speech in real time
- `VoiceParser` extracts: amount, category hint, and note from natural language (e.g. "spent 500 on food for lunch")
- Creates a manual expense on confirmation

### 5. Settings Bottom Sheet
Accessed via the settings icon on the Home screen. Compact bottom sheet that stacks child sheets on top.

**Gmail Import section:**
- **Connect Gmail** — shows green "Connected" badge when signed in; opens the Gmail auth/sync screen
- **Review Queue** — shows an orange count badge with pending items; opens the review queue at full height
- **Sync Mail** — triggers an immediate Gmail sync; label changes to "Syncing…" while in progress

**Other section:**
- **Manage Categories** — opens the category management screen at full height
- **Export Data** — generates a CSV of all expenses and opens the iOS share sheet (Files, email, Numbers, Excel, etc.)
- **Reset App** — confirmation alert; deletes all expenses, categories, and settings; re-seeds default categories; signs out of Gmail
- **About** — shows app version (1.0.0)

### 6. Gmail Import Flow
- **Auth** — Google Sign-In SDK, `gmail.readonly` scope, tokens stored in Keychain
- **Sync** — queries Gmail REST API for bank/transaction emails (30-day window); parses with `EmailParser`; deduplicates by Gmail message ID
- **EmailParser** — regex-based extraction of amount, merchant name, and bank name from SMS-forwarded and bank email bodies
- **Auto-categorisation** — `MerchantCategoryRule` maps known merchants to categories; auto-applied on import
- **Background sync** — `BGTaskScheduler` task registered for hourly background refresh
- **Review Queue** — list of unreviewed Gmail-imported transactions; each row shows amount, merchant, date, and current category; actions per row: Edit / Approve / Delete; approving a row saves a `MerchantCategoryRule` for that merchant

### 7. Category Management Sheet
- List of all expense categories (emoji + name)
- Add new category (emoji + name) via a nested sheet
- Delete any category
- 9 default categories seeded on first launch: Food, Transport, Groceries, Family Transfer, Entertainment, Health, Shopping, Utilities, Other

### 8. Bottom Navigation Bar
- **Home** tab — `RiHome2Line` / `RiHome2Fill` icons
- **+** centre button — orange accent, opens Add Expense full-screen cover
- **Spending Overview** tab — `RiBarChart2Line` / `RiBarChart2Fill` icons

---

## Data Models

| Model | Key Fields |
|---|---|
| `Expense` | amount, category (string), note, date, source (manual/voice/gmail), merchant, isReviewed |
| `ExpenseCategory` | name, emoji, monthlyBudget (optional), sortOrder |
| `FinancialProfile` | monthlyIncome, monthlySavings, familyTransferAmount |
| `MerchantCategoryRule` | merchant (lowercase key), category, usageCount, lastUsed |
| `GmailSyncState` | sync metadata |

---

## Design System

- **Font** — Chivo Mono (custom, bundled) — monospaced throughout
- **Palette** — warm cream background (`#F7F3ED`), dark brown primary (`#352918`), grey-brown secondary (`#837A6D`), orange-red accent (`#FE5000`), border (`#D0CBC2`)
- **Icons** — Remix Icons (PNG/SVG assets, template-rendered for tinting)
- **Interactions** — `PressScaleButtonStyle` (0.94× scale on press, spring animation) used on all buttons
- **Layout tokens** — `pagePadding: 20`, `sectionGap: 32`, `itemGap: 16`, `rowPaddingV: 14`
- **Modals** — All modals are bottom sheets (`.sheet`) with appropriate `presentationDetents`; Settings uses `.height(640)`, sub-sheets use `.large`

---

## Current Limitations / Notable Gaps

- No budgeting alerts — `monthlyBudget` exists on categories but is never surfaced in UI
- No recurring expenses support
- No multi-currency support (INR only)
- Home screen shows all-time total, not a filtered period total
- No charts or trend graphs beyond the single breakdown bar on Home
- No widget / Lock Screen support
- No iCloud sync — data is local SwiftData only
- No split expenses or shared bills
- No scheduled / future expenses
- Voice capture is not deeply tested
- No search across expenses
- No tags / labels beyond categories
- No photo / receipt attachment
