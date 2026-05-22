import Foundation

struct Destination: Identifiable, Codable, Equatable {
    var id = UUID()
    var userId: String? // Firebase ID
    let city: String
    let country: String
    let imageUrl: String
    let rating: Double
    var interests: [String: Double]? = [:] // Profil ağırlıklarıyla uyumlu ilgi alanları
    var matchPercentage: Int?
}


