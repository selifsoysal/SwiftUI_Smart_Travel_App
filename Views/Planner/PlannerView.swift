import SwiftUI

struct PlannerView: View {
    @State private var selectedMode: PlanMode? = nil
    @EnvironmentObject var router: AppRouter

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // Header Illustration/Icon
                    VStack(spacing: 15) {
                        Image(systemName: "paperplane.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(LinearGradient(colors: [Color(hex: "#008285"), Color(hex: "#00A2A5")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .shadow(color: Color(hex: "#008285").opacity(0.3), radius: 10, y: 5)
                        
                        Text("Yeni Bir Maceraya Hazır Mısın?")
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                        
                        Text("Nasıl bir plan yapmak istersin?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    VStack(spacing: 20) {
                        Button {
                            selectedMode = .ai
                        } label: {
                            PlannerModeCard(
                                title: "Yapay Zeka Önerisi",
                                subtitle: "Kişiliğine en uygun rotayı ve günleri AI senin için belirlesin.",
                                icon: "sparkles",
                                accentColor: .purple
                            )
                        }

                        Button {
                            selectedMode = .manual
                        } label: {
                            PlannerModeCard(
                                title: "Kendin Belirle",
                                subtitle: "Gideceğin şehri ve tarihi sen seç, gerisini biz halledelim.",
                                icon: "map.fill",
                                accentColor: .blue
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 50)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Planla")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $selectedMode) { mode in
                TripInputView(mode: mode, defaultCity: router.plannerDestinationCity)
            }
            .onAppear {
                if let city = router.plannerDestinationCity, !city.isEmpty {
                    selectedMode = .manual
                }
            }
        }
    }
}

struct PlannerModeCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
    }
}
