import Foundation

final class AITripService {
    static let shared = AITripService()

    func suggestCity(for profile: TravelProfile) -> String {
        switch profile {
        case .food: return "Tokyo"
        case .nature: return "Switzerland"
        case .culture: return "Rome"
        case .luxury: return "Dubai"
        case .history: return "Athens"
        }
    }

    func generatePlan(city: String, days: Int, budget: String) -> TripPlan {
        var plans: [DayPlan] = []
        for day in 1...days {
            plans.append(DayPlan(day: day, activities: ["Explore \(city)", "Local food", "Sightseeing"]))
        }
        return TripPlan(city: city, days: days, dailyPlans: plans)
    }
}
