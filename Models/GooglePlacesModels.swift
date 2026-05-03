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
}

struct PhotoDTO: Decodable {
    let photo_reference: String
}
