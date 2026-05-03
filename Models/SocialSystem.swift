import Foundation

enum ConnectionStatus: String, Codable {
    case pending
    case accepted
    case rejected
}

struct ConnectionRequest: Identifiable, Codable {
    var id: UUID = UUID()
    let senderId: UUID
    let receiverId: UUID
    var status: ConnectionStatus
    let timestamp: Date
    
    // Uygulama local db ile çalıştığı için cache adına isimleri de kaydedebiliriz
    // fakat User objelerinden Id'ler ile fetch edilmesi daha güvenlidir.
}

struct ChatMessage: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    let connectionId: UUID // Request ID
    let senderId: UUID
    let receiverId: UUID
    let text: String
    let timestamp: Date
}
