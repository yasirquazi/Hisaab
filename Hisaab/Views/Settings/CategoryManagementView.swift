import SwiftUI
import SwiftData

struct CategoryManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]

    @State private var showAddCategory = false
    @State private var newName = ""
    @State private var newEmoji = ""

    var body: some View {
        ZStack(alignment: .top) {
            Color.hBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                HisaabHeader(
                    title: "Categories",
                    leftAction: AnyView(
                        Button {
                            showAddCategory = true
                        } label: {
                            Text("+ Add")
                                .font(HisaabTheme.mono(HisaabTheme.FontSize.body))
                                .foregroundStyle(Color.hPrimary)
                        }
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

                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(categories) { cat in
                            categoryRow(cat)
                        }
                    }
                    .padding(.horizontal, HisaabTheme.Layout.pagePadding)
                    .padding(.bottom, 32)
                }
            }
        }
        .background(ModalSafeAreaFixer())
        .sheet(isPresented: $showAddCategory) {
            addCategorySheet
        }
    }

    private func categoryRow(_ cat: ExpenseCategory) -> some View {
        HStack(spacing: 14) {
            Text(cat.emoji)
                .font(.title3)
                .frame(width: 36)

            Text(cat.name)
                .font(HisaabTheme.mono(HisaabTheme.FontSize.body))
                .foregroundStyle(Color.hPrimary)

            Spacer()

            if let budget = cat.monthlyBudget {
                Text(budget, format: .currency(code: "INR").presentation(.narrow))
                    .font(HisaabTheme.mono(HisaabTheme.FontSize.body))
                    .foregroundStyle(Color.hSecondary)
            }

            Button(role: .destructive) {
                modelContext.delete(cat)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.hSecondary)
            }
            .buttonStyle(PressScaleButtonStyle())
        }
        .padding(.vertical, HisaabTheme.Layout.rowPaddingV)
        .hBottomBorder()
    }

    private var addCategorySheet: some View {
        VStack(spacing: 0) {
            HisaabHeader(
                title: "New Category",
                leftAction: AnyView(
                    Button("Cancel") {
                        showAddCategory = false
                        newName = ""
                        newEmoji = ""
                    }
                    .font(HisaabTheme.mono(HisaabTheme.FontSize.body))
                    .foregroundStyle(Color.hSecondary)
                ),
                rightAction: AnyView(
                    Button("Add") { addCategory() }
                        .font(HisaabTheme.mono(HisaabTheme.FontSize.body, weight: .semibold))
                        .foregroundStyle(newName.isEmpty || newEmoji.isEmpty ? Color.hBorder : Color.hPrimary)
                        .disabled(newName.isEmpty || newEmoji.isEmpty)
                )
            )
            .padding(.horizontal, HisaabTheme.Layout.pagePadding)

            VStack(alignment: .leading, spacing: 0) {
                fieldRow(label: "Emoji", placeholder: "e.g. 🎮", text: $newEmoji)
                fieldRow(label: "Name", placeholder: "e.g. Gaming", text: $newName)
            }
            .padding(.horizontal, HisaabTheme.Layout.pagePadding)

            Spacer()
        }
        .background(Color.hBackground)
        .presentationDetents([.medium])
        .presentationBackground(Color.hBackground)
    }

    private func fieldRow(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(HisaabTheme.mono(HisaabTheme.FontSize.small, weight: .medium))
                .foregroundStyle(Color.hSecondary)
                .tracking(0.8)
            TextField(placeholder, text: text)
                .font(HisaabTheme.mono(HisaabTheme.FontSize.title))
                .foregroundStyle(Color.hPrimary)
        }
        .padding(.vertical, HisaabTheme.Layout.rowPaddingV)
        .hBottomBorder()
    }

    private func addCategory() {
        let nextOrder = (categories.last?.sortOrder ?? -1) + 1
        modelContext.insert(ExpenseCategory(name: newName, emoji: newEmoji, sortOrder: nextOrder))
        showAddCategory = false
        newName = ""
        newEmoji = ""
    }
}
