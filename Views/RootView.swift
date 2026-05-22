import SwiftUI

struct RootView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        Group {
            if !authVM.isAuthenticated {
                // Hiç giriş yapmamış veya çıkış yapmış
                AuthView().environmentObject(authVM)
            }
            else if let user = authVM.currentUser, !(user.isOnboardingCompleted ?? false) {
                // Giriş yapmış ama onboarding bitmemiş
                SwipeOnboardingView().environmentObject(authVM)
            }
            else {
                // Giriş yapmış ve onboarding bitmiş
                MainTabView().environmentObject(authVM)
            }
        }
        .onAppear {
            NotificationManager.shared.requestPermission()
        }
    }
}
