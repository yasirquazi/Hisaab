import SwiftUI
import SwiftData
import GoogleSignIn

struct GmailSyncView: View {
    @Environment(GmailService.self) private var gmailService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            Color.hBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                HisaabHeader(
                    title: "Gmail Import",
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
                    VStack(alignment: .leading, spacing: HisaabTheme.Layout.sectionGap) {
                        descriptionBlock

                        if gmailService.isSignedIn {
                            connectedSection
                        } else {
                            connectSection
                        }

                        if let error = gmailService.syncError {
                            errorBlock(error)
                        }
                    }
                    .padding(.horizontal, HisaabTheme.Layout.pagePadding)
                    .padding(.bottom, 32)
                }
            }
        }
        .background(ModalSafeAreaFixer())
    }

    // MARK: - Description

    private var descriptionBlock: some View {
        Text("Auto-import bank transactions from your Gmail inbox — no email content is stored or sent externally.")
            .font(HisaabTheme.mono(HisaabTheme.FontSize.body))
            .foregroundStyle(Color.hSecondary)
    }

    // MARK: - Connect section

    private var connectSection: some View {
        VStack(alignment: .leading, spacing: HisaabTheme.Layout.itemGap) {
            privacyRow(icon: "lock.shield.fill", text: "Read-only access")
            privacyRow(icon: "envelope.open.fill", text: "Only transaction emails are scanned")
            privacyRow(icon: "xmark.icloud.fill", text: "No data sent to any server")

            HisaabPrimaryButton(label: "Connect Gmail") {
                Task { await signIn() }
            }
        }
    }

    private func privacyRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.hPrimary)
                .frame(width: 20, height: 20)
            Text(text)
                .font(HisaabTheme.mono(HisaabTheme.FontSize.body))
                .foregroundStyle(Color.hPrimary)
            Spacer()
        }
        .padding(.vertical, HisaabTheme.Layout.rowPaddingV)
        .hBottomBorder()
    }

    // MARK: - Connected section

    private var connectedSection: some View {
        VStack(alignment: .leading, spacing: HisaabTheme.Layout.itemGap) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Gmail Connected")
                        .font(HisaabTheme.mono(HisaabTheme.FontSize.headline, weight: .medium))
                        .foregroundStyle(Color.hPrimary)
                    if let last = gmailService.lastSyncDate {
                        Text("Last synced \(last.formatted(.relative(presentation: .named)))")
                            .font(HisaabTheme.mono(HisaabTheme.FontSize.small))
                            .foregroundStyle(Color.hSecondary)
                    } else {
                        Text("Not yet synced")
                            .font(HisaabTheme.mono(HisaabTheme.FontSize.small))
                            .foregroundStyle(Color.hSecondary)
                    }
                }
                Spacer()
            }
            .padding(.vertical, HisaabTheme.Layout.rowPaddingV)
            .hBottomBorder()

            Button {
                Task { await gmailService.syncEmails(modelContext: modelContext) }
            } label: {
                HStack(spacing: 8) {
                    if gmailService.isSyncing {
                        ProgressView().tint(Color.hBackground)
                            .scaleEffect(0.8)
                    }
                    Text(gmailService.isSyncing ? "Syncing…" : "Sync Now")
                }
                .font(HisaabTheme.mono(HisaabTheme.FontSize.headline, weight: .semibold))
                .foregroundStyle(gmailService.isSyncing ? Color.hSecondary : Color.hBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, HisaabTheme.Layout.buttonV)
                .background(gmailService.isSyncing ? Color.hBorder : Color.hPrimary)
            }
            .buttonStyle(PressScaleButtonStyle())
            .disabled(gmailService.isSyncing)

            Button(role: .destructive) {
                gmailService.signOut()
            } label: {
                Text("Disconnect Gmail")
                    .font(HisaabTheme.mono(HisaabTheme.FontSize.body))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, HisaabTheme.Layout.buttonV)
                    .overlay(Rectangle().stroke(Color.red.opacity(0.4), lineWidth: HisaabTheme.Layout.borderWidth))
            }
            .buttonStyle(PressScaleButtonStyle())
        }
    }

    // MARK: - Error

    private func errorBlock(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(HisaabTheme.mono(HisaabTheme.FontSize.small))
                .foregroundStyle(Color.hPrimary)
            Spacer()
        }
        .padding(HisaabTheme.Layout.cardPadding)
        .overlay(Rectangle().stroke(Color.red.opacity(0.4), lineWidth: HisaabTheme.Layout.borderWidth))
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
