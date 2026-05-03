import Foundation

struct TripPlan: Identifiable {
    let id = UUID()
    let city: String
    let days: Int
    let dailyPlans: [DayPlan]
}

struct DayPlan: Identifiable {
    let id = UUID()
    let day: Int
    let activities: [String]
}
