import SwiftUI
import SwiftData
import GoogleSignIn

struct GmailSyncView: View {
    @Environment(GmailService.self) private var gmailService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    iconHeader

                    if gmailService.isSignedIn {
                        connectedCard
                    } else {
                        connectCard
                    }

                    if let error = gmailService.syncError {
                        errorBanner(error)
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Gmail Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var iconHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 48))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)
            Text("Auto-import bank transactions from your Gmail inbox — no email content is stored.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var connectCard: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Read-only access", systemImage: "lock.shield.fill")
                    .font(.subheadline).fontWeight(.medium)
                Label("Only transaction emails are scanned", systemImage: "envelope.open.fill")
                    .font(.subheadline).fontWeight(.medium)
                Label("No data sent to any server", systemImage: "xmark.icloud.fill")
                    .font(.subheadline).fontWeight(.medium)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Button {
                Task { await signIn() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "envelope.fill")
                    Text("Connect Gmail")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(PressScaleButtonStyle())
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var connectedCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Gmail Connected")
                        .font(.headline)
                    if let last = gmailService.lastSyncDate {
                        Text("Last synced \(last.formatted(.relative(presentation: .named)))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Not yet synced")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }

            Button {
                Task { await gmailService.syncEmails(modelContext: modelContext) }
            } label: {
                HStack(spacing: 8) {
                    if gmailService.isSyncing {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                    Text(gmailService.isSyncing ? "Syncing…" : "Sync Now")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(PressScaleButtonStyle())
            .disabled(gmailService.isSyncing)

            Button(role: .destructive) {
                gmailService.signOut()
            } label: {
                Text("Disconnect Gmail")
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(PressScaleButtonStyle())
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.caption)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(14)
        .background(Color.red.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func signIn() async {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        await gmailService.signIn(presenting: root)
        if gmailService.isSignedIn {
            await gmailService.syncEmails(modelContext: modelContext)
        }
    }
}
