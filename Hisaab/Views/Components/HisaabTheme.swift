import SwiftUI

// MARK: - Design tokens — change these to restyle the entire app

enum HisaabTheme {

    // MARK: Colors
    static let background = Color(red: 247/255, green: 243/255, blue: 237/255)
    static let primary    = Color(red: 53/255,  green: 41/255,  blue: 24/255)
    static let secondary  = Color(red: 131/255, green: 122/255, blue: 109/255)
    static let border     = Color(red: 208/255, green: 203/255, blue: 194/255)
    static let accent     = Color(red: 254/255, green: 80/255,  blue: 0/255)

    // MARK: Typography sizes — adjust to rescale text globally
    enum FontSize {
        static let micro:    CGFloat = 10
        static let caption:  CGFloat = 11
        static let small:    CGFloat = 12
        static let body:     CGFloat = 14
        static let headline: CGFloat = 16
        static let title:    CGFloat = 20
        static let display:  CGFloat = 32
        static let hero:     CGFloat = 40
    }

    // MARK: Layout — adjust to rescale spacing/sizing globally
    enum Layout {
        static let pagePadding:    CGFloat = 20   // horizontal content margin
        static let sectionGap:     CGFloat = 32   // space between page sections
        static let itemGap:        CGFloat = 16   // space between list items
        static let rowPaddingV:    CGFloat = 14   // vertical padding inside rows
        static let cardPadding:    CGFloat = 20   // internal padding for panels
        static let chipH:          CGFloat = 14   // horizontal chip padding
        static let chipV:          CGFloat = 8    // vertical chip padding
        static let buttonV:        CGFloat = 15   // vertical padding for CTA buttons
        static let iconSize:       CGFloat = 24   // standard icon touch target
        static let categoryIcon:   CGFloat = 40   // transaction category icon container
        static let borderWidth:    CGFloat = 1    // all borders
        static let headerTopPad:   CGFloat = 16   // top padding for custom page headers
    }

    // MARK: Font helper
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom("Chivo Mono", size: size).weight(weight)
    }

    // MARK: Category icon (Remix Icon name)
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

// MARK: - Color shorthands

extension Color {
    static let hBackground = HisaabTheme.background
    static let hPrimary    = HisaabTheme.primary
    static let hSecondary  = HisaabTheme.secondary
    static let hBorder     = HisaabTheme.border
    static let hAccent     = HisaabTheme.accent
}

// MARK: - Reusable view helpers

extension View {
    /// Thin 1-pt bottom rule, matching the border token
    func hBottomBorder() -> some View {
        self.overlay(alignment: .bottom) {
            Rectangle().fill(Color.hBorder).frame(height: HisaabTheme.Layout.borderWidth)
        }
    }

    /// Full 1-pt outline rectangle
    func hOutline() -> some View {
        self.overlay(Rectangle().stroke(Color.hBorder, lineWidth: HisaabTheme.Layout.borderWidth))
    }
}

// MARK: - Reusable subviews

/// A sharp page header: left action | centred title | right action
struct HisaabHeader: View {
    let title: String
    var leftAction: AnyView?
    var rightAction: AnyView?

    var body: some View {
        HStack(spacing: 0) {
            Group {
                if let left = leftAction { left }
                else { Color.clear.frame(width: HisaabTheme.Layout.iconSize) }
            }

            Spacer(minLength: 0)

            Text(title)
                .font(HisaabTheme.mono(HisaabTheme.FontSize.headline, weight: .medium))
                .foregroundStyle(Color.hPrimary)

            Spacer(minLength: 0)

            Group {
                if let right = rightAction { right }
                else { Color.clear.frame(width: HisaabTheme.Layout.iconSize) }
            }
        }
        .padding(.top, HisaabTheme.Layout.headerTopPad)
        .padding(.bottom, HisaabTheme.Layout.itemGap)
    }
}

/// Chip button used in category pickers and filter rows
struct HisaabChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(HisaabTheme.mono(HisaabTheme.FontSize.body,
                                       weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.hBackground : Color.hPrimary)
                .padding(.horizontal, HisaabTheme.Layout.chipH)
                .padding(.vertical, HisaabTheme.Layout.chipV)
                .background(isSelected ? Color.hPrimary : Color.clear)
                .hOutline()
        }
        .buttonStyle(PressScaleButtonStyle())
        .animation(.spring(response: 0.2, dampingFraction: 0.75), value: isSelected)
    }
}

/// Full-width primary action button
struct HisaabPrimaryButton: View {
    let label: String
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(HisaabTheme.mono(HisaabTheme.FontSize.headline, weight: .semibold))
                .foregroundStyle(disabled ? Color.hSecondary : Color.hBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, HisaabTheme.Layout.buttonV)
                .background(disabled ? Color.hBorder : Color.hPrimary)
        }
        .buttonStyle(PressScaleButtonStyle())
        .disabled(disabled)
    }
}

// MARK: - Press scale interaction

struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Window-level safe area (status bar only, not inflated by iOS 26 modal chrome)

var windowSafeAreaTop: CGFloat {
    UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first?.windows
        .first(where: { $0.isKeyWindow })?
        .safeAreaInsets.top ?? 44
}

// MARK: - iOS 26 modal safe-area fix
// iOS 26 injects ~236pt of additionalSafeAreaInsets.top into every modal presentation.
// UIViewControllerRepresentable gives us a direct parent reference to the hosting VC,
// so we can zero out the extra inset on each layout pass.

import UIKit

struct ModalSafeAreaFixer: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> _SafeAreaFixerVC { _SafeAreaFixerVC() }
    func updateUIViewController(_ vc: _SafeAreaFixerVC, context: Context) {}
}

final class _SafeAreaFixerVC: UIViewController {
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let parent else { return }
        let windowTop = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first(where: { $0.isKeyWindow })?
            .safeAreaInsets.top ?? 44
        let extra = parent.view.safeAreaInsets.top - windowTop
        guard extra > 10, parent.additionalSafeAreaInsets.top != 0 else { return }
        parent.additionalSafeAreaInsets.top = 0
    }
}
