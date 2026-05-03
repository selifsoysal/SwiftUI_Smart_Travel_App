import SwiftUI

struct FavoritePlacesView: View {
    @StateObject private var savedPlacesManager = SavedPlacesManager.shared
    
    var body: some View {
        AppContainer {
            if savedPlacesManager.savedPlaces.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 80))
                        .foregroundColor(.gray.opacity(0.3))
                    
                    Text("Henüz favori mekanınız yok.")
                        .font(.title3.bold())
                        .foregroundColor(.secondary)
                    
                    Text("Keşfet sekmesinden sevdiğiniz yerleri favorilere ekleyin.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(savedPlacesManager.savedPlaces) { destination in
                            DestinationCardView(destination: destination)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Favori Mekanlarım")
    }
}
