import SwiftUI

enum AppStyle {

    // MARK: - Colors
    static let background = Color.white
    static let primaryText = Color.black
    static let secondaryText = Color.gray.opacity(0.7)

    static let primary = Color.black
    static let accent = Color.blue

    static let cardBackground = Color.gray.opacity(0.12)
}

extension Font {

    static let appTitle = Font.system(size: 28, weight: .bold)
    static let appSubtitle = Font.system(size: 16, weight: .medium)
    static let appBody = Font.system(size: 15, weight: .regular)
    static let appCaption = Font.system(size: 12, weight: .regular)
}

enum AppSpacing {
    static let xs: CGFloat = 6
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}
