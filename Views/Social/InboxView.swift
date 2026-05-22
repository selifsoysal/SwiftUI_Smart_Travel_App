import SwiftUI
import FirebaseFirestore

struct InboxView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var router: AppRouter
    @StateObject private var socialManager = SocialManager.shared
    @Namespace private var animation
    
    // Group connections by eventId, tripId, or tripDestination
    var groupedConnections: [GroupedConnection] {
        var groups: [String: GroupedConnection] = [:]
        
        for conn in socialManager.myConnections {
            // Eğer durum reddedilmişse ve hiç mesaj yoksa göstermeyelim (gereksiz kalabalık yapmasın)
            if conn.status == .rejected {
                let key = conn.eventId ?? conn.tripId ?? conn.tripDestination ?? conn.id
                let msgCount = socialManager.allMessages.filter { $0.connectionId == key || $0.connectionId == conn.id }.count
                if msgCount == 0 { continue }
            }
            
            let key = conn.eventId ?? conn.tripId ?? conn.tripDestination ?? conn.id
            if var existing = groups[key] {
                existing.connections.append(conn)
                groups[key] = existing
            } else {
                groups[key] = GroupedConnection(id: key, connections: [conn])
            }
        }
        
        return groups.values.sorted { 
            let date1 = $0.connections.map { $0.timestamp }.max() ?? Date.distantPast
            let date2 = $1.connections.map { $0.timestamp }.max() ?? Date.distantPast
            return date1 > date2
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Modern Tab Picker
                HStack(spacing: 0) {
                    let unreadMsgCount = socialManager.allMessages.filter { $0.senderId != authVM.currentUser?.id && ($0.isRead == false || $0.isRead == nil) }.count
                    TabButton(title: "Mesajlar", icon: "bubble.left.and.bubble.right.fill", isSelected: router.inboxTab == 0, badgeCount: unreadMsgCount, animation: animation) {
                        withAnimation(.spring()) { router.inboxTab = 0 }
                    }
                    
                    let unreadStatusChanges = (socialManager.mySentRequests + socialManager.myIncomingRequests).filter { $0.isRead == false }.count
                    TabButton(title: "Bildirimler", icon: "bell.fill", isSelected: router.inboxTab == 1, badgeCount: unreadStatusChanges, animation: animation) {
                        withAnimation(.spring()) { 
                            router.inboxTab = 1 
                            socialManager.markRequestsAsRead()
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
                
                ScrollView {
                    VStack(spacing: 15) {
                        if router.inboxTab == 0 {
                            // ACTIVE CHATS TAB
                            if groupedConnections.isEmpty {
                                EmptyStateView(icon: "message.fill", message: "Henüz mesajlaştığınız kimse yok.")
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(groupedConnections) { group in
                                        GroupChatRowView(group: group)
                                    }
                                }
                                .padding()
                            }
                        } else {
                            // NOTIFICATIONS & REQUESTS TAB
                            VStack(alignment: .leading, spacing: 20) {
                                let pendingIncoming = socialManager.myIncomingRequests.filter { $0.status == .pending }
                                if !pendingIncoming.isEmpty {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Gelen İstekler")
                                            .font(.headline)
                                            .padding(.horizontal)
                                        
                                        ForEach(pendingIncoming) { req in
                                            RequestRowView(request: req)
                                        }
                                    }
                                }
                                
                                // Completed notifications (excluding accepted ones as they are in Messages)
                                // Completed notifications (Accepted for sender, Rejected for both)
                                let completedIncoming = socialManager.myIncomingRequests.filter { $0.status == .rejected }
                                let completedSent = socialManager.mySentRequests.filter { $0.status == .rejected || $0.status == .accepted }
                                let notifications = (completedIncoming + completedSent).sorted(by: { $0.timestamp > $1.timestamp })
                                
                                if notifications.isEmpty && pendingIncoming.isEmpty {
                                    EmptyStateView(icon: "bell.slash", message: "Henüz bir bildirim yok.")
                                } else if !notifications.isEmpty {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Son Hareketler")
                                            .font(.headline)
                                            .padding(.horizontal)
                                        
                                        ForEach(notifications.sorted(by: { $0.timestamp > $1.timestamp }).prefix(15)) { note in
                                            NotificationRowView(notification: note)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
                .background(Color(UIColor.systemGroupedBackground))
            }
            .navigationTitle("Mesajlar")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let myId = authVM.currentUser?.id {
                    socialManager.loadSocialData(for: myId)
                }
                if router.inboxTab == 1 {
                    socialManager.markRequestsAsRead()
                }
            }
            .onChange(of: router.inboxTab) { newValue in
                if newValue == 1 {
                    socialManager.markRequestsAsRead()
                }
            }
        }
    }
}

struct GroupedConnection: Identifiable {
    let id: String // tripId, tripDestination or requestId
    var connections: [ConnectionRequest]
}

struct GroupChatRowView: View {
    let group: GroupedConnection
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var socialManager = SocialManager.shared
    @State private var participants: [User] = []
    @State private var creatorId: String? = nil
    
    var body: some View {
        let firstConn = group.connections.first!
        let destination = firstConn.tripDestination ?? "Genel Sohbet"
        
        // Prepare target for ChatDetailView
        let firstPartner = participants.first(where: { $0.id != authVM.currentUser?.id })
        let traveler = Traveler(
            id: firstPartner?.id ?? "unknown", 
            username: firstPartner?.name ?? "Gezgin", 
            age: firstPartner?.age ?? 25, 
            gender: firstPartner?.gender,
            budget: firstPartner?.budget ?? .medium, 
            travelType: firstPartner?.travelType ?? .solo,
            profileWeights: firstPartner?.profileWeights,
            companions: firstPartner?.companions ?? [],
            plannedTrips: []
        )

        NavigationLink(destination: ChatDetailView(targetTraveler: traveler, providedConnections: group.connections)) {
            HStack(spacing: 15) {
                // Multi-avatar circle
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: "#008285"), Color(hex: "#00A2A5")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 55, height: 55)
                    
                    Image(systemName: group.connections.count > 1 ? "person.2.fill" : "person.fill")
                        .foregroundColor(.white)
                        .font(.title3)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // Rota Adı (Başlık)
                    Text(destination)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // Kurucu Adı (Alt Başlık)
                    let firstConn = group.connections.first!
                    let cid = creatorId ?? firstConn.receiverId // Fallback to receiver
                    let creatorName = participants.first(where: { $0.id == cid })?.name ?? "Gezgin"
                    
                    Text("Kurucu: \(creatorName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Unread Badge or Removed Badge
                let unreadCount = socialManager.getUnreadCount(for: group.id)
                if group.connections.contains(where: { $0.status == .rejected }) {
                    Text("Çıkarıldı")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray)
                        .cornerRadius(8)
                } else if unreadCount > 0 {
                    Text("\(unreadCount)")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.red)
                        .clipShape(Circle())
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
        .onAppear {
            loadParticipants()
        }
    }
    
    private func loadParticipants() {
        let firstConn = group.connections.first!
        var allUids = Set(group.connections.flatMap { [$0.senderId, $0.receiverId] })
        
        // Eğer bu bir rota sohbetiyse, rotanın tüm katılımcılarını çek
        if let tid = firstConn.tripId {
            Firestore.firestore().collection("trips").document(tid).getDocument { snapshot, _ in
                if let data = snapshot, let trip = try? data.data(as: GeminiTripPlan.self) {
                    allUids.formUnion(trip.participants ?? [])
                    if let creator = trip.userId { 
                        allUids.insert(creator)
                        DispatchQueue.main.async {
                            self.creatorId = creator
                        }
                    }
                }
                
                // Kullanıcıları yükle
                fetchUsers(uids: Array(allUids))
            }
        } else {
            fetchUsers(uids: Array(allUids))
        }
    }
    
    private func fetchUsers(uids: [String]) {
        DatabaseManager.shared.getAllUsers { users in
            DispatchQueue.main.async {
                // Kendimizi de isim listesinde göstermek için filtreyi kaldırıyoruz (veya tercihen tutuyoruz ama kurucuyu asla silmiyoruz)
                self.participants = users.filter { uids.contains($0.id) }
            }
        }
    }
}

// ... Rest of the components (EmptyStateView, RequestRowView, NotificationRowView) stay same but NotificationRowView simplified
struct EmptyStateView: View {
    let icon: String
    let message: String
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.3))
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
}

struct RequestRowView: View {
    let request: ConnectionRequest
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var socialManager = SocialManager.shared
    @State private var senderUser: User?
    @State private var showProfile = false
    
    var body: some View {
        HStack(spacing: 15) {
            Button(action: { showProfile = true }) {
                Circle()
                    .fill(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text("\(senderUser?.name?.prefix(1) ?? "?")")
                            .font(.headline).foregroundColor(.white)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Button(action: { showProfile = true }) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: request.requestType == "event" ? "calendar" : "map.fill")
                            Text(request.requestType == "event" ? "ETKİNLİK İSTEĞİ" : "ROTA İSTEĞİ")
                        }
                        .font(.caption2.bold())
                        .foregroundColor(.blue)
                        .tracking(1)
                        
                        Text(senderUser?.name ?? "Gezgin")
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)
                    }
                }
                
                Text(request.tripDestination ?? "Genel Tanışma")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Kişiyi incelemek için dokunun")
                    .font(.caption2)
                    .foregroundColor(.blue.opacity(0.8))
                    .padding(.top, 2)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: { socialManager.rejectRequest(requestId: request.id) }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.gray)
                        .clipShape(Circle())
                }
                
                Button(action: { socialManager.acceptRequest(requestId: request.id, tripId: request.tripId, senderId: request.senderId, requestType: request.requestType) }) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color(hex: "#008285"))
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        .padding(.horizontal)
        .sheet(isPresented: $showProfile) {
            if let user = senderUser {
                let traveler = Traveler(id: user.id, username: user.name ?? "Gezgin", age: user.age ?? 25, gender: user.gender, budget: user.budget ?? .medium, profileWeights: user.profileWeights ?? [:], plannedTrips: [], bio: "")
                TravelerDetailView(traveler: traveler)
            }
        }
        .onAppear {
            DatabaseManager.shared.getAllUsers { users in
                DispatchQueue.main.async {
                    self.senderUser = users.first(where: { $0.id == request.senderId })
                }
            }
        }
    }
}

struct NotificationRowView: View {
    let notification: ConnectionRequest
    @EnvironmentObject var authVM: AuthViewModel
    @State private var partnerUser: User?
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(notification.status == .accepted ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    .frame(width: 45, height: 45)
                
                Image(systemName: notification.status == .accepted ? "checkmark.seal.fill" : "xmark.seal.fill")
                    .foregroundColor(notification.status == .accepted ? .green : .red)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                let partnerName = partnerUser?.name ?? "Gezgin"
                let actionText = notification.status == .accepted ? "isteğini kabul etti!" : "isteğini reddetti."
                Text("\(partnerName) \(actionText)")
                    .font(.subheadline.bold())
                
                Text(notification.requestType == "event" ? "\(notification.tripDestination ?? "Etkinlik") katılım isteği" : "\(notification.tripDestination ?? "Rota") planı ortaklığı")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        .padding(.horizontal)
        .onAppear {
            let partnerId = (notification.senderId == authVM.currentUser?.id) ? notification.receiverId : notification.senderId
            DatabaseManager.shared.getAllUsers { users in
                DispatchQueue.main.async {
                    self.partnerUser = users.first(where: { $0.id == partnerId })
                }
            }
        }
    }
}
