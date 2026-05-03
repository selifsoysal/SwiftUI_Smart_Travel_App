import Foundation

struct SwipeItem: Identifiable {
    let id = UUID()
    let title: String
    let imageUrl: String
    let tags: [Interest] // Kartın hangi ilgi alanına girdiği
}
