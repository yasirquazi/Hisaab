import SwiftUI
import SwiftData

@main
struct HisaabApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                HomeView()
                    .tabItem { Label("Home", systemImage: "house.fill") }
                SpendingsView()
                    .tabItem { Label("Spendings", systemImage: "chart.bar.fill") }
            }
        }
        .modelContainer(for: [Expense.self, ExpenseCategory.self, FinancialProfile.self])
    }
}
