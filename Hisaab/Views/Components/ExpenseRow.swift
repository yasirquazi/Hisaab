import SwiftUI

struct ExpenseRow: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 16) {
            categoryIcon

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.category)
                    .font(HisaabTheme.mono(14, weight: .medium))
                    .foregroundStyle(Color.hPrimary)

                if let note = expense.note, !note.isEmpty {
                    Text(note)
                        .font(HisaabTheme.mono(12, weight: .light))
                        .foregroundStyle(Color.hSecondary)
                        .lineLimit(1)
                } else if let merchant = expense.merchant, !merchant.isEmpty {
                    Text(merchant)
                        .font(HisaabTheme.mono(12, weight: .light))
                        .foregroundStyle(Color.hSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(expense.amount, format: .currency(code: "INR").presentation(.narrow))
                .font(HisaabTheme.mono(16, weight: .bold))
                .foregroundStyle(Color.hPrimary)
        }
    }

    private var categoryIcon: some View {
        let color = CategoryBreakdownChart.color(for: expense.category)
        let icon = HisaabTheme.categoryIcon(for: expense.category)
        return ZStack {
            color.opacity(0.1)
                .frame(width: 40, height: 40)
            Image(icon)
                .renderingMode(.template)
                .foregroundStyle(color)
                .frame(width: 20, height: 20)
        }
    }
}
