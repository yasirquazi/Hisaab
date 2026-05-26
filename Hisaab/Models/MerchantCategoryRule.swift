import SwiftData
import Foundation

@Model
final class MerchantCategoryRule {
    var merchant: String        // lowercase, normalized
    var category: String
    var usageCount: Int
    var lastUsed: Date

    init(merchant: String, category: String) {
        self.merchant = merchant.lowercased()
        self.category = category
        self.usageCount = 1
        self.lastUsed = .now
    }
}
