import Foundation

struct ParsedExpense {
    var amount: Double?
    var category: String?
    var note: String?
}

struct VoiceParser {

    // Priority matters: Transport is checked before Family Transfer so "flight to Nagpur"
    // matches Transport (on "flight") rather than Family Transfer (on "nagpur").
    // Family Transfer relies on explicit transfer/remittance verbs, not place names.
    private static let categoryKeywords: [(String, [String])] = [
        ("Transport",       ["flight", "flights", "ticket", "tickets", "airline", "indigo", "spicejet",
                             "air india", "airindia", "vistara", "akasa", "airport", "boarding",
                             "transport", "uber", "ola", "auto", "metro", "petrol", "fuel",
                             "cab", "taxi", "bus", "train", "rickshaw"]),
        ("Family Transfer", ["transfer", "send home", "sent home", "send money", "sent money",
                             "family", "parents", "mom", "dad", "mother", "father", "ghar",
                             "remit", "wire"]),
        ("Food",            ["food", "lunch", "dinner", "breakfast", "snack", "zomato", "swiggy",
                             "restaurant", "meal", "chai", "tea", "coffee", "bhojan", "khana",
                             "pizza", "burger", "biryani", "cafe"]),
        ("Groceries",       ["groceries", "grocery", "vegetables", "fruits", "milk", "bigbasket",
                             "zepto", "blinkit", "kirana", "sabzi", "dmart"]),
        ("Entertainment",   ["entertainment", "movie", "netflix", "prime", "hotstar", "games",
                             "concert", "ott", "cinema", "theatre"]),
        ("Health",          ["health", "medicine", "doctor", "pharmacy", "hospital", "medical",
                             "chemist", "clinic", "tablet", "tablets", "apollo"]),
        ("Shopping",        ["shopping", "clothes", "flipkart", "myntra", "amazon", "shirt",
                             "shoes", "jeans", "dress"]),
        ("Utilities",       ["electricity", "water", "internet", "wifi", "recharge", "broadband",
                             "bill", "jio", "airtel", "bsnl"]),
    ]

    static func parse(_ transcript: String, availableCategories: [String]) -> ParsedExpense {
        let lower = transcript.lowercased().trimmingCharacters(in: .whitespaces)
        let amount = extractAmount(from: lower)
        let category = extractCategory(from: lower, availableCategories: availableCategories)
        let note = extractNote(from: lower, matchedEntry: entry(for: category))
        return ParsedExpense(amount: amount, category: category, note: note)
    }

    // Matches: "Rs 180", "₹180", "180 rupees", bare number as fallback
    private static func extractAmount(from text: String) -> Double? {
        let patterns = [
            #"(?:rs\.?\s*|₹\s*)(\d[\d,]*(?:\.\d{1,2})?)"#,
            #"(\d[\d,]*(?:\.\d{1,2})?)\s*(?:rs\.?|₹|rupees?)"#,
            #"\b(\d[\d,]*(?:\.\d{1,2})?)\b"#,
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let nsRange = NSRange(text.startIndex..., in: text)
            if let match = regex.firstMatch(in: text, range: nsRange),
               let groupRange = Range(match.range(at: 1), in: text) {
                let numStr = String(text[groupRange]).replacingOccurrences(of: ",", with: "")
                if let value = Double(numStr), value > 0 { return value }
            }
        }
        return nil
    }

    private static func extractCategory(from text: String, availableCategories: [String]) -> String? {
        for (category, keywords) in categoryKeywords {
            guard availableCategories.contains(category) else { continue }
            for keyword in keywords {
                let pattern = "\\b\(NSRegularExpression.escapedPattern(for: keyword))\\b"
                if text.range(of: pattern, options: .regularExpression) != nil {
                    return category
                }
            }
        }
        return nil
    }

    // Strips numbers, currency symbols, filler words, and the matched category's own keywords.
    // What remains is typically the merchant or destination — e.g. "booked flight to Nagpur"
    // → strips "flight", fillers → note: "booked nagpur" (destination preserved)
    private static func extractNote(from text: String, matchedEntry: (String, [String])?) -> String? {
        var cleaned = text
        let fillers = ["spent", "spend", "paid", "pay", "for", "on", "at", "to", "from",
                       "rupees", "rupee", "rs", "₹", "the", "a", "an", "i"]
        for filler in fillers {
            cleaned = cleaned.replacingOccurrences(of: "\\b\(filler)\\b", with: " ", options: .regularExpression)
        }
        // Strip ₹ symbol (not caught by word-boundary pattern above)
        cleaned = cleaned.replacingOccurrences(of: "₹", with: " ")
        // Strip numbers
        cleaned = cleaned.replacingOccurrences(of: #"\d[\d,]*(?:\.\d{1,2})?"#, with: " ", options: .regularExpression)
        if let (_, keywords) = matchedEntry {
            for keyword in keywords {
                let pattern = "\\b\(NSRegularExpression.escapedPattern(for: keyword))\\b"
                cleaned = cleaned.replacingOccurrences(of: pattern, with: " ", options: .regularExpression)
            }
        }
        cleaned = cleaned
            .replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }

    private static func entry(for name: String?) -> (String, [String])? {
        guard let name else { return nil }
        return categoryKeywords.first { $0.0 == name }
    }
}
