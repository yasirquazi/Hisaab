import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(GmailService.self) private var gmailService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showGmailSync = false
    @State private var showReviewQueue = false
    @State private var showCategoryManagement = false
    @State private var showResetConfirm = false

    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]

    private var pendingCount: Int {
        allExpenses.filter { $0.source == .gmail && !$0.isReviewed }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            sheetHeader
            ScrollView {
                contentBody
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(Color.hBackground)
        .presentationDetents([.height(640), .large])
        .presentationBackground(Color.hBackground)
        .alert("Reset App?", isPresented: $showResetConfirm) {
            Button("Reset Everything", role: .destructive) { performReset() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All expenses, categories, and settings will be permanently deleted. This cannot be undone.")
        }
        .sheet(isPresented: $showGmailSync) {
            GmailSyncView()
                .presentationDetents([.large])
                .presentationBackground(Color.hBackground)
        }
        .sheet(isPresented: $showReviewQueue) {
            ReviewQueueView()
                .presentationDetents([.large])
                .presentationBackground(Color.hBackground)
        }
        .sheet(isPresented: $showCategoryManagement) {
            CategoryManagementView()
                .presentationDetents([.large])
                .presentationBackground(Color.hBackground)
        }
    }

    // MARK: - Header

    private var sheetHeader: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: 32, height: 32)

            Spacer()

            Text("Settings")
                .font(HisaabTheme.mono(HisaabTheme.FontSize.title, weight: .medium))
                .foregroundStyle(Color.hPrimary)

            Spacer()

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.hPrimary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(PressScaleButtonStyle())
        }
        .padding(HisaabTheme.Layout.pagePadding)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.hBorder).frame(height: 1)
        }
    }

    // MARK: - Content

    private var contentBody: some View {
        VStack(alignment: .leading, spacing: 24) {
            gmailSection
            otherSection
        }
        .padding(HisaabTheme.Layout.pagePadding)
        .padding(.bottom, 8)
    }

    // MARK: - Gmail section

    private var gmailSection: some View {
        settingsSection(title: "Gmail Import") {
            listRow(icon: "envelope.fill", label: "Connect Gmail", showChevron: true) {
                if gmailService.isSignedIn { connectedBadge }
            } action: { showGmailSync = true }

            rowDivider

            listRow(icon: "tray.full.fill", label: "Review Queue", showChevron: true) {
                if pendingCount > 0 { countBadge(pendingCount) }
            } action: { showReviewQueue = true }

            rowDivider

            listRow(icon: "arrow.clockwise", label: gmailService.isSyncing ? "Syncing…" : "Sync Mail", showChevron: false) {
                EmptyView()
            } action: {
                guard !gmailService.isSyncing else { return }
                Task { await gmailService.syncEmails(modelContext: modelContext) }
            }
        }
    }

    // MARK: - Other section

    private var otherSection: some View {
        settingsSection(title: "Other") {
            listRow(icon: "tag.fill", label: "Manage Categories", showChevron: true) {
                EmptyView()
            } action: { showCategoryManagement = true }

            rowDivider

            listRow(icon: "square.and.arrow.up", label: "Export Data", showChevron: false) {
                EmptyView()
            } action: { exportData() }

            rowDivider

            listRow(icon: "arrow.counterclockwise", label: "Reset App", tint: .red, showChevron: false) {
                EmptyView()
            } action: { showResetConfirm = true }

            rowDivider

            HStack(spacing: 16) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(Color.hPrimary)
                    .frame(width: 24, height: 24)
                Text("About")
                    .font(HisaabTheme.mono(HisaabTheme.FontSize.body, weight: .medium))
                    .foregroundStyle(Color.hPrimary)
                Spacer()
                Text("Version 1.0.0")
                    .font(HisaabTheme.mono(HisaabTheme.FontSize.small))
                    .foregroundStyle(Color.hSecondary)
            }
            .padding(16)
        }
    }

    // MARK: - Row builder

    @ViewBuilder
    private func listRow<T: View>(
        icon: String,
        label: String,
        tint: Color = Color.hPrimary,
        showChevron: Bool,
        @ViewBuilder trailing: () -> T,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                    .frame(width: 24, height: 24)
                Text(label)
                    .font(HisaabTheme.mono(HisaabTheme.FontSize.body, weight: .medium))
                    .foregroundStyle(tint)
                Spacer()
                trailing()
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.hSecondary)
                        .frame(width: 20, height: 20)
                }
            }
            .padding(16)
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    // MARK: - Badges

    private var connectedBadge: some View {
        Text("Connected")
            .font(HisaabTheme.mono(HisaabTheme.FontSize.small))
            .foregroundStyle(Color(red: 0, green: 66/255, blue: 25/255))
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(Color(red: 114/255, green: 255/255, blue: 104/255))
            .clipShape(Capsule())
    }

    private func countBadge(_ count: Int) -> some View {
        Text("\(count)")
            .font(HisaabTheme.mono(HisaabTheme.FontSize.small))
            .foregroundStyle(Color.hBackground)
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(Color.hAccent)
            .clipShape(Capsule())
    }

    // MARK: - Layout helpers

    private var rowDivider: some View {
        Rectangle().fill(Color.hBorder).frame(height: 1)
    }

    private func settingsSection<C: View>(title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(HisaabTheme.mono(HisaabTheme.FontSize.small, weight: .medium))
                .foregroundStyle(Color.hSecondary)
                .tracking(0.96)
            VStack(spacing: 0) {
                content()
            }
            .overlay(Rectangle().stroke(Color.hBorder, lineWidth: 1))
        }
    }

    // MARK: - Reset

    private func performReset() {
        try? modelContext.delete(model: Expense.self)
        try? modelContext.delete(model: ExpenseCategory.self)
        try? modelContext.delete(model: FinancialProfile.self)
        try? modelContext.delete(model: MerchantCategoryRule.self)
        for (name, emoji, order) in ExpenseCategory.defaults {
            modelContext.insert(ExpenseCategory(name: name, emoji: emoji, sortOrder: order))
        }
        try? modelContext.save()
        gmailService.signOut()
        dismiss()
    }

    // MARK: - Export

    private func exportData() {
        guard let url = generateCSV() else { return }
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }),
              var topVC = window.rootViewController else { return }
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        let actVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        topVC.present(actVC, animated: true)
    }

    private func generateCSV() -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var rows: [String] = ["Date,Amount,Category,Note,Source,Merchant"]
        for expense in allExpenses {
            let date    = dateFormatter.string(from: expense.date)
            let amount  = String(format: "%.2f", expense.amount)
            let cat     = csvField(expense.category)
            let note    = csvField(expense.note ?? "")
            let source  = expense.source.rawValue.capitalized
            let merchant = csvField(expense.merchant ?? "")
            rows.append("\(date),\(amount),\(cat),\(note),\(source),\(merchant)")
        }

        let csv = rows.joined(separator: "\n")
        let filename = "Hisaab_Export_\(dateFormatter.string(from: .now)).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    private func csvField(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") else {
            return value
        }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
