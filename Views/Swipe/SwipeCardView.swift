import SwiftUI

struct SwipeCardView: View {
    let item: SwipeItem

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Net Fotoğraf
            AsyncImage(url: URL(string: item.imageUrl)) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    Color.gray.opacity(0.1)
                }
            }
            .frame(height: 480)
            .clipped()
            .cornerRadius(24)

            // Yazı Okunurluğu için hafif üst gölge
            LinearGradient(gradient: Gradient(colors: [.black.opacity(0.5), .clear]), startPoint: .top, endPoint: .center)
                .frame(height: 120)
                .cornerRadius(24)

            // Sol Üstte Küçük Yazı
            Text(item.title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(20)
        }
        .padding(.horizontal, 20)
    }
}
