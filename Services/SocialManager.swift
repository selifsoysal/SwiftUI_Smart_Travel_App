import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class SocialManager: ObservableObject {
    static let shared = SocialManager()
    
    @Published var myIncomingRequests: [ConnectionRequest] = []
    @Published var mySentRequests: [ConnectionRequest] = []
    @Published var myConnections: [ConnectionRequest] = []
    @Published var allMessages: [ChatMessage] = []
    @Published var myEvents: [ActivityEvent] = []
    
    private var lastIncomingCount = 0
    private var lastMessageIds: Set<String> = []
    private var notifiedRequestIds: Set<String> = []
    private var hasInitialLoad = false
    
    var totalUnreadCount: Int {
        let unreadMessages = allMessages.filter { $0.senderId != Auth.auth().currentUser?.uid && ($0.isRead == false || $0.isRead == nil) }.count
        let pendingIncoming = myIncomingRequests.filter { $0.status == .pending }.count
        // Ayrıca bizim gönderdiğimiz ve karşı tarafın kabul/red edip bizim görmediğimiz durumlar
        let unreadStatusChanges = (mySentRequests + myIncomingRequests).filter { $0.isRead == false }.count
        return pendingIncoming + unreadMessages + unreadStatusChanges
    }
    
    private let db = Firestore.firestore()
    private let requestsCollection = "connection_requests"
    private let messagesCollection = "chat_messages"
    private let eventsCollection = "activity_events"
    
    private var requestsListener: ListenerRegistration?
    private var messagesListener: ListenerRegistration?
    
    private init() {}
    
    // MARK: - Core Fetch & Listeners
    func loadSocialData(for currentUserId: String) {
        setupRequestsListener(for: currentUserId)
        setupMessagesListener(for: currentUserId)
        fetchMyEvents(for: currentUserId)
    }
    
    private func fetchMyEvents(for userId: String) {
        DatabaseManager.shared.fetchUserEvents(userId: userId) { fetchedEvents in
            self.myEvents = fetchedEvents
        }
    }
    
    func deleteEvent(eventId: String, userId: String) {
        DatabaseManager.shared.deleteEvent(eventId: eventId) { error in
            if error == nil {
                DispatchQueue.main.async {
                    self.fetchMyEvents(for: userId)
                }
            }
        }
    }
    
    private func setupRequestsListener(for userId: String) {
        requestsListener?.remove()
        
        requestsListener = db.collection(requestsCollection)
            .whereFilter(Filter.orFilter([
                Filter.whereField("senderId", isEqualTo: userId),
                Filter.whereField("receiverId", isEqualTo: userId)
            ]))
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else { return }
                
                let allReqs = documents.compactMap { try? $0.data(as: ConnectionRequest.self) }
                
                self.myIncomingRequests = allReqs.filter { $0.receiverId == userId }
                self.mySentRequests = allReqs.filter { $0.senderId == userId }
                self.myConnections = allReqs.filter {
                    ($0.senderId == userId || $0.receiverId == userId) && ($0.status == .accepted || $0.status == .rejected)
                }.sorted { $0.timestamp > $1.timestamp }
                
                self.setupMessagesListener(for: userId)
                
                if !self.hasInitialLoad {
                    self.lastIncomingCount = self.myIncomingRequests.count
                    self.notifiedRequestIds = Set(self.mySentRequests.filter { $0.status != .pending }.map { $0.id })
                    self.hasInitialLoad = true
                } else {
                    if self.myIncomingRequests.count > self.lastIncomingCount {
                        NotificationManager.shared.sendNotification(title: "Yeni İstek", body: "Bir gezgin sizinle seyahat etmek istiyor!")
                    }
                    
                    for req in self.mySentRequests {
                        if req.status == .accepted && !self.notifiedRequestIds.contains(req.id) {
                            NotificationManager.shared.sendNotification(title: "İstek Kabul Edildi", body: "Seyahat isteğiniz onaylandı! Sohbet başlayabilir.")
                            self.notifiedRequestIds.insert(req.id)
                        } else if req.status == .rejected && !self.notifiedRequestIds.contains(req.id) {
                            NotificationManager.shared.sendNotification(title: "İstek Reddedildi", body: "Bir seyahat isteğiniz maalesef onaylanmadı.")
                            self.notifiedRequestIds.insert(req.id)
                        }
                    }
                    
                    self.lastIncomingCount = self.myIncomingRequests.count
                }
            }
    }
    
    private func setupMessagesListener(for userId: String) {
        messagesListener?.remove()
        
        let connectionIds = myConnections.map { $0.eventId ?? $0.tripId ?? $0.tripDestination ?? $0.id }
        
        var filters = [
            Filter.whereField("senderId", isEqualTo: userId),
            Filter.whereField("receiverId", isEqualTo: userId)
        ]
        
        for cid in connectionIds.prefix(10) {
            filters.append(Filter.whereField("connectionId", isEqualTo: cid))
        }
        
        messagesListener = db.collection(messagesCollection)
            .whereFilter(Filter.orFilter(filters))
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else { return }
                self.allMessages = documents.compactMap { try? $0.data(as: ChatMessage.self) }
                
                // Bildirimleri gönderen kişi "biz değilsek" (grup sohbeti dahil)
                let incomingMessages = self.allMessages.filter { $0.senderId != userId }
                for msg in incomingMessages {
                    if !self.lastMessageIds.contains(msg.id) && self.hasInitialLoad {
                        NotificationManager.shared.sendNotification(title: msg.senderName ?? "Yeni Mesaj", body: msg.text)
                    }
                }
                self.lastMessageIds = Set(self.allMessages.map { $0.id })
            }
    }
    
    // MARK: - Connection Actions
    func sendRequest(from senderId: String, to receiverId: String, tripId: String? = nil, eventId: String? = nil, tripDestination: String? = nil, requestType: String? = "trip") {
        let baseId = tripId != nil ? "\(senderId)_\(receiverId)_\(tripId!)" : "\(senderId)_\(receiverId)"
        let requestId = eventId != nil ? "\(baseId)_\(eventId!)" : baseId
        
        let newReq = ConnectionRequest(id: requestId, senderId: senderId, receiverId: receiverId, status: .pending, timestamp: Date(), tripId: tripId, eventId: eventId, tripDestination: tripDestination, requestType: requestType, isRead: true)
        
        try? db.collection(requestsCollection).document(requestId).setData(from: newReq)
    }
    
    func acceptRequest(requestId: String, tripId: String?, senderId: String, requestType: String? = "trip") {
        db.collection(requestsCollection).document(requestId).updateData([
            "status": ConnectionStatus.accepted.rawValue,
            "isRead": false // Diğer taraf için okunmadı işaretle
        ])
        
        // ÖNEMLİ: İsteği onayladığımızda kullanıcıyı otomatik olarak rotaya/etkinliğe ekle
        if let tid = tripId {
            db.collection("trips").document(tid).updateData([
                "participants": FieldValue.arrayUnion([senderId])
            ])
        }
    }
    
    func rejectRequest(requestId: String) {
        db.collection(requestsCollection).document(requestId).updateData([
            "status": ConnectionStatus.rejected.rawValue,
            "isRead": false
        ])
    }
    
    func removeParticipant(tripId: String, eventId: String? = nil, userId: String) {
        if let eid = eventId {
            db.collection("activity_events").document(eid).updateData([
                "participants": FieldValue.arrayRemove([userId])
            ])
        } else {
            db.collection("trips").document(tripId).updateData([
                "participants": FieldValue.arrayRemove([userId])
            ])
        }
        
        // Update connection status to block messaging
        let query = db.collection(requestsCollection).whereField("tripId", isEqualTo: tripId)
        query.whereFilter(Filter.orFilter([
            Filter.whereField("senderId", isEqualTo: userId),
            Filter.whereField("receiverId", isEqualTo: userId)
        ])).getDocuments { snapshot, _ in
            snapshot?.documents.forEach { doc in
                let req = try? doc.data(as: ConnectionRequest.self)
                if eventId == nil || req?.eventId == eventId {
                    doc.reference.updateData([
                        "status": ConnectionStatus.rejected.rawValue,
                        "isRead": false
                    ])
                }
            }
        }
    }
    
    func leaveTrip(tripId: String, userId: String) {
        // reuse the same logic as removeParticipant which also rejects the connection
        removeParticipant(tripId: tripId, userId: userId)
    }
    
    func deleteConnection(requestId: String) {
        db.collection(requestsCollection).document(requestId).delete()
        
        db.collection(messagesCollection).whereField("connectionId", isEqualTo: requestId).getDocuments { snapshot, _ in
            snapshot?.documents.forEach { $0.reference.delete() }
        }
    }
    
    func withdrawRequest(requestId: String) {
        db.collection(requestsCollection).document(requestId).delete()
    }
    
    func getPendingRequest(between userA: String, and userB: String, tripId: String? = nil, eventId: String? = nil, tripDestination: String? = nil) -> ConnectionRequest? {
        return (mySentRequests + myIncomingRequests).first {
            let isUsersMatch = ($0.senderId == userA && $0.receiverId == userB) ||
                               ($0.senderId == userB && $0.receiverId == userA)
            let isPending = $0.status == .pending
            
            if !isUsersMatch || !isPending { return false }
            
            if let eid = eventId {
                return $0.eventId == eid
            } else if let tid = tripId {
                return $0.tripId == tid && $0.eventId == nil
            } else {
                return true
            }
        }
    }
    
    func getRequestStatus(between userA: String, and userB: String, tripId: String? = nil, eventId: String? = nil, tripDestination: String? = nil) -> ConnectionStatus? {
        let req = (mySentRequests + myIncomingRequests + myConnections).first {
            let isUsersMatch = ($0.senderId == userA && $0.receiverId == userB) ||
                               ($0.senderId == userB && $0.receiverId == userA)
            
            if !isUsersMatch { return false }
            
            let isTripIdMatch = (tripId != nil && $0.tripId == tripId)
            
            if $0.status == .accepted {
                let dest1 = tripDestination?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
                let dest2 = $0.tripDestination?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
                let isValidDest = !dest1.isEmpty && dest1 != "belirtilmemiş" && dest1 != "gizemli"
                let isDestMatch = isValidDest && (dest1 == dest2)
                
                return isTripIdMatch || isDestMatch
            } else {
                if let eid = eventId {
                    return $0.eventId == eid
                } else if let tid = tripId {
                    return $0.tripId == tid && $0.eventId == nil
                } else {
                    return true
                }
            }
        }
        return req?.status
    }
    
    func getActiveConnection(between userA: String, and userB: String) -> ConnectionRequest? {
        return myConnections.first {
            ($0.senderId == userA && $0.receiverId == userB) ||
            ($0.senderId == userB && $0.receiverId == userA)
        }
    }
    
    func getGroupConnections(for destination: String?, or tripId: String?) -> [ConnectionRequest] {
        return myConnections.filter {
            let isTripIdMatch = (tripId != nil && $0.tripId == tripId)
            
            let dest1 = destination?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
            let dest2 = $0.tripDestination?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
            let isValidDest = !dest1.isEmpty && dest1 != "belirtilmemiş" && dest1 != "gizemli"
            let isDestMatch = isValidDest && (dest1 == dest2)
            
            return isTripIdMatch || isDestMatch
        }
    }
    
    // MARK: - Messaging
    func sendMessage(connectionId: String, senderId: String, senderName: String?, receiverId: String, text: String, type: MessageType = .text, matchScore: Int? = nil) {
        let msgId = UUID().uuidString
        let newMsg = ChatMessage(id: msgId, connectionId: connectionId, senderId: senderId, receiverId: receiverId, text: text, timestamp: Date(), senderName: senderName, type: type, matchScore: matchScore)
        
        try? db.collection(messagesCollection).document(msgId).setData(from: newMsg)
    }
    
    func handleParticipationDecision(messageId: String, connectionId: String, tripId: String?, eventId: String?, userId: String, approve: Bool, requestType: String = "trip") {
        if approve {
            if let eid = eventId {
                db.collection(eventsCollection).document(eid).updateData([
                    "participants": FieldValue.arrayUnion([userId])
                ])
            } else if let tid = tripId {
                db.collection("trips").document(tid).updateData([
                    "participants": FieldValue.arrayUnion([userId])
                ])
            }
            db.collection(messagesCollection).document(messageId).updateData(["type": MessageType.participationAccepted.rawValue])
        } else {
            db.collection(messagesCollection).document(messageId).updateData(["type": MessageType.participationRejected.rawValue])
            db.collection(requestsCollection).document(connectionId).updateData(["status": ConnectionStatus.rejected.rawValue])
        }
    }
    
    func getMessages(for connectionId: String) -> [ChatMessage] {
        return allMessages.filter { $0.connectionId == connectionId }.sorted(by: { $0.timestamp < $1.timestamp })
    }
    
    func getUnreadCount(for connectionId: String) -> Int {
        guard let myId = Auth.auth().currentUser?.uid else { return 0 }
        return allMessages.filter { 
            $0.connectionId == connectionId && 
            $0.senderId != myId && 
            ($0.isRead == false || $0.isRead == nil) 
        }.count
    }
    
    func markMessagesAsRead(for connectionId: String, currentUserId: String) {
        let unreadMsgs = allMessages.filter { $0.connectionId == connectionId && $0.senderId != currentUserId && ($0.isRead == false || $0.isRead == nil) }
        
        for msg in unreadMsgs {
            db.collection(messagesCollection).document(msg.id).updateData(["isRead": true])
        }
    }
    
    func markRequestsAsRead() {
        let unreadReqs = (mySentRequests + myIncomingRequests).filter { $0.isRead == false }
        for req in unreadReqs {
            db.collection(requestsCollection).document(req.id).updateData(["isRead": true])
        }
    }
}
