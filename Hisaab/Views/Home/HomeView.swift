import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]
    @Query private var profiles: [FinancialProfile]
    @Environment(GmailService.self) private var gmailService

    @State private var showSettings = false
    @State private var showVoiceCapture = false
    @State private var showIncomeSheet = false
    @State private var showSavingsSheet = false
    @State private var editingExpense: Expense? = nil

    private var profile: FinancialProfile? { profiles.first }

    private var totalSpending: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    private var pendingReview: [Expense] {
        expenses.filter { $0.source == .gmail && !$0.isReviewed }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.hBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    metricsSection
                    recentSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }

            micFAB
        }
        .sheet(isPresented: $showVoiceCapture) { VoiceCaptureView() }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(item: $editingExpense) { expense in
            AddExpenseView(editingExpense: expense)
        }
        .sheet(isPresented: $showIncomeSheet) {
            MetricInputSheet(title: "Monthly Income", current: profile?.monthlyIncome ?? 0) { amount in
                upsertProfile { $0.monthlyIncome = amount }
            }
        }
        .sheet(isPresented: $showSavingsSheet) {
            MetricInputSheet(title: "Monthly Savings", current: profile?.monthlySavings ?? 0) { amount in
                upsertProfile { $0.monthlySavings = amount }
            }
        }
        .onAppear(perform: seedCategoriesIfNeeded)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button { showSettings = true } label: {
                ZStack(alignment: .topTrailing) {
                    Image("ri-settings-4-line")
                        .renderingMode(.template)
                        .foregroundStyle(Color.hPrimary)
                        .frame(width: 24, height: 24)
                    if pendingReview.count > 0 {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                            .offset(x: 2, y: -2)
                    }
                }
            }
            .buttonStyle(PressScaleButtonStyle())

            Spacer()

            Text("Home")
                .font(HisaabTheme.mono(16, weight: .medium))
                .foregroundStyle(Color.hPrimary)

            Spacer()

            Color.clear.frame(width: 24, height: 24)
        }
        .padding(.top, 8)
        .padding(.bottom, 24)
    }

    // MARK: - Metrics

    private var metricsSection: some View {
        VStack(alignment: .center, spacing: 16) {
            VStack(spacing: 6) {
                if expenses.isEmpty {
                    Text("—")
                        .font(HisaabTheme.mono(40, weight: .bold))
                        .foregroundStyle(Color.hSecondary)
                } else {
                    Text(totalSpending, format: .currency(code: "INR").presentation(.narrow))
                        .font(HisaabTheme.mono(40, weight: .bold))
                        .foregroundStyle(Color.hPrimary)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: totalSpending)
                }
                Text("Total Spending")
                    .font(HisaabTheme.mono(16, weight: .medium))
                    .foregroundStyle(expenses.isEmpty ? Color.hSecondary : Color.hPrimary)
            }
            .frame(maxWidth: .infinity)

            if !expenses.isEmpty {
                HomeBreakdownBar(expenses: expenses)
            }

            incomeAndSavings
        }
        .padding(.bottom, 36)
    }

    private var incomeAndSavings: some View {
        HStack(spacing: 0) {
            Button { showIncomeSheet = true } label: {
                metricCell(label: "Income", value: profile?.monthlyIncome ?? 0, hasDivider: true)
            }
            .buttonStyle(PressScaleButtonStyle())

            Button { showSavingsSheet = true } label: {
                metricCell(label: "Savings", value: profile?.monthlySavings ?? 0, hasDivider: false)
            }
            .buttonStyle(PressScaleButtonStyle())
        }
        .overlay(RoundedRectangle(cornerRadius: 0).stroke(Color.hBorder, lineWidth: 1))
    }

    private func metricCell(label: String, value: Double, hasDivider: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(HisaabTheme.mono(14, weight: .medium))
                .foregroundStyle(Color.hPrimary)

            HStack(spacing: 0) {
                Text(value > 0
                     ? value.formatted(.currency(code: "INR").presentation(.narrow))
                     : "—")
                    .font(HisaabTheme.mono(14, weight: .bold))
                    .foregroundStyle(Color.hPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer(minLength: 8)

                Image("ri-arrow-right-s-line")
                    .renderingMode(.template)
                    .foregroundStyle(Color.hSecondary)
                    .frame(width: 16, height: 16)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .trailing) {
            if hasDivider {
                Rectangle().fill(Color.hBorder).frame(width: 1)
            }
        }
    }

    // MARK: - Recent Transactions

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !expenses.isEmpty {
                Text("Recent Transactions")
                    .font(HisaabTheme.mono(16, weight: .medium))
                    .foregroundStyle(Color.hPrimary)
                RecentTransactionsList(
                    expenses: Array(expenses.prefix(15)),
                    onTap: { editingExpense = $0 }
                )
            } else {
                emptyState
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 36))
                .foregroundStyle(Color.hSecondary)
                .symbolRenderingMode(.hierarchical)
                .padding(.bottom, 4)
            Text("No expenses yet")
                .font(HisaabTheme.mono(16, weight: .medium))
                .foregroundStyle(Color.hPrimary)
            Text("Tap + to log your first expense")
                .font(HisaabTheme.mono(12))
                .foregroundStyle(Color.hSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    // MARK: - Mic FAB

    private var micFAB: some View {
        Button { showVoiceCapture = true } label: {
            Image("ri-mic-line")
                .renderingMode(.template)
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .padding(16)
                .background(Color.hPrimary)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.17), radius: 11, x: 0, y: 6)
        }
        .buttonStyle(PressScaleButtonStyle())
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }

    // MARK: - Data

    private func upsertProfile(_ update: (FinancialProfile) -> Void) {
        if let p = profile {
            update(p)
            p.lastUpdated = .now
        } else {
            let p = FinancialProfile(monthlyIncome: 0, monthlySavings: 0)
            update(p)
            modelContext.insert(p)
        }
        try? modelContext.save()
    }

    private func seedCategoriesIfNeeded() {
        guard categories.isEmpty else { return }
        for (name, emoji, order) in ExpenseCategory.defaults {
            modelContext.insert(ExpenseCategory(name: name, emoji: emoji, sortOrder: order))
        }
    }
}

