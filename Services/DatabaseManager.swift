import Foundation

class DatabaseManager {
    static let shared = DatabaseManager()
    private let userKey = "saved_users"

    func getAllUsers() -> [User] {
        guard let data = UserDefaults.standard.data(forKey: userKey),
              let users = try? JSONDecoder().decode([User].self, from: data) else {
            return []
        }
        return users
    }

    func saveUser(_ user: User) {
        var users = getAllUsers()
        if let index = users.firstIndex(where: { $0.email.lowercased() == user.email.lowercased() }) {
            users[index] = user
        } else {
            users.append(user)
        }
        if let encoded = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(encoded, forKey: userKey)
        }
    }

    func findUser(email: String) -> User? {
        return getAllUsers().first(where: { $0.email.lowercased() == email.lowercased() })
    }
}
