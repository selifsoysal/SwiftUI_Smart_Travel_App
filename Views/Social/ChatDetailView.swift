import SwiftUI
import FirebaseFirestore
import MapKit

struct ChatDetailView: View {
    let targetTraveler: Traveler
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var socialManager = SocialManager.shared
    
    @State private var messageText: String = ""
    @State private var messages: [ChatMessage] = []
    @State private var trip: GeminiTripPlan? = nil
    @State private var connectionStatus: ConnectionStatus = .pending
    @State private var participants: [User] = []
    
    @State private var showRemovalAlert = false
    @State private var userToRemove: User? = nil
    @State private var tripListener: ListenerRegistration? = nil
    
    // Match Analysis State
    @State private var showMatchSheet = false
    @State private var matchDetails: MatchingScoreDetails? = nil
    
    var providedConnection: ConnectionRequest? = nil
    var providedConnections: [ConnectionRequest]? = nil
    
    @State private var showLeaveAlert = false
    @Environment(\.dismiss) var dismiss
    
    // MARK: - Computed Properties
    private var allConns: [ConnectionRequest] {
        if let conns = providedConnections { return conns }
        if let c = providedConnection { return [c] }
        return []
    }
    
    private var roomId: String {
        let first = allConns.first
        let tid = first?.tripId
        let eid = first?.eventId
        let dest = first?.tripDestination
        let rid = first?.id
        return tid ?? eid ?? dest ?? rid ?? "unknown"
    }
    
    private var headerTripId: String? { allConns.first?.tripId }
    private var headerDestination: String? { allConns.first?.tripDestination }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            headerView
            chatContent
            inputArea
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.bottom))
        .onAppear { 
            loadInitialData() 
            socialManager.markMessagesAsRead(for: roomId, currentUserId: authVM.currentUser?.id ?? "")
        }
        .onChange(of: socialManager.allMessages) { _ in 
            self.refreshMessages()
            self.refreshParticipants()
            socialManager.markMessagesAsRead(for: roomId, currentUserId: authVM.currentUser?.id ?? "")
        }
        .onChange(of: socialManager.myIncomingRequests) { _ in 
            self.checkConnectionStatus()
            self.refreshParticipants()
        }
        .onChange(of: socialManager.mySentRequests) { _ in 
            self.checkConnectionStatus()
            self.refreshParticipants()
        }
        .sheet(isPresented: $showMatchSheet) {
            if let details = matchDetails {
                MatchAnalysisView(details: details)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let t = trip, let myId = authVM.currentUser?.id, t.userId != myId, connectionStatus != .rejected {
                    Button(action: { showLeaveAlert = true }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(headerDestination ?? targetTraveler.username)
                        .font(.headline)
                    if headerTripId != nil {
                        Text("Grup Sohbeti • \(participants.count + 1) Kişi")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                if let tripId = headerTripId {
                    NavigationLink(destination: SharedTripWrapperView(tripId: tripId)) {
                        Image(systemName: "map.fill")
                            .font(.subheadline)
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            .padding()
            
            // Map Preview in Header
            if let trip = trip, let firstActivity = trip.itinerary.first?.activities.first(where: { $0.estimatedLat != 0 }), headerTripId != nil {
                let coords = CLLocationCoordinate2D(latitude: firstActivity.estimatedLat, longitude: firstActivity.estimatedLng)
                Map(initialPosition: .region(MKCoordinateRegion(center: coords, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)))) {
                    Marker(firstActivity.placeName, coordinate: coords)
                }
                .frame(height: 120)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .allowsHitTesting(false) // Just a preview
            }
            
            participantsList
        }
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        .alert("Kullanıcıyı Çıkar", isPresented: $showRemovalAlert) {
            Button("İptal", role: .cancel) { userToRemove = nil }
            Button("Çıkar", role: .destructive) { confirmRemoval() }
        } message: {
            Text("\(userToRemove?.name ?? "Bu kullanıcıyı") gruptan çıkarmak istediğinize emin misiniz?")
        }
        .alert("Gruptan Çık", isPresented: $showLeaveAlert) {
            Button("İptal", role: .cancel) { }
            Button("Çık", role: .destructive) { confirmLeave() }
        } message: {
            Text("Bu gruptan çıkmak istediğinize emin misiniz? (Tüm mesaj geçmişini kaybedeceksiniz.)")
        }
    }
    
    private var participantsList: some View {
        Group {
            if headerTripId != nil {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        if let t = trip {
                            ParticipantHeaderItem(name: t.creatorName ?? "Kurucu", isOwner: true, isMe: t.userId == authVM.currentUser?.id, isApproved: true, canRemove: false) { }
                        }
                        ForEach(participants, id: \.id) { user in
                            let isApproved = trip?.participants?.contains(user.id) ?? false
                            let amIOwner = trip?.userId == authVM.currentUser?.id
                            let isMe = user.id == authVM.currentUser?.id
                            ParticipantHeaderItem(name: user.name ?? "Gezgin", isOwner: false, isMe: isMe, isApproved: isApproved, canRemove: amIOwner && !isMe) {
                                self.userToRemove = user
                                self.showRemovalAlert = true
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 15)
                }
            }
        }
    }
    
    private var chatContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    if messages.isEmpty {
                        EmptyChatPlaceholder()
                    } else {
                        let filtered = getFilteredMessages()
                        ForEach(filtered) { msg in
                            ChatMessageView(
                                msg: msg, 
                                isMe: msg.senderId == authVM.currentUser?.id, 
                                roomId: roomId, 
                                tripId: headerTripId ?? "", 
                                tripOwnerId: trip?.userId,
                                onTap: {
                                    if msg.type == .participationRequest {
                                        openMatchAnalysis(for: msg)
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(.vertical)
            }
            .onChange(of: messages.count) { _ in
                if let last = messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }
    
    private var inputArea: some View {
        VStack(spacing: 0) {
            Divider()
            if connectionStatus == .rejected {
                Text("İsteğiniz reddedildi. Artık mesaj gönderemezsiniz.")
                    .font(.subheadline.bold()).foregroundColor(.red).padding().frame(maxWidth: .infinity).background(Color.red.opacity(0.05))
            } else {
                HStack(spacing: 12) {
                    TextField("Mesaj yaz...", text: $messageText)
                        .padding(12).background(Color(.systemGray6)).cornerRadius(20)
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill").font(.title2)
                            .foregroundColor(messageText.isEmpty ? .gray : Color(hex: "#FF5A5F"))
                    }.disabled(messageText.isEmpty)
                }.padding().background(Color(.systemBackground))
            }
        }
    }
    
    // MARK: - Logic Functions
    private func loadInitialData() {
        guard let myId = authVM.currentUser?.id else { return }
        socialManager.loadSocialData(for: myId)
        refreshMessages()
        checkConnectionStatus()
        setupTripListener()
    }
    
    private func setupTripListener() {
        guard let tid = headerTripId else { return }
        tripListener?.remove()
        tripListener = Firestore.firestore().collection("trips").document(tid).addSnapshotListener { snapshot, _ in
            guard let data = snapshot, let fetchedTrip = try? data.data(as: GeminiTripPlan.self) else { return }
            DispatchQueue.main.async {
                self.trip = fetchedTrip
                self.refreshParticipants()
                self.checkConnectionStatus()
            }
        }
    }
    
    private func refreshMessages() {
        let allMsgs = socialManager.getMessages(for: roomId)
        self.messages = allMsgs
    }
    
    private func getFilteredMessages() -> [ChatMessage] {
        if connectionStatus == .rejected {
            let rejectionMsg = messages.first(where: { $0.type == MessageType.participationRejected })
            if let rejectionTime = rejectionMsg?.timestamp {
                return messages.filter { $0.timestamp <= rejectionTime }
            }
        }
        return messages
    }
    
    private func checkConnectionStatus() {
        guard let myId = authVM.currentUser?.id else { return }
        if trip?.userId == myId { self.connectionStatus = .accepted; return }
        let allRequests = socialManager.myIncomingRequests + socialManager.mySentRequests
        if let req = allRequests.first(where: { ($0.tripId == headerTripId || $0.id == roomId) && ($0.senderId == myId || $0.receiverId == myId) }) {
            DispatchQueue.main.async { self.connectionStatus = req.status }
        } else {
            self.connectionStatus = .pending
        }
    }
    
    private func refreshParticipants() {
        let tid = headerTripId
        var allUids = Set<String>()
        if let tripParticipants = trip?.participants { allUids.formUnion(tripParticipants) }
        allUids.formUnion(messages.map { $0.senderId })
        let creatorId = trip?.userId ?? ""
        let finalUids = Array(allUids.filter { $0 != creatorId })
        if !finalUids.isEmpty { loadParticipantUsers(uids: finalUids) }
    }
    
    private func loadParticipantUsers(uids: [String]) {
        Firestore.firestore().collection("users").whereField("id", in: uids).getDocuments { snapshot, _ in
            guard let documents = snapshot?.documents else { return }
            let users = documents.compactMap { try? $0.data(as: User.self) }
            DispatchQueue.main.async { self.participants = users.filter { $0.id != self.trip?.userId } }
        }
    }
    
    private func confirmRemoval() {
        if let user = userToRemove, let tid = trip?.id {
            socialManager.removeParticipant(tripId: tid, userId: user.id)
            withAnimation { self.participants.removeAll(where: { $0.id == user.id }) }
        }
        userToRemove = nil
    }
    
    private func confirmLeave() {
        if let tid = trip?.id, let myId = authVM.currentUser?.id {
            socialManager.leaveTrip(tripId: tid, userId: myId)
            self.connectionStatus = .rejected
            dismiss()
        }
    }
    
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty && connectionStatus != .rejected else { return }
        messageText = ""
        socialManager.sendMessage(connectionId: roomId, senderId: authVM.currentUser?.id ?? "", senderName: authVM.currentUser?.name, receiverId: targetTraveler.id, text: text)
    }
    
    private func openMatchAnalysis(for msg: ChatMessage) {
        // Kullanıcıyı bul ve analizi aç
        DatabaseManager.shared.findUser(userId: msg.senderId) { user in
            guard let user = user, let currentUser = authVM.currentUser else { return }
            
            let traveler = Traveler(
                id: user.id, 
                username: user.name ?? "Gezgin", 
                age: user.age ?? 25, 
                gender: user.gender,
                budget: user.budget ?? .medium, 
                travelType: user.travelType ?? .solo,
                profileWeights: user.profileWeights,
                companions: user.companions ?? [],
                plannedTrips: []
            )
            
            Task {
                var currentUserWithTripContext = currentUser
                if let trip = self.trip, trip.userId == currentUser.id {
                    currentUserWithTripContext.companions = trip.creatorCompanions ?? currentUser.companions
                }
                
                let details = await NeuralMatchingEngine.shared.calculateMatchScore(user1: currentUserWithTripContext, user2: traveler, destination: headerDestination)
                DispatchQueue.main.async {
                    self.matchDetails = details
                    self.showMatchSheet = true
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct EmptyChatPlaceholder: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "message.and.waveform.fill").font(.largeTitle).foregroundColor(.gray.opacity(0.3))
            Text("Sohbeti Başlat!").font(.subheadline).foregroundColor(.secondary)
        }.padding(.top, 60)
    }
}

struct ChatMessageView: View {
    let msg: ChatMessage
    let isMe: Bool
    let roomId: String
    let tripId: String
    let tripOwnerId: String?
    var onTap: () -> Void
    
    init(msg: ChatMessage, isMe: Bool, roomId: String, tripId: String, tripOwnerId: String?, onTap: @escaping () -> Void = {}) {
        self.msg = msg
        self.isMe = isMe
        self.roomId = roomId
        self.tripId = tripId
        self.tripOwnerId = tripOwnerId
        self.onTap = onTap
    }
    
    var body: some View {
        if msg.type == .participationRequest {
            ParticipationRequestBubble(msg: msg, isMe: isMe)
                .onTapGesture { onTap() }
        } else if msg.type == .participationAccepted || msg.type == .participationRejected {
            SystemMessageBubble(msg: msg)
        } else {
            HStack {
                if isMe { Spacer() }
                VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
                    if !isMe { Text(msg.senderName ?? "Gezgin").font(.caption2.bold()).foregroundColor(.secondary) }
                    Text(msg.text).padding(.horizontal, 16).padding(.vertical, 10)
                        .background(isMe ? Color(hex: "#008285") : Color(.secondarySystemBackground))
                        .foregroundColor(isMe ? .white : .primary).cornerRadius(16)
                }
                if !isMe { Spacer() }
            }.padding(.horizontal)
        }
    }
}

struct ParticipationRequestBubble: View {
    let msg: ChatMessage
    let isMe: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Image(systemName: "person.badge.plus"); Text(isMe ? "Katılım isteği gönderdiniz" : "\(msg.senderName ?? "Gezgin") katılmak istiyor") }.font(.headline)
            Text(msg.text).font(.subheadline).foregroundColor(.secondary)
        }.padding().background(Color.blue.opacity(0.1)).cornerRadius(12).padding(.horizontal)
    }
}

struct SystemMessageBubble: View {
    let msg: ChatMessage
    var body: some View {
        HStack {
            Spacer()
            Text(msg.type == .participationAccepted ? "✅ Onaylandı" : "❌ Reddedildi")
                .font(.caption.bold()).padding(8).background(msg.type == .participationAccepted ? Color.green.opacity(0.1) : Color.red.opacity(0.1)).cornerRadius(8)
            Spacer()
        }
    }
}

struct ParticipantHeaderItem: View {
    let name: String
    let isOwner: Bool
    let isMe: Bool
    let isApproved: Bool
    let canRemove: Bool
    let onRemove: () -> Void
    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                Text(name.prefix(1))
                    .frame(width: 40, height: 40)
                    .background(isOwner ? Color.orange : Color.blue)
                    .clipShape(Circle())
                    .foregroundColor(.white)
                
                if canRemove {
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .background(Circle().fill(Color.white))
                            .offset(x: 5, y: -5)
                    }
                }
            }
            Text(isMe ? "Sen" : name).font(.caption2)
        }
    }
}
