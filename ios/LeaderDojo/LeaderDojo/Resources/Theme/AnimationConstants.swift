import SwiftUI

/// Leader Dojo Animation Constants
/// Consistent timing and easing for premium micro-interactions
enum LeaderDojoAnimation {
    // MARK: - Timing Durations
    
    /// Quick animation - 0.2s (button presses, immediate feedback)
    static let quick: Double = 0.2
    
    /// Smooth animation - 0.3s (view transitions, standard interactions)
    static let smooth: Double = 0.3
    
    /// Gentle animation - 0.4s (expansion/collapse, progressive disclosure)
    static let gentle: Double = 0.4
    
    /// Slow animation - 0.6s (celebration animations, success states)
    static let slow: Double = 0.6
    
    // MARK: - Animation Curves
    
    /// Ease out cubic - Most transitions
    static let easeOutCubic = Animation.timingCurve(0.33, 1, 0.68, 1)
    
    /// Spring - Bouncy interactions (buttons, selections)
    static let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    
    /// Smooth ease - Standard transitions
    static let smoothEase = Animation.easeOut(duration: smooth)
    
    /// Quick ease - Fast feedback
    static let quickEase = Animation.easeOut(duration: quick)
    
    /// Gentle ease - Slow reveals
    static let gentleEase = Animation.easeInOut(duration: gentle)
    
    // MARK: - Preset Animations
    
    /// Button press animation (scale down)
    static let buttonPress = Animation.spring(response: 0.2, dampingFraction: 0.6)
    
    /// Card appearance animation (fade + slide)
    static let cardAppear = Animation.easeOut(duration: gentle)
    
    /// List item animation
    static let listItem = Animation.easeOut(duration: smooth)
    
    /// Completion animation (success feedback)
    static let completion = Animation.spring(response: 0.4, dampingFraction: 0.7)
    
    /// Tab switch animation
    static let tabSwitch = Animation.easeInOut(duration: smooth)
    
    /// Loading pulse animation
    static let loadingPulse = Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)
    
    /// Swipe action reveal
    static let swipeReveal = Animation.spring(response: 0.35, dampingFraction: 0.75)
    
    // MARK: - Scale Transforms
    
    /// Button pressed scale
    static let buttonPressedScale: CGFloat = 0.96
    
    /// Button normal scale
    static let buttonNormalScale: CGFloat = 1.0
    
    /// Success celebration scale
    static let celebrationScale: CGFloat = 1.15
    
    // MARK: - Opacity Transforms
    
    /// Disabled opacity
    static let disabledOpacity: Double = 0.5
    
    /// Hidden opacity
    static let hiddenOpacity: Double = 0.0
    
    /// Visible opacity
    static let visibleOpacity: Double = 1.0
    
    /// Subtle opacity (secondary elements)
    static let subtleOpacity: Double = 0.7
}

// MARK: - Animation Modifiers

extension View {
    /// Apply button press animation (scale down on tap)
    func dojoButtonPressAnimation(isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? LeaderDojoAnimation.buttonPressedScale : LeaderDojoAnimation.buttonNormalScale)
            .animation(LeaderDojoAnimation.buttonPress, value: isPressed)
    }
    
    /// Apply card appearance animation (fade + slide up)
    func dojoCardAppearAnimation() -> some View {
        self
            .transition(.asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .opacity
            ))
            .animation(LeaderDojoAnimation.cardAppear, value: UUID())
    }
    
    /// Apply loading pulse animation
    func dojoLoadingPulse() -> some View {
        self
            .opacity(0.6)
            .animation(LeaderDojoAnimation.loadingPulse, value: UUID())
    }
    
    /// Apply completion celebration animation
    func dojoCelebrationAnimation() -> some View {
        self
            .scaleEffect(LeaderDojoAnimation.celebrationScale)
            .animation(LeaderDojoAnimation.completion, value: UUID())
    }
}

// MARK: - Transition Presets

extension AnyTransition {
    /// Card appearance transition (slide up + fade)
    static var dojoCardAppear: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .scale(scale: 0.95).combined(with: .opacity)
        )
    }
    
    /// Modal presentation transition
    static var dojoModalPresent: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom),
            removal: .move(edge: .bottom)
        )
    }
    
    /// List item transition
    static var dojoListItem: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
}

