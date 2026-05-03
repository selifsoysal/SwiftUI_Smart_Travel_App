import SwiftUI

struct TravelerCardView: View {
    var match: MatchResult
    
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var socialManager = SocialManager.shared
    
    // Durum kontrolü
    private var connectionStatus: ConnectionStatus? {
        guard let myId = authVM.currentUser?.id else { return nil }
        return socialManager.getRequestStatus(between: myId, and: match.traveler.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color(hex: "#008285"))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text("\(match.traveler.username.prefix(1))")
                            .font(.headline)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(match.traveler.username)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("\(match.traveler.age) Yaş • \(match.traveler.travelerType.rawValue)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Match Score Circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                        .frame(width: 45, height: 45)
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(match.matchScore) / 100.0)
                        .stroke(Color(hex: "#FF5A5F"), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 45, height: 45)
                        .rotationEffect(.degrees(-90))
                    
                    Text("%\(match.matchScore)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "#FF5A5F"))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Ortak Planlar:")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fontWeight(.bold)
                
                ForEach(match.traveler.plannedTrips) { trip in
                    Text("\(trip.location) (\(formatDate(trip.startDate)) - \(formatDate(trip.endDate)))")
                        .font(.footnote)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    // Detay Gör (Modal açılabilir)
                }) {
                    Text("Detay Gör")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
                
                // Social Action Button
                if connectionStatus == .pending {
                    Button(action: {}) {
                        Text("İstek Gönderildi")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.4))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(true)
                } else if connectionStatus == .accepted {
                    NavigationLink(destination: ChatDetailView(targetTraveler: match.traveler)) {
                        Text("Mesaja Git")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: "#008285")) // Yesil-Mavi ton
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                } else {
                    Button(action: {
                        guard let myId = authVM.currentUser?.id else { return }
                        socialManager.sendRequest(from: myId, to: match.traveler.id)
                    }) {
                        Text("İstek Gönder")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: "#FF5A5F"))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .padding(.horizontal)
        .padding(.vertical, 6)
        .onAppear {
            if let myId = authVM.currentUser?.id {
                socialManager.loadSocialData(for: myId)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
}

// Extension for Color is below..
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
