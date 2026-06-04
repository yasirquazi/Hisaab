import SwiftUI
import SwiftData

struct AddExpenseView: View {
    var editingExpense: Expense? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]

    @State private var amountText = ""
    @State private var selectedCategory = ""
    @State private var note = ""
    @State private var date = Date.now
    @State private var showDatePicker = false

    private var isEditing: Bool { editingExpense != nil }

    private var amount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: ""))
    }

    private var canSave: Bool {
        amount != nil && amount! > 0 && !selectedCategory.isEmpty
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.hBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                HisaabHeader(
                    title: isEditing ? "Edit Expense" : "Add Expense",
                    leftAction: AnyView(
                        Button("Cancel") { dismiss() }
                            .font(HisaabTheme.mono(HisaabTheme.FontSize.body))
                            .foregroundStyle(Color.hSecondary)
                    ),
                    rightAction: AnyView(
                        Button("Save") { save() }
                            .font(HisaabTheme.mono(HisaabTheme.FontSize.body, weight: .semibold))
                            .foregroundStyle(canSave ? Color.hPrimary : Color.hBorder)
                            .disabled(!canSave)
                    )
                )
                .padding(.horizontal, HisaabTheme.Layout.pagePadding)

                ScrollView {
                    VStack(alignment: .leading, spacing: HisaabTheme.Layout.sectionGap) {
                        amountField
                        categoryPicker
                        noteField
                        dateRow
                        HisaabPrimaryButton(
                            label: isEditing ? "Save Changes" : "Save Expense",
                            disabled: !canSave
                        ) { save() }
                        if isEditing { deleteButton }
                    }
                    .padding(.horizontal, HisaabTheme.Layout.pagePadding)
                    .padding(.bottom, 32)
                }
            }
        }
        .background(ModalSafeAreaFixer())
        .onAppear {
            if let expense = editingExpense {
                amountText = String(expense.amount)
                selectedCategory = expense.category
                note = expense.note ?? ""
                date = expense.date
            } else if selectedCategory.isEmpty, let first = categories.first {
                selectedCategory = first.name
            }
        }
    }

    // MARK: - Amount

    private var amountField: some View {
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
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.5)
            }
        }
        .padding(.top, HisaabTheme.Layout.rowPaddingV)
        .hBottomBorder()
    }

    // MARK: - Category

    private var categoryPicker: some View {
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
                            isSelected: selectedCategory == cat.name
                        ) {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                selectedCategory = cat.name
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, HisaabTheme.Layout.rowPaddingV)
        .hBottomBorder()
    }

    // MARK: - Note

    private var noteField: some View {
        VStack(alignment: .leading, spacing: HisaabTheme.Layout.itemGap) {
            Text("Note".uppercased())
                .font(HisaabTheme.mono(HisaabTheme.FontSize.small, weight: .medium))
                .foregroundStyle(Color.hSecondary)
                .tracking(0.8)
            TextField("Optional note", text: $note)
                .font(HisaabTheme.mono(HisaabTheme.FontSize.body))
                .foregroundStyle(Color.hPrimary)
        }
        .padding(.vertical, HisaabTheme.Layout.rowPaddingV)
        .hBottomBorder()
    }

    // MARK: - Date

    private var dateRow: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showDatePicker.toggle()
                }
            } label: {
                HStack {
                    Text("Date".uppercased())
                        .font(HisaabTheme.mono(HisaabTheme.FontSize.small, weight: .medium))
                        .foregroundStyle(Color.hSecondary)
                        .tracking(0.8)
                    Spacer()
                    Text(date.formatted(.dateTime.day().month().year().hour().minute()))
                        .font(HisaabTheme.mono(HisaabTheme.FontSize.body))
                        .foregroundStyle(Color.hPrimary)
                    Image("ri-arrow-right-s-line")
                        .renderingMode(.template)
                        .foregroundStyle(Color.hSecondary)
                        .frame(width: 16, height: 16)
                        .rotationEffect(.degrees(showDatePicker ? 90 : 0))
                        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: showDatePicker)
                }
                .padding(.vertical, HisaabTheme.Layout.rowPaddingV)
            }
            .buttonStyle(PressScaleButtonStyle())

            if showDatePicker {
                DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .tint(Color.hPrimary)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .hBottomBorder()
    }

    // MARK: - Delete

    private var deleteButton: some View {
        Button(role: .destructive) {
            guard let expense = editingExpense else { return }
            modelContext.delete(expense)
            try? modelContext.save()
            dismiss()
        } label: {
            Text("Delete Expense")
                .font(HisaabTheme.mono(HisaabTheme.FontSize.headline, weight: .semibold))
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, HisaabTheme.Layout.buttonV)
                .overlay(Rectangle().stroke(Color.red.opacity(0.4), lineWidth: HisaabTheme.Layout.borderWidth))
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    // MARK: - Save

    private func save() {
        guard let amount else { return }
        if let expense = editingExpense {
            expense.amount = amount
            expense.category = selectedCategory
            expense.note = note.isEmpty ? nil : note
            expense.date = date
            try? modelContext.save()
        } else {
            modelContext.insert(Expense(
                amount: amount,
                category: selectedCategory,
                note: note.isEmpty ? nil : note,
                date: date
            ))
        }
        dismiss()
    }
}
