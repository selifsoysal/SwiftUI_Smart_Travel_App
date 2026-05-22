import Foundation
import FirebaseFirestore

struct ActivityEvent: Codable, Identifiable {
    var id: String?
    var hostId: String
    var hostName: String
    var hostAvatar: String?
    var hostProfileWeights: [String: Double]?
    var hostTravelType: String?
    var hostBudget: String?
    var hostAge: Int?
    var hostGender: String?
    var hostCompanions: [Companion]? = []
    
    var tripId: String
    var activityId: String
    var destination: String
    var placeName: String
    var dateDescription: String
    var timeOfDay: String
    var createdAt: Date
    var participants: [String]? = []
    var sharingMode: SharingMode? = .none
}

