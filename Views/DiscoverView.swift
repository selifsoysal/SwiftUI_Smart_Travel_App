import SwiftUI

struct DiscoverView: View {
    
    @StateObject private var vm = DiscoverViewModel()
    
    var body: some View {
        NavigationStack {
            AppContainer {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        if vm.isLoading {
                            ProgressView("Yükleniyor...")
                                .padding(.top, 40)
                        }
                        
                        LazyVStack(spacing: 20) {
                            ForEach(vm.destinations) { destination in
                                DestinationCardView(destination: destination)
                            }
                        }
                        .padding(.top, 10)
                    }
                }
                .navigationTitle("Keşfet")
                .navigationBarTitleDisplayMode(.large)
                .task {
                    await vm.load()
                }
            }
        }
    }
}
