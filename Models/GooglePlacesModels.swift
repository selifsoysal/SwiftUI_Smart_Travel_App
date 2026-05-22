import Foundation

struct GooglePlacesResponse: Decodable {
    let results: [PlaceDTO]
    let status: String
}

struct PlaceDTO: Decodable {
    let name: String
    let rating: Double?
    let formatted_address: String?
    let photos: [PhotoDTO]?
    let geometry: GeometryDTO?
    let types: [String]?
}

struct GeometryDTO: Decodable {
    let location: LocationDTO
}

struct LocationDTO: Decodable {
    let lat: Double
    let lng: Double
}

struct PhotoDTO: Decodable {
    let photo_reference: String
}
