import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(GmailService.self) private var gmailService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showGmailSync = false
    @State private var showReviewQueue = false
    @State private var showCategoryManagement = false

    @Query private var allExpenses: [Expense]
    private var pendingReview: [Expense] {
        allExpenses.filter { $0.source == .gmail && !$0.isReviewed }
    }

    var body: some View {
        NavigationStack {
            List {
                gmailSection
                categoriesSection
                aboutSection
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showGmailSync) {
                GmailSyncView()
            }
            .sheet(isPresented: $showReviewQueue) {
                ReviewQueueView()
            }
            .sheet(isPresented: $showCategoryManagement) {
                CategoryManagementView()
            }
        }
    }

    private var gmailSection: some View {
        Section("Gmail Import") {
            Button {
                showGmailSync = true
            } label: {
                HStack {
                    Label {
                        Text("Connect Gmail")
                    } icon: {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(Color.accentColor)
                    }
                    Spacer()
                    if gmailService.isSignedIn {
                        Text("Connected")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .foregroundStyle(.primary)

            if gmailService.isSignedIn {
                Button {
                    showReviewQueue = true
                } label: {
                    HStack {
                        Label {
                            Text("Review Queue")
                        } icon: {
                            Image(systemName: "tray.full.fill")
                                .foregroundStyle(.orange)
                        }
                        Spacer()
                        if pendingReview.count > 0 {
                            Text("\(pendingReview.count)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.orange)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .foregroundStyle(.primary)

                Button {
                    Task { await gmailService.syncEmails(modelContext: modelContext) }
                } label: {
                    HStack {
                        Label {
                            Text("Sync Now")
                        } icon: {
                            if gmailService.isSyncing {
                                ProgressView().tint(Color.accentColor)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        Spacer()
                        if let last = gmailService.lastSyncDate {
                            Text(last.formatted(.relative(presentation: .named)))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .foregroundStyle(.primary)
                .disabled(gmailService.isSyncing)
            }
        }
    }

    private var categoriesSection: some View {
        Section("Categories") {
            Button {
                showCategoryManagement = true
            } label: {
                HStack {
                    Label {
                        Text("Manage Categories")
                    } icon: {
                        Image(systemName: "tag.fill")
                            .foregroundStyle(.purple)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .foregroundStyle(.primary)
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Label("Version", systemImage: "info.circle.fill")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
