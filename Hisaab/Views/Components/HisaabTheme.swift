import SwiftUI

enum HisaabTheme {
    static let background = Color(red: 247/255, green: 243/255, blue: 237/255)
    static let primary    = Color(red: 53/255,  green: 41/255,  blue: 24/255)
    static let secondary  = Color(red: 131/255, green: 122/255, blue: 109/255)
    static let border     = Color(red: 208/255, green: 203/255, blue: 194/255)
    static let accent     = Color(red: 254/255, green: 80/255,  blue: 0/255)

    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom("Chivo Mono", size: size).weight(weight)
    }

    static func categoryIcon(for name: String) -> String {
        switch name {
        case "Food":            return "ri-restaurant-line"
        case "Transport":       return "ri-car-line"
        case "Groceries":       return "ri-shopping-basket-line"
        case "Family Transfer": return "ri-send-plane-line"
        case "Entertainment":   return "ri-film-line"
        case "Health":          return "ri-heart-pulse-line"
        case "Shopping":        return "ri-shopping-bag-line"
        case "Utilities":       return "ri-wifi-line"
        default:                return "ri-more-2-line"
        }
    }
}

extension Color {
    static let hBackground = HisaabTheme.background
    static let hPrimary    = HisaabTheme.primary
    static let hSecondary  = HisaabTheme.secondary
    static let hBorder     = HisaabTheme.border
    static let hAccent     = HisaabTheme.accent
}
