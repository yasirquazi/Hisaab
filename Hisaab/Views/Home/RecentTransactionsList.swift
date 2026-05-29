import SwiftUI

struct RecentTransactionsList: View {
    let expenses: [Expense]

    private var grouped: [(label: String, items: [Expense])] {
        let calendar = Calendar.current
        var buckets: [String: [Expense]] = [:]
        var order: [String] = []
        for expense in expenses {
            let label = dayLabel(for: expense.date, calendar: calendar)
            if buckets[label] == nil { order.append(label) }
            buckets[label, default: []].append(expense)
        }
        return order.map { (label: $0, items: buckets[$0]!) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(grouped, id: \.label) { group in
                VStack(alignment: .leading, spacing: 12) {
                    Text(group.label)
                        .font(HisaabTheme.mono(12, weight: .medium))
                        .foregroundStyle(Color.hSecondary)
                        .tracking(0.8)
                        .textCase(.uppercase)

                    VStack(spacing: 16) {
                        ForEach(group.items) { expense in
                            ExpenseRow(expense: expense)
                        }
                    }
                }
            }
        }
    }

    private func dayLabel(for date: Date, calendar: Calendar) -> String {
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.weekday(.wide).day().month())
    }
}
