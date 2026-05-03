import SwiftUI

struct DestinationCardView: View {
    let destination: Destination
    @StateObject private var savedPlacesManager = SavedPlacesManager.shared
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            
            // Görseldeki taşmayı önlemek için frame kullanımını güncelledik
            AsyncImage(url: URL(string: destination.imageUrl)) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(height: 280)
                    .clipped()
            } placeholder: {
                Color(UIColor.secondarySystemFill)
                    .frame(height: 280)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
            LinearGradient(
                colors: [.black.opacity(0.7), .clear],
                startPoint: .bottom,
                endPoint: .center
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(destination.city)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text(destination.country)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("⭐ \(destination.rating, specifier: "%.1f")")
                    .foregroundColor(.yellow)
            }
            .padding()
            
            // Favori Butonu Sol Değil, Sağ Üstte olsun diye ZStack içinde topTrailing overlay
            VStack {
                HStack {
                    Spacer()
                    Button {
                        savedPlacesManager.toggleFavorite(destination)
                    } label: {
                        Image(systemName: savedPlacesManager.isFavorite(destination) ? "heart.fill" : "heart")
                            .font(.title3)
                            .foregroundColor(savedPlacesManager.isFavorite(destination) ? .red : .white)
                            .padding(12)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    .padding(12)
                }
                Spacer()
            }
        }
        // Removed internal padding so parent defines it and width is respected
    }
}
