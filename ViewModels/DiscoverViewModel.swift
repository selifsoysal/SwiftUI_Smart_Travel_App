import Foundation

@MainActor
final class DiscoverViewModel: ObservableObject {

    @Published var destinations: [Destination] = []
    @Published var isLoading = false

    private let service = GooglePlacesService()

    func load() async {
        isLoading = true
        defer { isLoading = false }

        let cities = [
            "Paris",
            "Rome",
            "Barcelona",
            "Berlin",
            "Amsterdam",
            "Prague",
            "Vienna"
        ]

        var allResults: [Destination] = []

        await withTaskGroup(of: [Destination].self) { group in

            for city in cities {
                group.addTask { [service] in

                    var results: [Destination] = []

                    do {
                        let places = try await service.fetchPlaces(
                            query: "\(city) tourist attractions"
                        )

                        for place in places.prefix(3) {

                            guard
                                let photoRef = place.photos?.first?.photo_reference,
                                !photoRef.isEmpty
                            else {
                                continue
                            }

                            let imageUrl = service.photoURL(photoRef: photoRef)

                            let destination = Destination(
                                city: place.name,
                                country: place.formatted_address ?? city,
                                imageUrl: imageUrl,
                                rating: place.rating ?? 0
                            )

                            results.append(destination)
                        }

                    } catch {
                        print("Hata (\(city)): \(error)")
                    }

                    return results
                }
            }

            for await result in group {
                allResults.append(contentsOf: result)
            }
        }

        // rating + clean sorting
        self.destinations = allResults
            .sorted { $0.rating > $1.rating }
    }
}
