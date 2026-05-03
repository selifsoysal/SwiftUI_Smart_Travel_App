import Foundation

struct Destination: Identifiable, Codable, Equatable {
    var id = UUID()
    let city: String
    let country: String
    let imageUrl: String
    let rating: Double
}
