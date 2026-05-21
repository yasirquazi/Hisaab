import SwiftUI

struct ExpenseRow: View {
    let expense: Expense

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Text(categoryEmoji)
                .font(.title2)
                .frame(width: 42, height: 42)
                .background(Color(.secondarySystemBackground))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.category)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                if let note = expense.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(expense.amount, format: .currency(code: "INR").presentation(.narrow))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                if expense.source == .gmail {
                    Label("Auto", systemImage: "envelope.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // Resolve the emoji from the shared category store via name match
    // Falls back to a default if no Category object is found
    private var categoryEmoji: String {
        ExpenseCategory.defaults.first { $0.name == expense.category }?.emoji ?? "💸"
    }
}
