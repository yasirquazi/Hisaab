import SwiftUI

struct RecentTransactionsList: View {
    let expenses: [Expense]

    private var grouped: [(label: String, items: [Expense])] {
        let calendar = Calendar.current
        var buckets: [String: [Expense]] = [:]
        var order: [String] = []

        for expense in expenses.prefix(10) {
            let label = dayLabel(for: expense.date, calendar: calendar)
            if buckets[label] == nil {
                order.append(label)
            }
            buckets[label, default: []].append(expense)
        }

        return order.map { (label: $0, items: buckets[$0]!) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent")
                .font(.headline)

            if expenses.isEmpty {
                Text("No expenses yet. Tap + to add one.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                ForEach(Array(grouped.enumerated()), id: \.element.label) { index, group in
                    Section {
                        ForEach(group.items) { expense in
                            ExpenseRow(expense: expense)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    } header: {
                        Text(group.label)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .padding(.top, index == 0 ? 0 : 8)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func dayLabel(for date: Date, calendar: Calendar) -> String {
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.weekday(.wide).day().month())
    }
}
