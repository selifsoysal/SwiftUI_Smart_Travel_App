import SwiftUI

struct DestinationCardView: View {
    let destination: Destination
    @EnvironmentObject var authVM: AuthViewModel
    
    private var matchScore: Int {
        guard let user = authVM.currentUser else { return 0 }
        return NeuralMatchingEngine.shared.calculateDestinationMatch(user: user, destination: destination)
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
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
        }
    }
}

// Extension for partial rounded corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

