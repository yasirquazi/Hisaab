import Foundation

struct ParsedTransaction {
    let amount: Double
    let merchant: String?
    let category: String
    let note: String?
    let date: Date
}

struct EmailParser {

    static func parse(subject: String, body: String, date: Date) -> ParsedTransaction? {
        let combined = subject + " " + body

        guard let amount = extractAmount(from: combined) else { return nil }

        let merchant = extractMerchant(from: combined, subject: subject)
        let category = inferCategory(merchant: merchant, text: combined)
        let note = buildNote(merchant: merchant, subject: subject)

        return ParsedTransaction(
            amount: amount,
            merchant: merchant,
            category: category,
            note: note,
            date: date
        )
    }

    // MARK: - Amount extraction

    private static func extractAmount(from text: String) -> Double? {
        // Patterns: INR 1,234.56 / Rs. 1234 / ₹1,234.56 / debited for Rs 500
        let patterns = [
            #"(?:INR|Rs\.?|₹)\s*([0-9,]+(?:\.[0-9]{1,2})?)"#,
            #"([0-9,]+(?:\.[0-9]{1,2})?)\s*(?:INR|Rs\.?)"#,
            #"(?:debited|deducted|paid|charged)[^\d]*([0-9,]+(?:\.[0-9]{1,2})?)"#,
        ]
        for pattern in patterns {
            if let match = firstCapture(pattern: pattern, in: text) {
                let cleaned = match.replacingOccurrences(of: ",", with: "")
                if let value = Double(cleaned), value > 0 {
                    return value
                }
            }
        }
        return nil
    }

    // MARK: - Merchant extraction

    private static func extractMerchant(from text: String, subject: String) -> String? {
        // UPI: paid to <merchant>
        if let m = firstCapture(pattern: #"(?:paid to|payment to|transferred to)\s+([A-Za-z0-9 &'.\-]+?)(?:\s+(?:on|via|using|for|UPI|ref|txn|transaction)|\.|$)"#, in: text) {
            return m.trimmingCharacters(in: .whitespaces)
        }
        // HDFC/ICICI/SBI: at <merchant>
        if let m = firstCapture(pattern: #"at\s+([A-Za-z0-9 &'.\-]+?)(?:\s+on|\.|,|$)"#, in: text) {
            return m.trimmingCharacters(in: .whitespaces)
        }
        // Swiggy, Zomato, Amazon, Flipkart in subject
        let knownMerchants = ["Swiggy", "Zomato", "Amazon", "Flipkart", "BigBasket", "Blinkit",
                              "Dunzo", "Uber", "Ola", "Rapido", "PhonePe", "Google Pay", "Paytm",
                              "IRCTC", "MakeMyTrip", "Cleartrip", "BookMyShow", "Nykaa", "Myntra"]
        for merchant in knownMerchants {
            if text.localizedCaseInsensitiveContains(merchant) { return merchant }
        }
        return nil
    }

    // MARK: - Category inference

    private static func inferCategory(merchant: String?, text: String) -> String {
        let combined = (merchant ?? "") + " " + text
        let lower = combined.lowercased()

        if lower.contains("swiggy") || lower.contains("zomato") || lower.contains("restaurant") ||
           lower.contains("cafe") || lower.contains("food") || lower.contains("dining") ||
           lower.contains("hotel") || lower.contains("biryani") || lower.contains("pizza") {
            return "Food"
        }
        if lower.contains("uber") || lower.contains("ola") || lower.contains("rapido") ||
           lower.contains("metro") || lower.contains("irctc") || lower.contains("flight") ||
           lower.contains("airline") || lower.contains("indigo") || lower.contains("spicejet") ||
           lower.contains("makemytrip") || lower.contains("cleartrip") || lower.contains("petrol") ||
           lower.contains("diesel") || lower.contains("fuel") || lower.contains("toll") {
            return "Transport"
        }
        if lower.contains("bigbasket") || lower.contains("blinkit") || lower.contains("grofer") ||
           lower.contains("zepto") || lower.contains("dmart") || lower.contains("grocery") ||
           lower.contains("supermarket") || lower.contains("reliance fresh") {
            return "Groceries"
        }
        if lower.contains("amazon") || lower.contains("flipkart") || lower.contains("myntra") ||
           lower.contains("nykaa") || lower.contains("meesho") || lower.contains("shopping") ||
           lower.contains("purchase") || lower.contains("order") {
            return "Shopping"
        }
        if lower.contains("netflix") || lower.contains("spotify") || lower.contains("hotstar") ||
           lower.contains("prime video") || lower.contains("bookmyshow") || lower.contains("movie") ||
           lower.contains("entertainment") || lower.contains("game") {
            return "Entertainment"
        }
        if lower.contains("hospital") || lower.contains("pharmacy") || lower.contains("medical") ||
           lower.contains("doctor") || lower.contains("clinic") || lower.contains("apollo") ||
           lower.contains("medplus") || lower.contains("health") {
            return "Health"
        }
        if lower.contains("electricity") || lower.contains("water bill") || lower.contains("gas bill") ||
           lower.contains("internet") || lower.contains("broadband") || lower.contains("jio") ||
           lower.contains("airtel") || lower.contains("bsnl") || lower.contains("utility") ||
           lower.contains("recharge") {
            return "Utilities"
        }
        return "Shopping"
    }

    // MARK: - Note

    private static func buildNote(merchant: String?, subject: String) -> String? {
        if let merchant { return "Via Gmail: \(merchant)" }
        let trimmed = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Via Gmail" : "Via Gmail: \(trimmed.prefix(60))"
    }

    // MARK: - Helpers

    private static func firstCapture(pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[range])
    }
}
