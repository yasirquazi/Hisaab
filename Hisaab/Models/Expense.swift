import SwiftData
import Foundation

enum ExpenseSource: String, Codable {
    case manual, voice, gmail
}

@Model
final class Expense {
    var id: UUID = UUID()
    var amount: Double
    var category: String
    var note: String?
    var date: Date
    var source: ExpenseSource
    var gmailMessageId: String?
    var merchant: String?
    var isReviewed: Bool = false

    init(
        amount: Double,
        category: String,
        note: String? = nil,
        date: Date = .now,
        source: ExpenseSource = .manual,
        gmailMessageId: String? = nil,
        merchant: String? = nil
    ) {
        self.amount = amount
        self.category = category
        self.note = note
        self.date = date
        self.source = source
        self.gmailMessageId = gmailMessageId
        self.merchant = merchant
    }
}
