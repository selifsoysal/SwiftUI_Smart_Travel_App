import SwiftUI

struct InboxView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var socialManager = SocialManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Pending Requests
                if !socialManager.myIncomingRequests.isEmpty {
                    Text("Gelen İstekler")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    ForEach(socialManager.myIncomingRequests) { req in
                        RequestRowView(request: req)
                    }
                    
                    Divider().padding(.horizontal)
                }
                
                // Active Chats
                Text("Mesajlar")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                if socialManager.myConnections.isEmpty {
                    Text("Henüz mesajlaştığınız kimse yok.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(socialManager.myConnections) { conn in
                        ChatRowView(connection: conn)
                    }
                }
            }
        }
        .navigationTitle("Gelen Kutusu")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.bottom))
        .onAppear {
            if let myId = authVM.currentUser?.id {
                socialManager.loadSocialData(for: myId)
            }
        }
    }
}

struct RequestRowView: View {
    let request: ConnectionRequest
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var socialManager = SocialManager.shared
    
    // Yalnızca ID tutulduğu için o UUID ile Database'den kullanıcı bilgisini çekebiliriz
    var senderUser: User? {
        // Gerçekte SocialManager cache'inden alınabilir ama şu an DatabaseManager var
        let users = DatabaseManager.shared.getAllUsers()
        return users.first(where: { $0.id == request.senderId })
    }
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.orange.opacity(0.8))
                .frame(width: 50, height: 50)
                .overlay(
                    Text("\(senderUser?.name.prefix(1) ?? "?")")
                        .font(.headline).foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(senderUser?.name ?? "Bilinmeyen Gezgin")
                    .font(.headline)
                Text("Seninle tanışmak istiyor.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: {
                    if let myId = authVM.currentUser?.id {
                        socialManager.rejectRequest(requestId: request.id, currentUserId: myId)
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.gray)
                }
                
                Button(action: {
                    if let myId = authVM.currentUser?.id {
                        socialManager.acceptRequest(requestId: request.id, currentUserId: myId)
                    }
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        .padding(.horizontal)
    }
}

struct ChatRowView: View {
    let connection: ConnectionRequest
    @EnvironmentObject var authVM: AuthViewModel
    
    var partnerUser: User? {
        guard let myId = authVM.currentUser?.id else { return nil }
        let partnerId = (connection.senderId == myId) ? connection.receiverId : connection.senderId
        let users = DatabaseManager.shared.getAllUsers()
        return users.first(where: { $0.id == partnerId })
    }
    
    var body: some View {
        if let partner = partnerUser {
            // Model dönüşümü yapıp ChatDetailView içine Traveler değil User geçiriyoruz veya Traveler dönüştürüyoruz.
            // Traveler objesi uyduralım
            let candidateRef = Traveler(id: partner.id, username: partner.name, age: partner.age, budget: partner.budget, travelerType: partner.travelProfile ?? .culture, plannedTrips: [], bio: "")
            
            NavigationLink(destination: ChatDetailView(targetTraveler: candidateRef)) {
                HStack {
                    Circle()
                        .fill(Color(hex: "#008285"))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text("\(partner.name.prefix(1))")
                                .font(.headline).foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(partner.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Sohbete girmek için tıkla.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundColor(.gray)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                .padding(.horizontal)
            }
        }
    }
}
