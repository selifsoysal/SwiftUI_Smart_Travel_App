import Foundation

final class UnsplashService {
    
    private let accessKey = "YOUR_UNSPLASH_KEY"
    
    func fetchImage(for city: String) async throws -> String {
        let query = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
        
        let urlString = "https://api.unsplash.com/search/photos?query=\(query)&per_page=1&client_id=\(accessKey)"
        
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let decoded = try JSONDecoder().decode(UnsplashResponse.self, from: data)
        
        return decoded.results.first?.urls.regular ?? ""
    }
}

// DTO
struct UnsplashResponse: Decodable {
    let results: [Photo]
}

struct Photo: Decodable {
    let urls: PhotoURL
}

struct PhotoURL: Decodable {
    let regular: String
}
