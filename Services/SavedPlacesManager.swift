import Foundation

@MainActor
class SavedPlacesManager: ObservableObject {
    static let shared = SavedPlacesManager()
    
    @Published var savedPlaces: [Destination] = []
    
    private var placesKey: String {
        guard let data = UserDefaults.standard.data(forKey: "loggedInUser"),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            return "com.smarttravel.savedPlaces_guest"
        }
        return "com.smarttravel.savedPlaces_\(user.id.uuidString)"
    }
    
    private init() {
        loadPlaces()
    }
    
    func loadPlaces() {
        guard let data = UserDefaults.standard.data(forKey: placesKey) else {
            savedPlaces = []
            return
        }
        do {
            let decoder = JSONDecoder()
            savedPlaces = try decoder.decode([Destination].self, from: data)
        } catch {
            savedPlaces = []
            print("Kayıtlı mekanları yüklerken hata oluştu: \(error)")
        }
    }
    
    func toggleFavorite(_ destination: Destination) {
        if let index = savedPlaces.firstIndex(where: { $0.city == destination.city && $0.country == destination.country }) {
            savedPlaces.remove(at: index)
        } else {
            savedPlaces.insert(destination, at: 0)
        }
        persist()
    }
    
    func isFavorite(_ destination: Destination) -> Bool {
        return savedPlaces.contains(where: { $0.city == destination.city && $0.country == destination.country })
    }
    
    func deletePlace(at offsets: IndexSet) {
        savedPlaces.remove(atOffsets: offsets)
        persist()
    }
    
    private func persist() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(savedPlaces)
            UserDefaults.standard.set(data, forKey: placesKey)
        } catch {
            print("Mekanları kaydederken hata oluştu: \(error)")
        }
    }
}
