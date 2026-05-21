import SwiftUI
import SwiftData

struct CategoryManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]

    @State private var showAddCategory = false
    @State private var newName = ""
    @State private var newEmoji = ""
    @State private var editingCategory: ExpenseCategory?

    var body: some View {
        NavigationStack {
            List {
                ForEach(categories) { cat in
                    HStack(spacing: 14) {
                        Text(cat.emoji)
                            .font(.title3)
                            .frame(width: 36)

                        Text(cat.name)
                            .font(.body)

                        Spacer()

                        if let budget = cat.monthlyBudget {
                            Text(budget, format: .currency(code: "INR").presentation(.narrow))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            modelContext.delete(cat)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }

                Section {
                    Button {
                        showAddCategory = true
                    } label: {
                        Label("Add Category", systemImage: "plus.circle.fill")
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showAddCategory) {
                addCategorySheet
            }
        }
    }

    private var addCategorySheet: some View {
        NavigationStack {
            Form {
                Section("Emoji") {
                    TextField("e.g. 🎮", text: $newEmoji)
                        .font(.title)
                }
                Section("Name") {
                    TextField("e.g. Gaming", text: $newName)
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showAddCategory = false
                        newName = ""
                        newEmoji = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addCategory()
                    }
                    .fontWeight(.semibold)
                    .disabled(newName.isEmpty || newEmoji.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func addCategory() {
        let nextOrder = (categories.last?.sortOrder ?? -1) + 1
        modelContext.insert(ExpenseCategory(name: newName, emoji: newEmoji, sortOrder: nextOrder))
        showAddCategory = false
        newName = ""
        newEmoji = ""
    }
}
