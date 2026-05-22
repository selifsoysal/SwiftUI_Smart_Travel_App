import SwiftUI

@MainActor
struct TripsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var savedTripsManager = SavedTripsManager.shared
    @State private var selectedFilter = 0 // 0: Oluşturduklarım, 1: Katıldıklarım
    @Namespace private var animation
    @State private var editingTrip: GeminiTripPlan?
    
    var filteredTrips: [GeminiTripPlan] {
        let currentUserId = authVM.currentUser?.id
        if selectedFilter == 0 {
            return savedTripsManager.savedTrips.filter { $0.userId == currentUserId }
        } else {
            return savedTripsManager.savedTrips.filter { $0.userId != currentUserId }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Modern Tab Picker (Community Style)
                HStack(spacing: 0) {
                    TabButton(title: "Oluşturduklarım", icon: "pencil.circle.fill", isSelected: selectedFilter == 0, animation: animation) {
                        withAnimation(.spring()) { selectedFilter = 0 }
                    }
                    TabButton(title: "Katıldıklarım", icon: "person.2.circle.fill", isSelected: selectedFilter == 1, animation: animation) {
                        withAnimation(.spring()) { selectedFilter = 1 }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if filteredTrips.isEmpty {
                            EmptyTripsState(selectedFilter: selectedFilter)
                        } else {
                            LazyVStack(spacing: 15) {
                                ForEach(filteredTrips) { trip in
                                    NavigationLink(destination: TripResultView(plan: trip)) {
                                        SavedTripCard(trip: trip, onEdit: { editingTrip = trip }, onDelete: { savedTripsManager.deleteTrip(trip) })
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                        }
                    }
                    .padding(.vertical)
                }
                .background(Color(UIColor.systemGroupedBackground))
            }
            .navigationTitle("Rotalarım")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $editingTrip) { trip in
                EditTripView(trip: trip) { updatedTrip in
                    savedTripsManager.updateTrip(updatedTrip)
                }
            }
        }
    }
}

struct EmptyTripsState: View {
    let selectedFilter: Int
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: selectedFilter == 0 ? "map.circle.fill" : "person.2.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.3))
            
            Text(selectedFilter == 0 ? "Henüz bir rota oluşturmadınız." : "Henüz bir rotaya katılmadınız.")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(selectedFilter == 0 ? "Planla sekmesinden yeni rotalar oluşturup kaydedin." : "Topluluk kısmından diğer gezginlerin rotalarına göz atın.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
}

struct SavedTripCard: View {
    let trip: GeminiTripPlan
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    @EnvironmentObject var authVM: AuthViewModel
    
    private var isJoined: Bool {
        trip.userId != authVM.currentUser?.id
    }
    
    @State private var matchDetails: MatchingScoreDetails?
    @State private var showMatchDetails = false
    
    private func loadMatchScore() {
        guard isJoined, let user = authVM.currentUser else { return }
        Task {
            let result = await NeuralMatchingEngine.shared.calculateTripMatch(user: user, trip: trip)
            await MainActor.run {
                self.matchDetails = result
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.selectedDestination.uppercased())
                        .font(.caption2.bold())
                        .foregroundColor(.blue)
                        .tracking(1)
                    
                    Text(trip.tripTitle)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }
                Spacer()
                
                // Visible Management Menu
                Menu {
                    if trip.userId == authVM.currentUser?.id {
                        if let onEdit = onEdit {
                            Button(action: onEdit) {
                                Label("Düzenle", systemImage: "pencil")
                            }
                        }
                        
                        if let onDelete = onDelete {
                            Button(role: .destructive, action: onDelete) {
                                Label("Sil", systemImage: "trash")
                            }
                        }
                    } else {
                        Button(role: .destructive) {
                            if let myId = authVM.currentUser?.id, let tid = trip.id {
                                SocialManager.shared.leaveTrip(tripId: tid, userId: myId)
                            }
                        } label: {
                            Label("Ayrıl", systemImage: "person.badge.minus")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title3)
                        .foregroundColor(.gray.opacity(0.3))
                        .padding(4)
                }
                
                if let match = matchDetails, match.score > 0 {
                    Button(action: { showMatchDetails = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "brain.head.profile")
                            Text("%\(match.score)")
                            Image(systemName: "info.circle")
                                .font(.caption2)
                        }
                        .font(.caption.bold())
                        .foregroundColor(Color(hex: "#FF5A5F"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#FF5A5F").opacity(0.1))
                        .cornerRadius(8)
                    }
                    .sheet(isPresented: $showMatchDetails) {
                        MatchAnalysisView(details: match)
                    }
                } else {
                    Image(systemName: "airplane")
                        .font(.title3)
                        .foregroundColor(.blue.opacity(0.3))
                }
            }
            
            HStack {
                Label("\(trip.itinerary.count) Gün", systemImage: "calendar")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let count = trip.participants?.count, count > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption2)
                        Text("\(count) kişi katıldı")
                            .font(.caption2.bold())
                    }
                    .foregroundColor(Color(hex: "#008285"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(hex: "#008285").opacity(0.1))
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
}

