import SwiftUI
import SwiftData

struct ReviewQueueView: View {
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    private var pending: [Expense] {
        allExpenses.filter { $0.source == .gmail && !$0.isReviewed }
    }

    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if pending.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Review Queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
                if !pending.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Approve All") { approveAll() }
                    }
                }
            }
        }
    }

    private var list: some View {
        List {
            Section {
                Text("\(pending.count) transaction\(pending.count == 1 ? "" : "s") imported from Gmail — review and confirm.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ForEach(pending) { expense in
                ReviewRow(expense: expense, categories: categories)
            }
            .onDelete(perform: deleteItems)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.green)
            Text("All caught up!")
                .font(.headline)
            Text("No pending Gmail transactions to review.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func approveAll() {
        for expense in pending { expense.isReviewed = true }
        try? modelContext.save()
    }

    private func deleteItems(at offsets: IndexSet) {
        for i in offsets { modelContext.delete(pending[i]) }
        try? modelContext.save()
    }
}

private struct ReviewRow: View {
    @Bindable var expense: Expense
    let categories: [ExpenseCategory]
    @State private var showEdit = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(expense.amount, format: .currency(code: "INR").presentation(.narrow))
                        .font(.headline)
                    if let merchant = expense.merchant {
                        Text(merchant)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Text(expense.date.formatted(.dateTime.day().month().year()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                categoryBadge
            }

            HStack(spacing: 10) {
                Button("Edit") { showEdit = true }
                    .font(.caption).fontWeight(.medium)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color(.secondarySystemFill))
                    .clipShape(Capsule())

                Button("Approve") {
                    saveRule(merchant: expense.merchant, category: expense.category)
                    expense.isReviewed = true
                    try? modelContext.save()
                }
                .font(.caption).fontWeight(.semibold)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(Capsule())

                Button(role: .destructive) {
                    modelContext.delete(expense)
                    try? modelContext.save()
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Color.red.opacity(0.1))
                .foregroundStyle(.red)
                .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showEdit) {
            EditImportedExpenseView(expense: expense, categories: categories)
        }
    }

    private var categoryBadge: some View {
        let emoji = categories.first { $0.name == expense.category }?.emoji ?? "💸"
        return Text("\(emoji) \(expense.category)")
            .font(.caption).fontWeight(.medium)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(Color(.tertiarySystemFill))
            .clipShape(Capsule())
    }

    private func saveRule(merchant: String?, category: String) {
        guard let merchant, !merchant.isEmpty else { return }
        let key = merchant.lowercased()
        let descriptor = FetchDescriptor<MerchantCategoryRule>(
            predicate: #Predicate { $0.merchant == key }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            existing.category = category
            existing.usageCount += 1
            existing.lastUsed = .now
        } else {
            modelContext.insert(MerchantCategoryRule(merchant: key, category: category))
        }
    }
}

private struct EditImportedExpenseView: View {
    @Bindable var expense: Expense
    let categories: [ExpenseCategory]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var amountText: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                }
                Section("Category") {
                    Picker("Category", selection: $expense.category) {
                        ForEach(categories) { cat in
                            Text("\(cat.emoji) \(cat.name)").tag(cat.name)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                Section("Note") {
                    TextField("Note (optional)", text: Binding(
                        get: { expense.note ?? "" },
                        set: { expense.note = $0.isEmpty ? nil : $0 }
                    ))
                }
            }
            .navigationTitle("Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let value = Double(amountText), value > 0 { expense.amount = value }
                        saveRule(merchant: expense.merchant, category: expense.category)
                        expense.isReviewed = true
                        try? modelContext.save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear { amountText = String(expense.amount) }
        }
    }

    private func saveRule(merchant: String?, category: String) {
        guard let merchant, !merchant.isEmpty else { return }
        let key = merchant.lowercased()
        let descriptor = FetchDescriptor<MerchantCategoryRule>(
            predicate: #Predicate { $0.merchant == key }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            existing.category = category
            existing.usageCount += 1
            existing.lastUsed = .now
        } else {
            modelContext.insert(MerchantCategoryRule(merchant: key, category: category))
        }
    }
}
