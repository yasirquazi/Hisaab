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
        ZStack(alignment: .top) {
            Color.hBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                HisaabHeader(
                    title: "Review Queue",
                    leftAction: pending.isEmpty ? nil : AnyView(
                        Button("Approve All") { approveAll() }
                            .font(HisaabTheme.mono(HisaabTheme.FontSize.body))
                            .foregroundStyle(Color.hPrimary)
                    ),
                    rightAction: AnyView(
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.hPrimary)
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(PressScaleButtonStyle())
                    )
                )
                .padding(.horizontal, HisaabTheme.Layout.pagePadding)

                if pending.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(pending.count) transaction\(pending.count == 1 ? "" : "s") imported from Gmail")
                                .font(HisaabTheme.mono(HisaabTheme.FontSize.small))
                                .foregroundStyle(Color.hSecondary)
                                .padding(.vertical, HisaabTheme.Layout.rowPaddingV)
                                .hBottomBorder()

                            ForEach(pending) { expense in
                                ReviewRow(expense: expense, categories: categories)
                            }
                        }
                        .padding(.horizontal, HisaabTheme.Layout.pagePadding)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .background(ModalSafeAreaFixer())
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.green)
            Text("All caught up!")
                .font(HisaabTheme.mono(HisaabTheme.FontSize.headline, weight: .medium))
                .foregroundStyle(Color.hPrimary)
            Text("No pending Gmail transactions to review.")
                .font(HisaabTheme.mono(HisaabTheme.FontSize.body))
                .foregroundStyle(Color.hSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func approveAll() {
        for expense in pending { expense.isReviewed = true }
        try? modelContext.save()
    }
}

private struct ReviewRow: View {
    @Bindable var expense: Expense
    let categories: [ExpenseCategory]
    @State private var showEdit = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(alignment: .leading, spacing: HisaabTheme.Layout.itemGap) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.amount, format: .currency(code: "INR").presentation(.narrow))
                        .font(HisaabTheme.mono(HisaabTheme.FontSize.headline, weight: .bold))
                        .foregroundStyle(Color.hPrimary)
                    if let merchant = expense.merchant {
                        Text(merchant)
                            .font(HisaabTheme.mono(HisaabTheme.FontSize.body))
                            .foregroundStyle(Color.hSecondary)
                    }
                    Text(expense.date.formatted(.dateTime.day().month().year()))
                        .font(HisaabTheme.mono(HisaabTheme.FontSize.small))
                        .foregroundStyle(Color.hSecondary)
                }
                Spacer()
                categoryBadge
            }

            HStack(spacing: 8) {
                actionButton("Edit", style: .outline) { showEdit = true }
                actionButton("Approve", style: .filled) {
                    saveRule(merchant: expense.merchant, category: expense.category)
                    expense.isReviewed = true
                    try? modelContext.save()
                }
                Button(role: .destructive) {
                    modelContext.delete(expense)
                    try? modelContext.save()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundStyle(.red)
                        .padding(.horizontal, HisaabTheme.Layout.chipH)
                        .padding(.vertical, HisaabTheme.Layout.chipV)
                        .overlay(Rectangle().stroke(Color.red.opacity(0.4), lineWidth: HisaabTheme.Layout.borderWidth))
                }
                .buttonStyle(PressScaleButtonStyle())
            }
        }
        .padding(.vertical, HisaabTheme.Layout.rowPaddingV)
        .hBottomBorder()
        .sheet(isPresented: $showEdit) {
            EditImportedExpenseView(expense: expense, categories: categories)
        }
    }

    private var categoryBadge: some View {
        let emoji = categories.first { $0.name == expense.category }?.emoji ?? "💸"
        return Text("\(emoji) \(expense.category)")
            .font(HisaabTheme.mono(HisaabTheme.FontSize.small, weight: .medium))
            .foregroundStyle(Color.hPrimary)
            .padding(.horizontal, HisaabTheme.Layout.chipH)
            .padding(.vertical, HisaabTheme.Layout.chipV)
            .hOutline()
    }

    private enum ButtonStyle { case outline, filled }

    private func actionButton(_ label: String, style: ButtonStyle, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(HisaabTheme.mono(HisaabTheme.FontSize.small, weight: style == .filled ? .semibold : .regular))
                .foregroundStyle(style == .filled ? Color.hBackground : Color.hPrimary)
                .padding(.horizontal, HisaabTheme.Layout.chipH)
                .padding(.vertical, HisaabTheme.Layout.chipV)
                .background(style == .filled ? Color.hPrimary : Color.clear)
                .hOutline()
        }
        .buttonStyle(PressScaleButtonStyle())
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
        ZStack(alignment: .top) {
            Color.hBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                HisaabHeader(
                    title: "Edit Transaction",
                    leftAction: AnyView(
                        Button("Cancel") { dismiss() }
                            .font(HisaabTheme.mono(HisaabTheme.FontSize.body))
                            .foregroundStyle(Color.hSecondary)
                    ),
                    rightAction: AnyView(
                        Button("Save") {
                            if let value = Double(amountText), value > 0 { expense.amount = value }
                            saveRule(merchant: expense.merchant, category: expense.category)
                            expense.isReviewed = true
                            try? modelContext.save()
                            dismiss()
                        }
                        .font(HisaabTheme.mono(HisaabTheme.FontSize.body, weight: .semibold))
                        .foregroundStyle(Color.hPrimary)
                    )
                )
                .padding(.horizontal, HisaabTheme.Layout.pagePadding)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        amountRow
                        categoryRow
                        noteRow
                    }
                    .padding(.horizontal, HisaabTheme.Layout.pagePadding)
                    .padding(.bottom, 32)
                }
            }
        }
        .background(ModalSafeAreaFixer())
        .onAppear { amountText = String(expense.amount) }
    }

    private var amountRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Amount".uppercased())
                .font(HisaabTheme.mono(HisaabTheme.FontSize.small, weight: .medium))
                .foregroundStyle(Color.hSecondary)
                .tracking(0.8)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("₹")
                    .font(HisaabTheme.mono(HisaabTheme.FontSize.display, weight: .semibold))
                    .foregroundStyle(Color.hSecondary)
                TextField("0", text: $amountText)
                    .font(HisaabTheme.mono(HisaabTheme.FontSize.hero, weight: .bold))
                    .foregroundStyle(Color.hPrimary)
                    .keyboardType(.decimalPad)
                    .minimumScaleFactor(0.5)
            }
        }
        .padding(.vertical, HisaabTheme.Layout.rowPaddingV)
        .hBottomBorder()
    }

    private var categoryRow: some View {
        VStack(alignment: .leading, spacing: HisaabTheme.Layout.itemGap) {
            Text("Category".uppercased())
                .font(HisaabTheme.mono(HisaabTheme.FontSize.small, weight: .medium))
                .foregroundStyle(Color.hSecondary)
                .tracking(0.8)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories) { cat in
                        HisaabChip(
                            label: "\(cat.emoji) \(cat.name)",
                            isSelected: expense.category == cat.name
                        ) {
                            expense.category = cat.name
                        }
                    }
                }
            }
        }
        .padding(.vertical, HisaabTheme.Layout.rowPaddingV)
        .hBottomBorder()
    }

    private var noteRow: some View {
        VStack(alignment: .leading, spacing: HisaabTheme.Layout.itemGap) {
            Text("Note".uppercased())
                .font(HisaabTheme.mono(HisaabTheme.FontSize.small, weight: .medium))
                .foregroundStyle(Color.hSecondary)
                .tracking(0.8)
            TextField("Note (optional)", text: Binding(
                get: { expense.note ?? "" },
                set: { expense.note = $0.isEmpty ? nil : $0 }
            ))
            .font(HisaabTheme.mono(HisaabTheme.FontSize.body))
            .foregroundStyle(Color.hPrimary)
        }
        .padding(.vertical, HisaabTheme.Layout.rowPaddingV)
        .hBottomBorder()
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
