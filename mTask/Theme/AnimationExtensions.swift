import SwiftUI

// MARK: - Animation Extensions
extension Animation {
    static let smoothEaseInOut = Animation.easeInOut(duration: 0.25)
    static let gentleBounce = Animation.spring(response: 0.6, dampingFraction: 0.8)
    static let quickFade = Animation.easeInOut(duration: 0.15)
    static let slideIn = Animation.spring(response: 0.5, dampingFraction: 0.9)
}

// MARK: - Transition Extensions
extension AnyTransition {
    static let cardSlide = AnyTransition.asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal: .move(edge: .leading).combined(with: .opacity)
    )
    
    static let cardFade = AnyTransition.asymmetric(
        insertion: .scale(scale: 0.95).combined(with: .opacity),
        removal: .scale(scale: 1.05).combined(with: .opacity)
    )
    
    static let slideFromBottom = AnyTransition.move(edge: .bottom)
        .combined(with: .opacity)
        .animation(.slideIn)
}

// MARK: - Custom Modifier for Hover Effects
struct HoverEffectModifier: ViewModifier {
    @State private var isHovered = false
    let scaleEffect: CGFloat
    let shadowOpacity: Double
    
    init(scaleEffect: CGFloat = 1.02, shadowOpacity: Double = 0.1) {
        self.scaleEffect = scaleEffect
        self.shadowOpacity = shadowOpacity
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? scaleEffect : 1.0)
            .shadow(
                color: Color.black.opacity(isHovered ? shadowOpacity : 0),
                radius: isHovered ? 12 : 0,
                x: 0,
                y: isHovered ? 4 : 0
            )
            .animation(.smoothEaseInOut, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

extension View {
    func hoverEffect(scaleEffect: CGFloat = 1.02, shadowOpacity: Double = 0.1) -> some View {
        self.modifier(HoverEffectModifier(scaleEffect: scaleEffect, shadowOpacity: shadowOpacity))
    }
}

// MARK: - Shimmer Effect for Loading States
struct ShimmerModifier: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.6),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(30))
                    .offset(x: isAnimating ? 300 : -300)
                    .animation(
                        .linear(duration: 1.5).repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            )
            .onAppear {
                isAnimating = true
            }
            .mask(content)
    }
}

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

// MARK: - Pulse Animation
struct PulseModifier: ViewModifier {
    @State private var isPulsing = false
    let minOpacity: Double
    let maxOpacity: Double
    let duration: Double
    
    init(minOpacity: Double = 0.6, maxOpacity: Double = 1.0, duration: Double = 1.0) {
        self.minOpacity = minOpacity
        self.maxOpacity = maxOpacity
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? maxOpacity : minOpacity)
            .animation(
                .easeInOut(duration: duration).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

extension View {
    func pulse(minOpacity: Double = 0.6, maxOpacity: Double = 1.0, duration: Double = 1.0) -> some View {
        self.modifier(PulseModifier(minOpacity: minOpacity, maxOpacity: maxOpacity, duration: duration))
    }
}
