import SwiftUI

struct CategoryBreakdownChart: View {
    let expenses: [Expense]

    private let maxLegendItems = 4

    struct CategoryTotal: Identifiable {
        let id = UUID()
        let name: String
        let emoji: String
        let total: Double
        let color: Color
    }

    var totals: [CategoryTotal] {
        var buckets: [String: Double] = [:]
        for e in expenses { buckets[e.category, default: 0] += e.amount }
        return buckets
            .map { name, amount in
                let emoji = ExpenseCategory.defaults.first { $0.name == name }?.emoji ?? "💸"
                return CategoryTotal(name: name, emoji: emoji, total: amount, color: Self.color(for: name))
            }
            .sorted { $0.total > $1.total }
    }

    private var legendItems: [CategoryTotal] {
        guard totals.count > maxLegendItems else { return totals }
        let visible = Array(totals.prefix(maxLegendItems - 1))
        let otherTotal = totals.dropFirst(maxLegendItems - 1).reduce(0) { $0 + $1.total }
        let other = CategoryTotal(name: "Other", emoji: "💸", total: otherTotal, color: Color.hSecondary)
        return visible + [other]
    }

    private var grandTotal: Double { totals.reduce(0) { $0 + $1.total } }

    var body: some View {
        VStack(alignment: .leading, spacing: HisaabTheme.Layout.itemGap) {
            Text("This Month")
                .font(HisaabTheme.mono(HisaabTheme.FontSize.headline, weight: .medium))
                .foregroundStyle(Color.hPrimary)

            if totals.isEmpty {
                Text("No expenses yet")
                    .font(HisaabTheme.mono(HisaabTheme.FontSize.body))
                    .foregroundStyle(Color.hSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                segmentedBar
                legendRow
            }
        }
        .padding(HisaabTheme.Layout.cardPadding)
        .hOutline()
    }

    private var segmentedBar: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach(totals) { item in
                    Rectangle()
                        .fill(item.color)
                        .frame(width: max(4, geo.size.width * CGFloat(item.total / grandTotal)))
                }
            }
        }
        .frame(height: 14)
    }

    private var legendRow: some View {
        HStack(spacing: 14) {
            ForEach(legendItems) { item in
                HStack(spacing: 5) {
                    Rectangle()
                        .fill(item.color)
                        .frame(width: 8, height: 8)
                    Text("\(item.emoji) \(item.name)")
                        .font(HisaabTheme.mono(HisaabTheme.FontSize.caption))
                        .foregroundStyle(Color.hSecondary)
                        .lineLimit(1)
                        .fixedSize()
                }
            }
            Spacer(minLength: 0)
        }
    }

    static func color(for name: String) -> Color {
        switch name {
        case "Food":            return .orange
        case "Transport":       return .blue
        case "Groceries":       return Color(.systemGreen)
        case "Family Transfer": return .indigo
        case "Entertainment":   return .purple
        case "Health":          return .red
        case "Shopping":        return .pink
        case "Utilities":       return Color(.systemTeal)
        default:
            let palette: [Color] = [.cyan, .mint, .yellow, .brown]
            return palette[abs(name.hashValue) % palette.count]
        }
    }
}
