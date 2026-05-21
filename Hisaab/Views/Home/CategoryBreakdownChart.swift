import SwiftUI
import Charts

struct CategoryBreakdownChart: View {
    let expenses: [Expense]

    private struct CategoryTotal: Identifiable {
        let id = UUID()
        let name: String
        let emoji: String
        let total: Double
    }

    private var topCategories: [CategoryTotal] {
        var totals: [String: Double] = [:]
        for expense in expenses {
            totals[expense.category, default: 0] += expense.amount
        }
        return totals
            .map { key, value -> CategoryTotal in
                let emoji = ExpenseCategory.defaults.first { $0.name == key }?.emoji ?? "💸"
                return CategoryTotal(name: key, emoji: emoji, total: value)
            }
            .sorted { $0.total > $1.total }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("This Month")
                .font(.headline)

            if topCategories.isEmpty {
                Text("No expenses yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                Chart(topCategories) { item in
                    BarMark(
                        x: .value("Amount", item.total),
                        y: .value("Category", "\(item.emoji) \(item.name)")
                    )
                    .foregroundStyle(Color.accentColor.gradient)
                    .cornerRadius(6)
                    .annotation(position: .trailing) {
                        Text(item.total, format: .currency(code: "INR").presentation(.narrow))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartXAxis(.hidden)
                .frame(height: CGFloat(topCategories.count) * 44)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: topCategories.map(\.total))
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
