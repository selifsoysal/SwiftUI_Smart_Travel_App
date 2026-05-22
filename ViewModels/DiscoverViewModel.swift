import Foundation
import FirebaseAuth

@MainActor
final class DiscoverViewModel: ObservableObject {

    @Published var trendingDestinations: [Destination] = []
    @Published var recommendedDestinations: [Destination] = []
    @Published var activeEvents: [ActivityEvent] = []
    @Published var isLoading = false
    @Published var selectedCategory: String = "Tümü"
    @Published var searchText: String = ""

    @Published var searchResults: [Destination] = []
    @Published var isSearching = false

    var filteredRecommended: [Destination] {
        if searchText.isEmpty { return recommendedDestinations }
        // If live search results exist, don't double-show recommended
        return searchResults.isEmpty ? recommendedDestinations.filter {
            $0.city.localizedCaseInsensitiveContains(searchText) ||
            $0.country.localizedCaseInsensitiveContains(searchText)
        } : []
    }

    var filteredTrending: [Destination] {
        if searchText.isEmpty { return trendingDestinations }
        if !searchResults.isEmpty { return searchResults }
        return trendingDestinations.filter {
            $0.city.localizedCaseInsensitiveContains(searchText) ||
            $0.country.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    let categories = ["Tümü", "🌊 Deniz & Kum", "🏛️ Tarih & Kültür", "⛰️ Doğa", "🍷 Gastronomi", "🏂 Kış Sporları"]
    
    private let categoryCities: [String: [String]] = [
        "🌊 Deniz & Kum": ["Maldives", "Antalya", "Santorini", "Phuket"],
        "🏛️ Tarih & Kültür": ["Rome", "Athens", "Kyoto", "Istanbul"],
        "⛰️ Doğa": ["Swiss Alps", "Banff", "Cappadocia", "Patagonia"],
        "🍷 Gastronomi": ["Paris", "Bologna", "Tokyo", "Oaxaca"],
        "🏂 Kış Sporları": ["Zermatt", "Whistler", "Chamonix", "Aspen"],
        "Tümü": ["Cappadocia", "Barcelona", "Bali", "Kyoto", "New York", "Rome", "Paris"]
    ]
    
    private let service = GooglePlacesService()

    func load(currentUser: User?) async {
        isLoading = true
        defer { isLoading = false }

        let allTrips = await SavedTripsManager.getAllTripsGlobal()
        let currentUserId = Auth.auth().currentUser?.uid
        
        // 1. Trending Destinations
        var destinationCounts: [String: Int] = [:]
        for trip in allTrips {
            let dest = trip.selectedDestination.trimmingCharacters(in: .whitespacesAndNewlines)
            if !dest.isEmpty && dest.lowercased() != "belirtilmemiş" && dest.lowercased() != "gizemli" {
                destinationCounts[dest, default: 0] += 1
            }
        }
        
        let sortedDestinations = destinationCounts.sorted { $0.value > $1.value }.map { $0.key }
        var topDestinations = Array(sortedDestinations.prefix(5))
        
        if topDestinations.isEmpty {
            topDestinations = ["Paris", "Rome", "London", "Tokyo"]
        }
        
        var trending: [Destination] = []
        await withTaskGroup(of: Destination?.self) { group in
            for city in topDestinations {
                group.addTask { [service] in
                    do {
                        let places = try await service.fetchPlaces(query: "\(city) tourist attractions")
                        if let place = places.first, let photoRef = place.photos?.first?.photo_reference {
                            let imageUrl = service.photoURL(photoRef: photoRef)
                            var dest = Destination(city: city, country: place.formatted_address ?? "", imageUrl: imageUrl, rating: place.rating ?? 5.0)
                            dest.interests = await NeuralMatchingEngine.shared.analyzeCityWithPlaces(city: city)

                            return dest

                        }
                    } catch {
                        print("Error fetching places for \(city): \(error)")
                    }
                    return nil
                }
            }
            
            for await dest in group {
                if let dest = dest {
                    trending.append(dest)
                }
            }
        }
        self.trendingDestinations = trending.sorted { $0.rating > $1.rating }
        
        // 2. Recommended based on profile & category
        await fetchRecommended(for: "Tümü", currentUser: currentUser)
        
        // 3. Fetch Activity Events
        DatabaseManager.shared.fetchUpcomingEvents { [weak self] events in
            guard let self = self else { return }
            let othersEvents = events.filter { $0.hostId != currentUserId }
            Task { @MainActor in
                self.activeEvents = othersEvents
            }
        }
    }
    
    func fetchRecommended(for category: String, currentUser: User?) async {
        let sourceCities: [String]
        if category == "Tümü" {
            let allPotentialCities = categoryCities.values.flatMap { $0 } + ["Paris", "Tokyo", "Rome", "Bali", "New York", "London", "Istanbul", "Cape Town", "Sydney"]
            sourceCities = Array(Set(allPotentialCities))
        } else {
            sourceCities = categoryCities[category] ?? []
        }
        
        var recommended: [Destination] = []
        
        await withTaskGroup(of: Destination?.self) { group in
            for city in sourceCities {
                group.addTask { [service] in
                    // 1. Şehrin ilgi alanlarını Google Places 'types' verisi ile analiz et (KOTA DOSTU)
                    let interests = await NeuralMatchingEngine.shared.analyzeCityWithPlaces(city: city)
                    
                    // 2. Kullanıcı ile uyum puanını hesapla (Noktasal Çarpım / Dot Product)
                    let matchScore: Int? = currentUser.map { 
                        NeuralMatchingEngine.shared.calculateRecommendationScore(user: $0, cityInterests: interests)
                    }
                    
                    // 3. Görsel ve detayları çek
                    do {
                        let places = try await service.fetchPlaces(query: "\(city) tourist attractions")
                        if let place = places.first, let photoRef = place.photos?.first?.photo_reference {
                            let imageUrl = service.photoURL(photoRef: photoRef)
                            var dest = Destination(city: city, country: place.formatted_address ?? "", imageUrl: imageUrl, rating: place.rating ?? 5.0)
                            dest.interests = interests
                            dest.matchPercentage = matchScore
                            return dest
                        }
                    } catch { }
                    return nil
                }
            }
            
            for await dest in group {
                if let dest = dest { recommended.append(dest) }
            }
        }
        
        // Sıralama: Match Percentage (Varsa) -> Rating
        let sorted = recommended.sorted { 
            let m1 = $0.matchPercentage ?? 0
            let m2 = $1.matchPercentage ?? 0
            if m1 != m2 { return m1 > m2 }
            return $0.rating > $1.rating
        }
        
        await MainActor.run {
            self.recommendedDestinations = Array(sorted.prefix(8))
        }
    }
    


    
    /// Searches cities/countries via the Places API — results are real places, not POIs.
    func searchDestinations(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            self.searchResults = []
            return
        }
        isSearching = true
        defer { isSearching = false }

        do {
            let places = try await service.fetchCities(query: query)
            var results: [Destination] = []
            for place in places.prefix(6) {
                let city = place.name
                // Extract just the country from the last component of formatted_address
                let country = place.formatted_address?
                    .components(separatedBy: ", ")
                    .last ?? ""
                let imageUrl: String
                if let photoRef = place.photos?.first?.photo_reference {
                    imageUrl = service.photoURL(photoRef: photoRef)
                } else {
                    imageUrl = ""
                }
                results.append(Destination(city: city, country: country, imageUrl: imageUrl, rating: place.rating ?? 4.5))
            }
            self.searchResults = results
        } catch {
            print("City search error: \(error)")
            self.searchResults = []
        }
    }
}
