import Foundation

// Biz varolan TravelProfile ve BudgetRange'ı `Enums.swift` dosyasından kullanacağız.
// Bu yüzden özel TravelerBudget veya TravelerType kullanımdan kaldırıldı.

struct PlannedTrip: Codable, Identifiable {
    var id: UUID = UUID()
    var location: String
    var startDate: Date
    var endDate: Date
}

struct Traveler: Identifiable, Codable {
    var id: UUID = UUID()
    var username: String
    var age: Int
    var budget: BudgetRange
    var travelerType: TravelProfile
    var plannedTrips: [PlannedTrip]
    var bio: String?
}

struct MatchResult: Identifiable {
    var id: UUID = UUID()
    var traveler: Traveler
    var matchScore: Int // 0-100 percentage
}
