import SwiftUI
import SwiftData

struct AddExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]

    @State private var amountText = ""
    @State private var selectedCategory = ""
    @State private var note = ""
    @State private var date = Date.now
    @State private var showDatePicker = false

    private var amount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: ""))
    }

    private var canSave: Bool {
        amount != nil && amount! > 0 && !selectedCategory.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    amountField
                    categoryPicker
                    noteField
                    dateRow
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
        }
        .onAppear {
            if selectedCategory.isEmpty, let first = categories.first {
                selectedCategory = first.name
            }
        }
    }

    // MARK: - Amount

    private var amountField: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("₹")
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)

                TextField("0", text: $amountText)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.5)
            }
            .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Category

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(categories) { cat in
                        categoryChip(cat)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func categoryChip(_ cat: ExpenseCategory) -> some View {
        let isSelected = selectedCategory == cat.name
        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                selectedCategory = cat.name
            }
        } label: {
            HStack(spacing: 6) {
                Text(cat.emoji)
                Text(cat.name)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.tertiarySystemBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    // MARK: - Note

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Note")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            TextField("Optional note", text: $note)
                .font(.body)
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
                    Label("Date", systemImage: "calendar")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text(date.formatted(.dateTime.day().month().year().hour().minute()))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(showDatePicker ? 90 : 0))
                        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: showDatePicker)
                }
                .padding(20)
            }
            .foregroundStyle(.primary)

            if showDatePicker {
                DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Save

    private func save() {
        guard let amount else { return }
        let expense = Expense(
            amount: amount,
            category: selectedCategory,
            note: note.isEmpty ? nil : note,
            date: date
        )
        modelContext.insert(expense)
        dismiss()
    }
}
