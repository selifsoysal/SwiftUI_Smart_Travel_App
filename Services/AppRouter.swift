import SwiftUI
import FirebaseAuth

/// Shared navigation state for cross-tab routing.
@MainActor
final class AppRouter: ObservableObject {
    static let shared = AppRouter()
    
    @Published var selectedTab: Int = 0
    @Published var inboxTab: Int = 0 // 0: Mesajlar, 1: Bildirimler
    /// When set, PlannerView will open TripInputView with this city pre-filled.
    @Published var plannerDestinationCity: String? = nil
    
    private init() {}
    
    func navigateToPlanner(with city: String) {
        plannerDestinationCity = city
        selectedTab = 2   // Planla tab index
    }
    
    func navigateToNotifications() {
        inboxTab = 1
        selectedTab = 3 // Mesajlar/Bildirimler tab index
    }
    
    func navigateToInbox() {
        let unreadMessages = SocialManager.shared.allMessages.filter { $0.senderId != Auth.auth().currentUser?.uid && ($0.isRead == false || $0.isRead == nil) }.count
        if unreadMessages > 0 {
            inboxTab = 0
        } else {
            inboxTab = 1
        }
        selectedTab = 3
    }
}
