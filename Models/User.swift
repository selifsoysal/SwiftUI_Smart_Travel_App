import Foundation

struct User: Identifiable, Codable {
    let id: UUID
    var email: String
    var password: String
    var name: String
    var age: Int
    var gender: String
    
    // Enum kullanımları hatasızdır
    var travelProfile: TravelProfile?
    var travelType: TravelType
    var budget: BudgetRange
    var isOnboardingCompleted: Bool

    // Mock veriyi oluştururken enumların kendisini (.solo, .medium gibi) veriyoruz
    static let mock = User(
        id: UUID(),
        email: "test@example.com",
        password: "password123",
        name: "Gezgin",
        age: 22,
        gender: "Male",
        travelProfile: nil,
        travelType: .solo,
        budget: .medium,
        isOnboardingCompleted: false
    )
}
