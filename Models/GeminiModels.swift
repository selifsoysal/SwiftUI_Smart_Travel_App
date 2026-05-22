import Foundation

// MARK: - App Models
// Bu model yapısı, doğrudan Gemini'den dönecek JSON formatıyla uyumlu olacak şekilde hazırlanmıştır.

struct GeminiTripPlan: Codable, Identifiable {
    var id: String? // Firestore document ID
    var userId: String? // Firebase User ID
    var startDate: Date?
    var endDate: Date?
    var selectedDestination: String
    var tripTitle: String
    var itinerary: [DailyItinerary]
    var generalTips: [String]
    var isPublic: Bool? = false
    var creatorName: String?
    var creatorAvatar: String?
    var creatorProfileWeights: [String: Double]?
    var creatorTravelType: String?
    var creatorBudget: String?
    var creatorAge: Int?
    var creatorGender: String?
    var creatorCompanions: [Companion]? = []
    var participants: [String]? = [] // Array of User IDs
    var sharingMode: SharingMode? = .none
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case startDate
        case endDate
        case selectedDestination
        case tripTitle
        case itinerary
        case generalTips
        case isPublic
        case creatorName
        case creatorAvatar
        case creatorProfileWeights
        case creatorTravelType
        case creatorBudget
        case creatorAge
        case creatorGender
        case creatorCompanions
        case participants
        case sharingMode
    }
}


struct DailyItinerary: Codable, Identifiable {
    var id: UUID = UUID()
    let dayNumber: Int
    let dateDescription: String
    var activities: [Activity]
    
    enum CodingKeys: String, CodingKey {
        case dayNumber
        case dateDescription
        case activities
    }
}

struct Activity: Codable, Identifiable {
    var id: UUID = UUID()
    let timeOfDay: String
    let placeName: String
    let description: String
    let estimatedLat: Double
    let estimatedLng: Double
    let costCategory: String
    
    enum CodingKeys: String, CodingKey {
        case timeOfDay
        case placeName
        case description
        case estimatedLat
        case estimatedLng
        case costCategory
    }
}
