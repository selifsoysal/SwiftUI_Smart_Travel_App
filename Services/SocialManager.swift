import Foundation
import Combine

@MainActor
class SocialManager: ObservableObject {
    static let shared = SocialManager()
    
    @Published var myIncomingRequests: [ConnectionRequest] = []
    @Published var mySentRequests: [ConnectionRequest] = []
    @Published var myConnections: [ConnectionRequest] = []
    
    @Published var allMessages: [ChatMessage] = []
    
    private let requestsKey = "global_connection_requests"
    private let messagesKey = "global_chat_messages"
    
    private init() {}
    
    // MARK: - Core Fetch
    func loadSocialData(for currentUserId: UUID) {
        let allReqs = getAllRequestsFromDB()
        
        myIncomingRequests = allReqs.filter { $0.receiverId == currentUserId && $0.status == .pending }
        mySentRequests = allReqs.filter { $0.senderId == currentUserId } // Hem pending hem accepted olanlar vs..
        
        myConnections = allReqs.filter {
            ($0.senderId == currentUserId || $0.receiverId == currentUserId) && $0.status == .accepted
        }.sorted { $0.timestamp > $1.timestamp }
        
        allMessages = getAllMessagesFromDB()
    }
    
    // MARK: - Connection Actions
    func sendRequest(from senderId: UUID, to receiverId: UUID) {
        var allReqs = getAllRequestsFromDB()
        
        // Zaten aynı kişiler arası bir istek var mı?
        if allReqs.contains(where: { ($0.senderId == senderId && $0.receiverId == receiverId) || ($0.senderId == receiverId && $0.receiverId == senderId) }) {
            return
        }
        
        let newReq = ConnectionRequest(senderId: senderId, receiverId: receiverId, status: .pending, timestamp: Date())
        allReqs.append(newReq)
        saveRequestsToDB(allReqs)
        
        loadSocialData(for: senderId)
    }
    
    func acceptRequest(requestId: UUID, currentUserId: UUID) {
        var allReqs = getAllRequestsFromDB()
        if let index = allReqs.firstIndex(where: { $0.id == requestId }) {
            allReqs[index].status = .accepted
            saveRequestsToDB(allReqs)
        }
        loadSocialData(for: currentUserId)
    }
    
    func rejectRequest(requestId: UUID, currentUserId: UUID) {
        var allReqs = getAllRequestsFromDB()
        if let index = allReqs.firstIndex(where: { $0.id == requestId }) {
            allReqs[index].status = .rejected
            saveRequestsToDB(allReqs)
        }
        loadSocialData(for: currentUserId)
    }
    
    func getRequestStatus(between userA: UUID, and userB: UUID) -> ConnectionStatus? {
        let allReqs = getAllRequestsFromDB()
        let req = allReqs.first {
            ($0.senderId == userA && $0.receiverId == userB) ||
            ($0.senderId == userB && $0.receiverId == userA)
        }
        return req?.status
    }
    
    func getActiveConnection(between userA: UUID, and userB: UUID) -> ConnectionRequest? {
        let allReqs = getAllRequestsFromDB()
        return allReqs.first {
            (($0.senderId == userA && $0.receiverId == userB) ||
             ($0.senderId == userB && $0.receiverId == userA)) && $0.status == .accepted
        }
    }
    
    // MARK: - Messaging
    func sendMessage(connectionId: UUID, senderId: UUID, receiverId: UUID, text: String) {
        var msgs = getAllMessagesFromDB()
        let newMsg = ChatMessage(connectionId: connectionId, senderId: senderId, receiverId: receiverId, text: text, timestamp: Date())
        msgs.append(newMsg)
        saveMessagesToDB(msgs)
        
        loadSocialData(for: senderId) // Refresh my cache
    }
    
    func getMessages(for connectionId: UUID) -> [ChatMessage] {
        return allMessages.filter { $0.connectionId == connectionId }.sorted(by: { $0.timestamp < $1.timestamp })
    }
    
    // MARK: - Database Helpers (UserDefaults)
    private func getAllRequestsFromDB() -> [ConnectionRequest] {
        guard let data = UserDefaults.standard.data(forKey: requestsKey),
              let reqs = try? JSONDecoder().decode([ConnectionRequest].self, from: data) else {
            return []
        }
        return reqs
    }
    
    private func saveRequestsToDB(_ reqs: [ConnectionRequest]) {
        if let encoded = try? JSONEncoder().encode(reqs) {
            UserDefaults.standard.set(encoded, forKey: requestsKey)
        }
    }
    
    private func getAllMessagesFromDB() -> [ChatMessage] {
        guard let data = UserDefaults.standard.data(forKey: messagesKey),
              let msgs = try? JSONDecoder().decode([ChatMessage].self, from: data) else {
            return []
        }
        return msgs
    }
    
    private func saveMessagesToDB(_ msgs: [ChatMessage]) {
        if let encoded = try? JSONEncoder().encode(msgs) {
            UserDefaults.standard.set(encoded, forKey: messagesKey)
        }
    }
}
