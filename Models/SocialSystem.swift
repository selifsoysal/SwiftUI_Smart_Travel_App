import Foundation

enum ConnectionStatus: String, Codable {
    case pending
    case accepted
    case rejected
}

struct ConnectionRequest: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    let senderId: String
    let receiverId: String
    var status: ConnectionStatus
    let timestamp: Date
    var tripId: String?
    var eventId: String?
    var tripDestination: String?
    var requestType: String? // "trip" or "event"
    var isRead: Bool? = true // Track if status change has been seen
}

enum MessageType: String, Codable {
    case text
    case participationRequest
    case participationAccepted
    case participationRejected
}

struct ChatMessage: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    let connectionId: String // Request ID
    let senderId: String
    let receiverId: String
    let text: String
    let timestamp: Date
    var isRead: Bool? = false
    var senderName: String? // Added for Group Chat
    var type: MessageType? = .text
    var matchScore: Int? // Added to store match score in requests
}
