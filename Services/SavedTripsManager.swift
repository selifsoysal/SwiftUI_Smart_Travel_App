import Foundation

@MainActor
class SavedTripsManager: ObservableObject {
    static let shared = SavedTripsManager()
    
    @Published var savedTrips: [GeminiTripPlan] = []
    
    private var tripsKey: String {
        guard let data = UserDefaults.standard.data(forKey: "loggedInUser"),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            return "com.smarttravel.savedTrips_guest"
        }
        return "com.smarttravel.savedTrips_\(user.id.uuidString)"
    }
    
    private init() {
        loadTrips()
    }
    
    func loadTrips() {
        guard let data = UserDefaults.standard.data(forKey: tripsKey) else {
            savedTrips = []
            return
        }
        do {
            let decoder = JSONDecoder()
            savedTrips = try decoder.decode([GeminiTripPlan].self, from: data)
        } catch {
            savedTrips = []
            print("Kayıtlı rotaları yüklerken hata oluştu: \(error)")
        }
    }
    
    // YENİ: Diğer kullanıcıların rotalarını sorgulamak için
    static func getTrips(for userId: UUID) -> [GeminiTripPlan] {
        let fetchKey = "com.smarttravel.savedTrips_\(userId.uuidString)"
        guard let data = UserDefaults.standard.data(forKey: fetchKey),
              let plans = try? JSONDecoder().decode([GeminiTripPlan].self, from: data) else {
            return []
        }
        return plans
    }
    
    func saveTrip(_ trip: GeminiTripPlan) {
        // Aynı rotanın ikinci kez eklenmesini önlemek için basit kontrol
        if !savedTrips.contains(where: { $0.id == trip.id }) {
            savedTrips.insert(trip, at: 0)
            persist()
        }
    }
    
    func deleteTrip(at offsets: IndexSet) {
        savedTrips.remove(atOffsets: offsets)
        persist()
    }
    
    private func persist() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(savedTrips)
            UserDefaults.standard.set(data, forKey: tripsKey)
        } catch {
            print("Rotaları kaydederken hata oluştu: \(error)")
        }
    }
}
