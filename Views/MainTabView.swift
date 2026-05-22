import SwiftUI

struct MainTabView: View {
    @StateObject private var router = AppRouter.shared

    var body: some View {
        TabView(selection: $router.selectedTab) {

            DiscoverView()
                .tabItem {
                    Image(systemName: "safari.fill")
                    Text("Keşfet")
                }
                .tag(0)

            CommunityView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Topluluk")
                }
                .tag(1)

            PlannerView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Planla")
                }
                .tag(2)

            InboxView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Mesajlar")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profilim")
                }
                .tag(4)
        }
        .environmentObject(router)
    }
}
