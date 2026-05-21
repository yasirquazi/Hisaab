import SwiftData
import Foundation

// Named ExpenseCategory because the Obj-C runtime already defines `Category` as an opaque type.
@Model
final class ExpenseCategory {
    var name: String
    var emoji: String
    var monthlyBudget: Double?
    var sortOrder: Int

    init(name: String, emoji: String, monthlyBudget: Double? = nil, sortOrder: Int = 0) {
        self.name = name
        self.emoji = emoji
        self.monthlyBudget = monthlyBudget
        self.sortOrder = sortOrder
    }

    static let defaults: [(name: String, emoji: String, sortOrder: Int)] = [
        ("Food", "🍔", 0),
        ("Transport", "🚗", 1),
        ("Groceries", "🛒", 2),
        ("Family Transfer", "🏠", 3),
        ("Entertainment", "🎬", 4),
        ("Health", "💊", 5),
        ("Shopping", "🛍️", 6),
        ("Utilities", "💡", 7),
        ("Other", "📦", 8)
    ]
}
