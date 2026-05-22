import SwiftUI

struct TripParticipantsView: View {
    let trip: GeminiTripPlan
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var socialManager = SocialManager.shared
    @State private var participantUsers: [User] = []
    @State private var isLoading = false
    
    var isOwner: Bool {
        trip.userId == authVM.currentUser?.id
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Katılımcılar")
                .font(.headline)
                .padding(.horizontal)
            
            if isLoading {
                ProgressView()
                    .padding()
            } else if participantUsers.isEmpty && trip.userId != authVM.currentUser?.id {
                Text("Henüz kimse katılmadı.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        // Host
                        ParticipantBadge(name: trip.creatorName ?? "Sahip", isHost: true)
                        
                        // Others
                        ForEach(participantUsers) { user in
                            ParticipantBadge(name: user.name ?? "Gezgin", isHost: false)
                                .contextMenu {
                                    if isOwner {
                                        Button(role: .destructive) {
                                            socialManager.removeParticipant(tripId: trip.id ?? "", userId: user.id)
                                        } label: {
                                            Label("Gruptan Çıkar", systemImage: "person.badge.minus")
                                        }
                                    } else if user.id == authVM.currentUser?.id {
                                        Button(role: .destructive) {
                                            socialManager.leaveTrip(tripId: trip.id ?? "", userId: user.id)
                                        } label: {
                                            Label("Gruptan Ayrıl", systemImage: "rectangle.portrait.and.arrow.right")
                                        }
                                    }
                                }
                        }
                        
                        // If I am a participant but not the owner, I should see myself and have an option to leave
                        if !isOwner && trip.participants?.contains(authVM.currentUser?.id ?? "") == true && !participantUsers.contains(where: { $0.id == authVM.currentUser?.id }) {
                             ParticipantBadge(name: authVM.currentUser?.name ?? "Ben", isHost: false)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        socialManager.leaveTrip(tripId: trip.id ?? "", userId: authVM.currentUser?.id ?? "")
                                    } label: {
                                        Label("Gruptan Ayrıl", systemImage: "rectangle.portrait.and.arrow.right")
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            if !isOwner && trip.participants?.contains(authVM.currentUser?.id ?? "") == true {
                Button(action: {
                    socialManager.leaveTrip(tripId: trip.id ?? "", userId: authVM.currentUser?.id ?? "")
                }) {
                    Text("Gruptan Ayrıl")
                        .font(.caption.bold())
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
            }
        }
        .onAppear {
            fetchParticipants()
        }
        .onChange(of: trip.participants) { _ in
            fetchParticipants()
        }
    }
    
    private func fetchParticipants() {
        guard let participantIds = trip.participants, !participantIds.isEmpty else {
            self.participantUsers = []
            return
        }
        
        isLoading = true
        DatabaseManager.shared.getAllUsers { allUsers in
            DispatchQueue.main.async {
                self.participantUsers = allUsers.filter { participantIds.contains($0.id) }
                self.isLoading = false
            }
        }
    }
}

struct ParticipantBadge: View {
    let name: String
    let isHost: Bool
    
    var body: some View {
        VStack {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(isHost ? Color.orange.opacity(0.2) : Color.blue.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(name.prefix(1))
                            .font(.title2.bold())
                            .foregroundColor(isHost ? .orange : .blue)
                    )
                
                if isHost {
                    Image(systemName: "crown.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .padding(4)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
            }
            
            Text(name)
                .font(.caption.bold())
                .lineLimit(1)
                .frame(width: 70)
        }
    }
}
