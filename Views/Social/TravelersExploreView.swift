import SwiftUI

struct TravelersExploreView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var savedTripsManager = SavedTripsManager.shared
    @StateObject private var socialManager = SocialManager.shared
    
    @State private var matches: [MatchResult] = []
    @State private var hasCalculated: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Senin İçin Eşleşmeler")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Aynı şehir ve tarihlere planı olan gerçek gezginler.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    
                    if !hasCalculated {
                        ProgressView("Eşleşmeler hesaplanıyor...")
                            .padding(.top, 50)
                    } else if matches.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "person.fill.xmark")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("Aynı tarihlerde ve konumlarda eşleşme bulunamadı.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 50)
                    } else {
                        ForEach(matches) { match in
                            TravelerCardView(match: match)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Gezginler")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.bottom))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: InboxView()) {
                        ZStack {
                            Image(systemName: "message.fill")
                                .font(.title3)
                                .foregroundColor(Color(hex: "#008285"))
                            
                            let unreadCount = socialManager.myIncomingRequests.count
                            if unreadCount > 0 {
                                Text("\(unreadCount)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: 10, y: -8)
                            }
                        }
                    }
                }
            }
            .onAppear {
                if let userId = authVM.currentUser?.id {
                    socialManager.loadSocialData(for: userId)
                }
                generateDynamicMatches()
            }
            .onChange(of: authVM.currentUser?.travelProfile) { _ in
                generateDynamicMatches()
            }
            .onChange(of: savedTripsManager.savedTrips.count) { _ in
                generateDynamicMatches()
            }
        }
    }
    
    private func generateDynamicMatches() {
        guard let realUser = authVM.currentUser else { return }
        
        let allUsers = DatabaseManager.shared.getAllUsers()
        var generatedMatches: [MatchResult] = []
        
        for user in allUsers {
            // Kendimizi göstermeyelim
            if user.id == realUser.id { continue }
            
            // Diğer kullanıcının rotalarını UserDefaults'tan çek
            let rawUserTrips = SavedTripsManager.getTrips(for: user.id)
            
            // Traveler objesine dönüştürüyoruz
            var candidatePlannedTrips: [PlannedTrip] = []
            for trip in rawUserTrips {
                if let sDate = trip.startDate, let eDate = trip.endDate {
                    candidatePlannedTrips.append(PlannedTrip(location: trip.selectedDestination, startDate: sDate, endDate: eDate))
                }
            }
            
            let candidate = Traveler(
                id: user.id, // ID önemli (Mesajlaşabilmek için User ID'sini tutuyoruz)
                username: user.name,
                age: user.age,
                budget: user.budget,
                travelerType: user.travelProfile ?? .culture,
                plannedTrips: candidatePlannedTrips,
                bio: "Merhabalar"
            )
            
            let score = MatchingEngine.calculateScore(currentUser: realUser, candidate: candidate, currentUserTrips: savedTripsManager.savedTrips)
            if score > 0 {
                generatedMatches.append(MatchResult(traveler: candidate, matchScore: score))
            }
        }
        
        self.matches = generatedMatches.sorted(by: { $0.matchScore > $1.matchScore })
        self.hasCalculated = true
    }
}
