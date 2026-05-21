import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]

    @State private var showAddExpense = false
    @State private var showSettings = false

    // MARK: - Computed properties

    private var thisMonthExpenses: [Expense] {
        let calendar = Calendar.current
        return expenses.filter {
            calendar.isDate($0.date, equalTo: .now, toGranularity: .month)
        }
    }

    private var totalThisMonth: Double {
        thisMonthExpenses.reduce(0) { $0 + $1.amount }
    }

    private var familyTransferThisMonth: Double {
        thisMonthExpenses
            .filter { $0.category == "Family Transfer" }
            .reduce(0) { $0 + $1.amount }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    MonthlySummaryCard(
                        totalSpent: totalThisMonth,
                        familyTransferTotal: familyTransferThisMonth,
                        budget: nil
                    )

                    CategoryBreakdownChart(expenses: thisMonthExpenses)

                    RecentTransactionsList(expenses: Array(expenses.prefix(10)))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Hisaab")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                addButton
            }
            .sheet(isPresented: $showAddExpense) {
                AddExpenseView()
            }
            .sheet(isPresented: $showSettings) {
                CategoryManagementView()
            }
        }
        .onAppear(perform: seedCategoriesIfNeeded)
    }

    // MARK: - Add Button (Emil: scale on press, spring out)

    private var addButton: some View {
        Button {
            showAddExpense = true
        } label: {
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
        .padding(.bottom, 32)
    }

    // MARK: - Category seeding

    private func seedCategoriesIfNeeded() {
        guard categories.isEmpty else { return }
        for (name, emoji, order) in ExpenseCategory.defaults {
            modelContext.insert(ExpenseCategory(name: name, emoji: emoji, sortOrder: order))
        }
    }
}

// Applies Emil's scale(0.97) on press — gives instant, physical feedback
struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
