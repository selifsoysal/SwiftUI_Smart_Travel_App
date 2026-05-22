import Foundation

// Biz varolan TravelProfile ve BudgetRange'ı `Enums.swift` dosyasından kullanacağız.
// Bu yüzden özel TravelerBudget veya TravelerType kullanımdan kaldırıldı.

struct PlannedTrip: Codable, Identifiable {
    var id: UUID = UUID()
    var tripId: String?
    var location: String
    var startDate: Date
    var endDate: Date
}

struct Traveler: Identifiable, Codable {
    var id: String
    var username: String
    var age: Int
    var gender: String?
    var budget: BudgetRange
    var travelType: TravelType? = .solo
    var profileWeights: [String: Double]?
    var companions: [Companion]? = []
    var plannedTrips: [PlannedTrip]
    var bio: String?
}

struct MatchResult: Identifiable {
    var id: UUID = UUID()
    var traveler: Traveler
    var matchScore: Int // 0-100 percentage
    var explanations: [String] = []
}
