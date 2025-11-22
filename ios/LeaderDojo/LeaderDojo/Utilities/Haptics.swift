import UIKit

/// Leader Dojo Haptic Feedback System
/// Consistent tactile feedback for premium interactions
enum Haptics {
    // MARK: - Notification Feedback
    
    /// Success notification with medium impact
    static func success() {
        let notification = UINotificationFeedbackGenerator()
        notification.prepare()
        notification.notificationOccurred(.success)
        
        // Add medium impact for emphasis
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
    
    /// Error notification with heavy impact
    static func error() {
        let notification = UINotificationFeedbackGenerator()
        notification.prepare()
        notification.notificationOccurred(.error)
        
        // Add heavy impact for emphasis
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
    }
    
    /// Warning notification
    static func warning() {
        let notification = UINotificationFeedbackGenerator()
        notification.prepare()
        notification.notificationOccurred(.warning)
    }
    
    // MARK: - Impact Feedback
    
    /// Light impact for selections and UI interactions
    static func impact() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Light impact for subtle selections
    static func lightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Medium impact for button presses
    static func mediumImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Heavy impact for important actions
    static func heavyImpact() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // MARK: - Selection Feedback
    
    /// Selection changed (for pickers, tabs, segmented controls)
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    // MARK: - Context-Specific Feedback
    
    /// Commitment marked as done
    static func commitmentCompleted() {
        success()
    }
    
    /// Project created or updated
    static func projectAction() {
        mediumImpact()
    }
    
    /// Priority item interaction (soft feedback)
    static func priorityItem() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Swipe action revealed
    static func swipeReveal() {
        lightImpact()
    }
    
    /// Card tap
    static func cardTap() {
        lightImpact()
    }
    
    /// Tab switch
    static func tabSwitch() {
        selection()
    }
    
    /// Entry created
    static func entryCreated() {
        mediumImpact()
    }
    
    /// Reflection saved
    static func reflectionSaved() {
        success()
    }
    
    /// Delete action
    static func delete() {
        heavyImpact()
    }
    
    /// Pull to refresh triggered
    static func refreshTriggered() {
        lightImpact()
    }
    
    // MARK: - Celebration Sequences
    
    /// Celebration feedback (for major achievements)
    static func celebrate() {
        mediumImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            lightImpact()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            lightImpact()
        }
    }
}
