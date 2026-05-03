import SwiftUI

struct TravelResultView: View {
    let profile: TravelProfile
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Top Header
                VStack(spacing: 8) {
                    Text("ANALİZ TAMAMLANDI")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.blue)
                        .kerning(2)
                    
                    Text("Senin İçin En Uygun Rotaları Hazırladık")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)

                Spacer()

                // MARK: - Badge Area
                VStack(spacing: 25) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.05))
                            .frame(width: 220, height: 220)
                        
                        Circle()
                            .stroke(Color.blue.opacity(0.2), lineWidth: 2)
                            .frame(width: 250, height: 250)
                        
                        VStack(spacing: 15) {
                            Text(getEmoji(for: profile))
                                .font(.system(size: 70))
                            
                            Text(profile.rawValue.uppercased())
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                    }

                    Text(getDescription(for: profile))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()

                // MARK: - Bottom Button
                Button(action: {
                    withAnimation {
                        // Onboarding'i bitirir ve profili de User objesine kaydeder
                        authVM.completeOnboarding(with: profile)
                        dismiss()
                    }
                }) {
                    HStack {
                        Text("Keşfetmeye Başla")
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(20)
                    .shadow(color: .blue.opacity(0.3), radius: 15, x: 0, y: 8)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
    }

    private func getEmoji(for profile: TravelProfile) -> String {
        switch profile {
        case .culture: return "🏛️"
        case .nature: return "🏔️"
        case .food: return "🍝"
        case .luxury: return "💎"
        case .history: return "📜"
        }
    }

    private func getDescription(for profile: TravelProfile) -> String {
        switch profile {
        case .culture: return "Sen bir kültür elçisisin! Müzeler, sanat galerileri ve şehir ruhu tam sana göre."
        case .nature: return "Doğa senin evin! Dağlar, göller ve temiz hava ile yenilenmeye hazırsın."
        case .food: return "Midenin sesini dinliyorsun! Dünyanın en lezzetli durakları seni bekliyor."
        case .luxury: return "Konfor senin için öncelik! En şık oteller ve premium deneyimlerin tadını çıkar."
        case .history: return "Geçmişin izindesin! Antik kentler ve tarihi yapılar senin tutkun."
        }
    }
}
