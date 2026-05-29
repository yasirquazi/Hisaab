import SwiftData
import Foundation

@Model
final class FinancialProfile {
    var monthlyIncome: Double
    var monthlySavings: Double
    var familyTransferAmount: Double
    var lastUpdated: Date

    init(monthlyIncome: Double, monthlySavings: Double = 0, familyTransferAmount: Double = 0) {
        self.monthlyIncome = monthlyIncome
        self.monthlySavings = monthlySavings
        self.familyTransferAmount = familyTransferAmount
        self.lastUpdated = .now
    }
}
