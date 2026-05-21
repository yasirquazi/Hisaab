import SwiftData
import Foundation

@Model
final class FinancialProfile {
    var monthlyIncome: Double
    var familyTransferAmount: Double
    var lastUpdated: Date

    init(monthlyIncome: Double, familyTransferAmount: Double) {
        self.monthlyIncome = monthlyIncome
        self.familyTransferAmount = familyTransferAmount
        self.lastUpdated = .now
    }
}
