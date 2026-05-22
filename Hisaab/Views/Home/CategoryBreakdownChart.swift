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
        let other = CategoryTotal(name: "Other", emoji: "💸", total: otherTotal, color: Color(.systemGray3))
        return visible + [other]
    }

    private var grandTotal: Double {
        totals.reduce(0) { $0 + $1.total }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("This Month")
                .font(.headline)

            if totals.isEmpty {
                Text("No expenses yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                segmentedBar
                legendRow
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // Single bar where each category gets a proportional colored segment
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
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }

    // One-line legend: up to 4 categories, overflow collapses to "Other"
    private var legendRow: some View {
        HStack(spacing: 14) {
            ForEach(legendItems) { item in
                HStack(spacing: 5) {
                    Circle()
                        .fill(item.color)
                        .frame(width: 8, height: 8)
                    Text("\(item.emoji) \(item.name)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .fixedSize()
                }
            }
            Spacer(minLength: 0)
        }
    }

    // Stable color mapping used consistently in both the home widget and the Spendings tab
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
