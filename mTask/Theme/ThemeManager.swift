import SwiftUI

// MARK: - Theme System
struct AppTheme {
    // MARK: - Colors
    struct Colors {
        // Primary colors
        static let primary = Color.blue
        static let primaryLight = Color.blue.opacity(0.1)
        static let accent = Color.orange
        
        // Background colors
        static let background = Color(NSColor.controlBackgroundColor)
        static let secondaryBackground = Color(NSColor.controlColor)
        static let tertiaryBackground = Color(NSColor.separatorColor).opacity(0.1)
        
        // Text colors
        static let primaryText = Color.primary
        static let secondaryText = Color.secondary
        static let tertiaryText = Color(NSColor.tertiaryLabelColor)
        
        // UI Element colors
        static let cardBackground = Color(NSColor.controlBackgroundColor)
        static let cardBorder = Color(NSColor.separatorColor).opacity(0.3)
        static let buttonBackground = Color(NSColor.controlColor)
        static let buttonHover = Color(NSColor.controlAccentColor).opacity(0.1)
        
        // Status colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        
        // Task-specific colors
        static let completedTask = Color.green.opacity(0.7)
        static let overdueTask = Color.red.opacity(0.8)
        static let todayTask = Color.orange.opacity(0.8)
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title2.weight(.semibold)
        static let headline = Font.headline.weight(.medium)
        static let body = Font.body
        static let callout = Font.callout
        static let caption = Font.caption
        static let footnote = Font.footnote
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let extraLarge: CGFloat = 16
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let card = Shadow(
            color: Color.black.opacity(0.05),
            radius: 8,
            x: 0,
            y: 2
        )
        
        static let elevated = Shadow(
            color: Color.black.opacity(0.1),
            radius: 12,
            x: 0,
            y: 4
        )
    }
}

// MARK: - Shadow Helper
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        self
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .shadow(
                color: AppTheme.Shadows.card.color,
                radius: AppTheme.Shadows.card.radius,
                x: AppTheme.Shadows.card.x,
                y: AppTheme.Shadows.card.y
            )
    }
    
    func modernButton() -> some View {
        self
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(AppTheme.Colors.buttonBackground)
            .cornerRadius(AppTheme.CornerRadius.small)
            .contentShape(Rectangle())
    }
    
    func taskRowStyle() -> some View {
        self
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(AppTheme.Colors.cardBorder, lineWidth: 1)
            )
    }
}

// MARK: - Custom Button Styles
struct ModernButtonStyle: ButtonStyle {
    let color: Color
    let isSecondary: Bool
    
    init(color: Color = AppTheme.Colors.primary, isSecondary: Bool = false) {
        self.color = color
        self.isSecondary = isSecondary
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(
                isSecondary 
                    ? AppTheme.Colors.buttonBackground
                    : color
            )
            .foregroundColor(
                isSecondary 
                    ? AppTheme.Colors.primaryText
                    : .white
            )
            .cornerRadius(AppTheme.CornerRadius.small)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct IconButtonStyle: ButtonStyle {
    let color: Color
    
    init(color: Color = AppTheme.Colors.secondaryText) {
        self.color = color
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(color)
            .padding(AppTheme.Spacing.xs)
            .background(
                Circle()
                    .fill(configuration.isPressed ? AppTheme.Colors.buttonHover : Color.clear)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
