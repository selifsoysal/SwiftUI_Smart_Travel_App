import SwiftUI

struct MainTabView: View {

    var body: some View {
        TabView {

            DiscoverView()
                .tabItem {
                    Image(systemName: "safari")
                    Text("Keşfet")
                }

            PlannerView()
                .tabItem {
                    Image(systemName: "map")
                    Text("Planla")
                }

            TripsView()
                .tabItem {
                    Image(systemName: "airplane")
                    Text("Rotalarım")
                }

            TravelersExploreView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Gezginler")
                }

            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profilim")
                }
        }    }
}
