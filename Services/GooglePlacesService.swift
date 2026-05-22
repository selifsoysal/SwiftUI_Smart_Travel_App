import Foundation

final class GooglePlacesService {

    private let apiKey = Config.googleAPIKey

    func fetchPlaces(query: String) async throws -> [PlaceDTO] {

        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let url = URL(string:
            "https://maps.googleapis.com/maps/api/place/textsearch/json?query=\(encoded)&key=\(apiKey)"
        )!

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return []
        }

        let decoded = try JSONDecoder().decode(GooglePlacesResponse.self, from: data)

        guard decoded.status == "OK" else {
            return []
        }

        return decoded.results
    }

    /// Search specifically for cities/countries (type=locality|country)
    func fetchCities(query: String) async throws -> [PlaceDTO] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let url = URL(string:
            "https://maps.googleapis.com/maps/api/place/textsearch/json?query=\(encoded)&type=locality&key=\(apiKey)"
        )!

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return [] }
        let decoded = try JSONDecoder().decode(GooglePlacesResponse.self, from: data)
        guard decoded.status == "OK" else { return [] }
        return decoded.results
    }

    func photoURL(photoRef: String) -> String {
        "https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photo_reference=\(photoRef)&key=\(apiKey)"
    }
}
