import SwiftUI
import SwiftData
import GoogleSignIn
import BackgroundTasks

@main
struct HisaabApp: App {
    @State private var gmailService = GmailService()

    init() {
        configureGoogleSignIn()
        registerBackgroundTask()
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                HomeView()
                    .tabItem { Label("Home", systemImage: "house.fill") }
                SpendingsView()
                    .tabItem { Label("Spendings", systemImage: "chart.bar.fill") }
            }
            .environment(gmailService)
            .task { await gmailService.restorePreviousSignIn() }
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
        .modelContainer(for: [Expense.self, ExpenseCategory.self, FinancialProfile.self, GmailSyncState.self, MerchantCategoryRule.self])
    }

    private func configureGoogleSignIn() {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let clientId = dict["CLIENT_ID"] as? String else { return }
        let config = GIDConfiguration(clientID: clientId)
        GIDSignIn.sharedInstance.configuration = config
    }

    private func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.hisaab.gmailsync",
            using: nil
        ) { task in
            handleBackgroundSync(task: task as! BGAppRefreshTask)
        }
    }

    private func handleBackgroundSync(task: BGAppRefreshTask) {
        scheduleNextBackgroundSync()
        Task {
            let container = try? ModelContainer(for: Expense.self, ExpenseCategory.self, FinancialProfile.self, GmailSyncState.self, MerchantCategoryRule.self)
            if let context = container?.mainContext {
                await gmailService.syncEmails(modelContext: context)
            }
            task.setTaskCompleted(success: true)
        }
        task.expirationHandler = { task.setTaskCompleted(success: false) }
    }

    private func scheduleNextBackgroundSync() {
        let request = BGAppRefreshTaskRequest(identifier: "com.hisaab.gmailsync")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600)
        try? BGTaskScheduler.shared.submit(request)
    }
}
