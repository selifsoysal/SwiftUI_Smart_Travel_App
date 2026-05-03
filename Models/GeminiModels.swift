import Foundation

// MARK: - App Models
// Bu model yapısı, doğrudan Gemini'den dönecek JSON formatıyla uyumlu olacak şekilde hazırlanmıştır.

struct GeminiTripPlan: Codable, Identifiable {
    var id: UUID = UUID()
    var startDate: Date?
    var endDate: Date?
    let selectedDestination: String
    let tripTitle: String
    let itinerary: [DailyItinerary]
    let generalTips: [String]
    
    // id alanını JSON parse ederken beklememek için CodingKeys tanımı:
    enum CodingKeys: String, CodingKey {
        case startDate
        case endDate
        case selectedDestination
        case tripTitle
        case itinerary
        case generalTips
    }
}

struct DailyItinerary: Codable, Identifiable {
    var id: UUID = UUID()
    let dayNumber: Int
    let dateDescription: String
    let activities: [Activity]
    
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
