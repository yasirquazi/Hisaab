import Foundation
import GoogleSignIn
import SwiftData

@Observable
final class GmailService {

    var isSignedIn: Bool = false
    var isSyncing: Bool = false
    var syncError: String?
    var lastSyncDate: Date?

    private let gmailReadScope = "https://www.googleapis.com/auth/gmail.readonly"
    private let transactionQuery = "subject:(debited OR credited OR payment OR transaction OR UPI OR NEFT OR IMPS OR spent) newer_than:30d"

    func signIn(presenting: UIViewController) async {
        let config = GIDConfiguration(clientID: clientID())
        GIDSignIn.sharedInstance.configuration = config

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: presenting,
                hint: nil,
                additionalScopes: [gmailReadScope]
            )
            isSignedIn = result.user.grantedScopes?.contains(gmailReadScope) == true
        } catch {
            syncError = error.localizedDescription
        }
    }

    func restorePreviousSignIn() async {
        do {
            let user = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
            isSignedIn = user.grantedScopes?.contains(gmailReadScope) == true
        } catch {
            isSignedIn = false
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        isSignedIn = false
        lastSyncDate = nil
    }

    func syncEmails(modelContext: ModelContext) async {
        guard isSignedIn, !isSyncing else { return }
        isSyncing = true
        syncError = nil
        defer { isSyncing = false }

        guard let user = GIDSignIn.sharedInstance.currentUser else {
            syncError = "Not signed in"
            return
        }

        do {
            try await user.refreshTokensIfNeeded()
            guard let token = user.accessToken.tokenString as String? else {
                syncError = "Could not get access token"
                return
            }

            let messageIds = try await fetchMessageIds(token: token)
            let existing = try fetchExistingGmailIds(modelContext: modelContext)

            for messageId in messageIds where !existing.contains(messageId) {
                if let expense = try await fetchAndParseMessage(id: messageId, token: token) {
                    modelContext.insert(expense)
                }
            }

            try modelContext.save()
            lastSyncDate = .now
        } catch {
            syncError = error.localizedDescription
        }
    }

    // MARK: - Private

    private func fetchMessageIds(token: String) async throws -> [String] {
        let encodedQuery = transactionQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://gmail.googleapis.com/gmail/v1/users/me/messages?q=\(encodedQuery)&maxResults=50"
        guard let url = URL(string: urlString) else { return [] }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(MessageListResponse.self, from: data)
        return response.messages?.map(\.id) ?? []
    }

    private func fetchAndParseMessage(id: String, token: String) async throws -> Expense? {
        let urlString = "https://gmail.googleapis.com/gmail/v1/users/me/messages/\(id)?format=metadata&metadataHeaders=Subject&metadataHeaders=Date"
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let msg = try JSONDecoder().decode(GmailMessage.self, from: data)

        let subject = msg.payload.headers.first { $0.name == "Subject" }?.value ?? ""
        let dateStr = msg.payload.headers.first { $0.name == "Date" }?.value ?? ""
        let date = parseEmailDate(dateStr) ?? .now
        let snippet = msg.snippet ?? ""

        guard let parsed = EmailParser.parse(subject: subject, body: snippet, date: date) else {
            return nil
        }

        return Expense(
            amount: parsed.amount,
            category: parsed.category,
            note: parsed.note,
            date: parsed.date,
            source: .gmail,
            gmailMessageId: id,
            merchant: parsed.merchant
        )
    }

    private func fetchExistingGmailIds(modelContext: ModelContext) throws -> Set<String> {
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.gmailMessageId != nil }
        )
        let expenses = try modelContext.fetch(descriptor)
        return Set(expenses.compactMap(\.gmailMessageId))
    }

    private func parseEmailDate(_ dateString: String) -> Date? {
        let formatters = [
            "EEE, dd MMM yyyy HH:mm:ss Z",
            "dd MMM yyyy HH:mm:ss Z",
            "EEE, d MMM yyyy HH:mm:ss Z",
        ]
        for format in formatters {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) { return date }
        }
        return nil
    }

    private func clientID() -> String {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let clientId = dict["CLIENT_ID"] as? String else {
            return ""
        }
        return clientId
    }
}

// MARK: - Gmail API response models

private struct MessageListResponse: Decodable {
    let messages: [MessageRef]?
    struct MessageRef: Decodable {
        let id: String
    }
}

private struct GmailMessage: Decodable {
    let snippet: String?
    let payload: Payload
    struct Payload: Decodable {
        let headers: [Header]
    }
    struct Header: Decodable {
        let name: String
        let value: String
    }
}
