import SwiftUI

struct HomeBreakdownBar: View {
    let expenses: [Expense]

    private var totals: [CategoryBreakdownChart.CategoryTotal] {
        var buckets: [String: Double] = [:]
        for e in expenses { buckets[e.category, default: 0] += e.amount }
        return buckets
            .map { name, amount in
                let emoji = ExpenseCategory.defaults.first { $0.name == name }?.emoji ?? ""
                return CategoryBreakdownChart.CategoryTotal(
                    name: name, emoji: emoji, total: amount,
                    color: CategoryBreakdownChart.color(for: name)
                )
            }
            .sorted { $0.total > $1.total }
    }

    private var grandTotal: Double { totals.reduce(0) { $0 + $1.total } }

    private var legendItems: [CategoryBreakdownChart.CategoryTotal] {
        let maxItems = 3
        guard totals.count > maxItems else { return totals }
        let visible = Array(totals.prefix(maxItems - 1))
        let otherTotal = totals.dropFirst(maxItems - 1).reduce(0) { $0 + $1.total }
        let other = CategoryBreakdownChart.CategoryTotal(
            name: "Other", emoji: "", total: otherTotal,
            color: Color(red: 220/255, green: 216/255, blue: 211/255)
        )
        return visible + [other]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geo in
                HStack(spacing: 2) {
                    ForEach(totals) { item in
                        Rectangle()
                            .fill(item.color)
                            .frame(width: max(4, geo.size.width * CGFloat(item.total / grandTotal)))
                    }
                }
            }
            .frame(height: 12)

            HStack(spacing: 16) {
                ForEach(legendItems) { item in
                    HStack(spacing: 4) {
                        Circle().fill(item.color).frame(width: 8, height: 8)
                        Text(item.name)
                            .font(HisaabTheme.mono(12, weight: .light))
                            .foregroundStyle(Color.hSecondary)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: totals.map(\.total))
    }
}
