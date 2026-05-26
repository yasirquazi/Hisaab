import SwiftData
import Foundation

@Model
final class GmailSyncState {
    var isConnected: Bool = false
    var lastSyncDate: Date?
    var syncError: String?
    var pendingReviewCount: Int = 0

    init() {}
}
