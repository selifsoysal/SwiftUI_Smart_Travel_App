import Foundation

struct Companion: Codable, Hashable {
    var age: Int
    var gender: String
}

struct User: Identifiable, Codable {
    var id: String
    var email: String?
    var password: String?
    var name: String?
    var age: Int?
    var gender: String?
    var companions: [Companion]? = []
    
    // Yüzdesel profil ağırlıkları (Örn: ["Doğa Sever": 0.6, "Kültür Kaşifi": 0.4])
    var profileWeights: [String: Double]?
    
    var travelType: TravelType?
    var budget: BudgetRange?
    var isOnboardingCompleted: Bool?
    var profileImageUrl: String?

    // Mock veriyi oluştururken enumların kendisini (.solo, .medium gibi) veriyoruz
    static let mock = User(
        id: "mock123",
        email: "selif@example.com",
        password: "password123",
        name: "Selif Soysal",
        age: 25,
        gender: "Kadın",
        profileWeights: ["Doğa Sever": 0.7, "Kültür Kaşifi": 0.3],
        travelType: .solo,
        budget: .medium,
        isOnboardingCompleted: true
    )
}
