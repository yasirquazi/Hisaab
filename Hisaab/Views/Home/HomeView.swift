import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]

    @State private var showAddExpense = false
    @State private var showVoiceCapture = false
    @State private var showSettings = false

    private var thisMonthExpenses: [Expense] {
        let calendar = Calendar.current
        return expenses.filter {
            calendar.isDate($0.date, equalTo: .now, toGranularity: .month)
        }
    }

    private var totalThisMonth: Double {
        thisMonthExpenses.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Inline settings button — no large nav title
                    HStack {
                        Spacer()
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape.fill")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.secondary)
                                .font(.body)
                                .frame(width: 36, height: 36)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PressScaleButtonStyle())
                    }
                    .padding(.top, 8)

                    MonthlySummaryCard(totalSpent: totalThisMonth, budget: nil)

                    CategoryBreakdownChart(expenses: thisMonthExpenses)

                    RecentTransactionsList(expenses: Array(expenses.prefix(10)))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 140)
            }
            .overlay(alignment: .bottomTrailing) { addButton }
            .overlay(alignment: .bottom) { micButton }
        }
        .sheet(isPresented: $showAddExpense) { AddExpenseView() }
        .sheet(isPresented: $showVoiceCapture) { VoiceCaptureView() }
        .sheet(isPresented: $showSettings) { CategoryManagementView() }
        .onAppear(perform: seedCategoriesIfNeeded)
    }

    // MARK: - Floating buttons

    private var micButton: some View {
        Button { showVoiceCapture = true } label: {
            Image(systemName: "mic.fill")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color(.label))
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.2), radius: 12, y: 4)
        }
        .buttonStyle(PressScaleButtonStyle())
        .padding(.bottom, 100)
    }

    private var addButton: some View {
        Button { showAddExpense = true } label: {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor)
                .clipShape(Circle())
                .shadow(color: Color.accentColor.opacity(0.35), radius: 12, y: 4)
        }
        .buttonStyle(PressScaleButtonStyle())
        .padding(.trailing, 20)
        .padding(.bottom, 100)
    }

    // MARK: - Category seeding

    private func seedCategoriesIfNeeded() {
        guard categories.isEmpty else { return }
        for (name, emoji, order) in ExpenseCategory.defaults {
            modelContext.insert(ExpenseCategory(name: name, emoji: emoji, sortOrder: order))
        }
    }
}

// Emil's scale(0.97) on press — shared across the module
struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
