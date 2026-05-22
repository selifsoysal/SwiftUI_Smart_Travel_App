import SwiftUI

struct TravelerCardView: View {
    var match: MatchResult
    
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var socialManager = SocialManager.shared
    
    @State private var showDetail = false
    @State private var showMatchDetails = false
    
    // Durum kontrolü
    private var connectionStatus: ConnectionStatus? {
        guard let myId = authVM.currentUser?.id else { return nil }
        return socialManager.getRequestStatus(
            between: myId, 
            and: match.traveler.id, 
            tripId: match.traveler.plannedTrips.first?.tripId,
            tripDestination: match.traveler.plannedTrips.first?.location
        )
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
                    
                    let dominantProfile = match.traveler.profileWeights?.max(by: { $0.value < $1.value })?.key ?? "Gezgin"
                    Text("\(match.traveler.age) Yaş • \(dominantProfile)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Match Score Circle
                if match.matchScore > 0 {
                        Button(action: { showMatchDetails = true }) {
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
                        .sheet(isPresented: $showMatchDetails) {
                            MatchAnalysisView(details: MatchingScoreDetails(score: match.matchScore, explanations: match.explanations))
                        }
                } else {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                            .frame(width: 45, height: 45)
                        
                        Text("%0")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(match.matchScore > 0 ? "Ortak Planlar:" : "Planlanan Seyahatler:")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fontWeight(.bold)
                
                if match.traveler.plannedTrips.isEmpty {
                    Text("Henüz planı yok.")
                        .font(.footnote)
                        .foregroundColor(.primary)
                } else {
                    ForEach(match.traveler.plannedTrips.prefix(2)) { trip in
                        Text("\(trip.location) (\(formatDate(trip.startDate)) - \(formatDate(trip.endDate)))")
                            .font(.footnote)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                    if match.traveler.plannedTrips.count > 2 {
                        Text("ve \(match.traveler.plannedTrips.count - 2) seyahat daha...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    showDetail = true
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
                    if let pendingReq = socialManager.getPendingRequest(
                        between: authVM.currentUser?.id ?? "", 
                        and: match.traveler.id, 
                        tripId: match.traveler.plannedTrips.first?.tripId,
                        tripDestination: match.traveler.plannedTrips.first?.location
                    ) {
                        if pendingReq.senderId == authVM.currentUser?.id {
                            Button(action: {
                                socialManager.withdrawRequest(requestId: pendingReq.id)
                            }) {
                                Text("İsteği Geri Çek")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.orange.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        } else {
                            Button(action: {}) {
                                Text("Gelen İstek")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.gray.opacity(0.4))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .disabled(true)
                        }
                    } else {
                        Button(action: {}) {
                            Text("İşleniyor...")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.4))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(true)
                    }
                } else if connectionStatus == .accepted {
                    let targetTrip = match.traveler.plannedTrips.first
                    let conns = socialManager.getGroupConnections(for: targetTrip?.location, or: targetTrip?.tripId)
                    NavigationLink(destination: ChatDetailView(targetTraveler: match.traveler, providedConnections: conns)) {
                        Text("Mesaja Git")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: "#008285")) // Yesil-Mavi ton
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                } else if connectionStatus == .rejected {
                    Button(action: {
                        guard let myId = authVM.currentUser?.id else { return }
                        let targetTrip = match.traveler.plannedTrips.first
                        socialManager.sendRequest(from: myId, to: match.traveler.id, tripId: targetTrip?.tripId, tripDestination: targetTrip?.location)
                    }) {
                        Text("Tekrar İstek Gönder")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: "#FF5A5F"))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                } else {
                    Button(action: {
                        guard let myId = authVM.currentUser?.id else { return }
                        let targetTrip = match.traveler.plannedTrips.first
                        socialManager.sendRequest(from: myId, to: match.traveler.id, tripId: targetTrip?.tripId, tripDestination: targetTrip?.location)
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
        .sheet(isPresented: $showDetail) {
            TravelerDetailView(traveler: match.traveler)
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
