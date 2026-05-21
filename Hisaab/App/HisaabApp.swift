import SwiftUI
import SwiftData

@main
struct HisaabApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: [Expense.self, ExpenseCategory.self, FinancialProfile.self])
    }
}
