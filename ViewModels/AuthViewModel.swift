import Foundation
import SwiftUI

final class AuthViewModel: ObservableObject {
    
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    private let db = DatabaseManager.shared
    private let userKey = "loggedInUser"

    init() {
        // Uygulama ilk açıldığında yerel veriyi kontrol et
        loadUserFromStorage()
    }

    // MARK: - LOGIN
    func login(email: String, password: String) {
        errorMessage = nil
        guard validateFields(email: email, password: password) else { return }
        
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            
            if let user = self.db.findUser(email: email) {
                if user.password == password {
                    self.currentUser = user
                    self.isAuthenticated = true // Giriş başarılı
                    self.saveUserToStorage(user) // Veriyi kalıcı hale getir
                    
                    // Geçiş yapıldıktan sonra o kullanıcıya özel favorileri/rotaları belleğe al
                    DispatchQueue.main.async {
                        SavedPlacesManager.shared.loadPlaces()
                        SavedTripsManager.shared.loadTrips()
                    }
                } else {
                    self.errorMessage = "Hatalı şifre girdiniz."
                }
            } else {
                self.errorMessage = "Bu e-posta ile kullanıcı bulunamadı."
            }
        }
    }

    // MARK: - REGISTER
    func register(email: String, password: String, name: String, birthDate: Date) {
        errorMessage = nil
        guard validateFields(email: email, password: password) else { return }
        guard !name.isEmpty else {
            errorMessage = "Lütfen adınızı girin."
            return
        }

        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            
            if self.db.findUser(email: email) != nil {
                self.errorMessage = "Bu e-posta zaten kullanımda."
                return
            }

            let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 18

            let newUser = User(
                id: UUID(),
                email: email,
                password: password,
                name: name,
                age: age,
                gender: "Belirtilmemiş",
                travelProfile: nil,
                travelType: .solo,
                budget: .medium,
                isOnboardingCompleted: false
            )
            
            self.db.saveUser(newUser)
            self.currentUser = newUser
            self.isAuthenticated = true
            self.saveUserToStorage(newUser)
            
            // Geçiş yapıldıktan sonra yeni kullanıcı için boş dizileri hafızaya al
            DispatchQueue.main.async {
                SavedPlacesManager.shared.loadPlaces()
                SavedTripsManager.shared.loadTrips()
            }
        }
    }

    // MARK: - ONBOARDING COMPLETE
    func completeOnboarding(with profile: TravelProfile) {
        guard var user = currentUser else { return }
        
        // Durumu güncelle
        user.isOnboardingCompleted = true
        user.travelProfile = profile
        
        // Hem hafızayı hem de depolamayı güncelle
        self.currentUser = user
        self.saveUserToStorage(user)
        self.db.saveUser(user) // Eğer DB yapında güncellenmiş kullanıcıyı kaydetme varsa
    }

    // MARK: - LOGOUT
    func logout() {
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: userKey)
        
        // Çıkış yapınca Singletons hafızasından başkasının verisini temizle
        DispatchQueue.main.async {
            SavedPlacesManager.shared.loadPlaces()
            SavedTripsManager.shared.loadTrips()
        }
    }

    // MARK: - VALIDATION & STORAGE
    private func validateFields(email: String, password: String) -> Bool {
        if email.isEmpty || password.isEmpty {
            errorMessage = "Lütfen tüm alanları doldurun."
            return false
        }
        return true
    }

    private func saveUserToStorage(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userKey)
        }
    }

    private func loadUserFromStorage() {
        guard let data = UserDefaults.standard.data(forKey: userKey),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            // Kullanıcı yoksa varsayılan durumlar
            self.isAuthenticated = false
            self.currentUser = nil
            return
        }
        
        // Kullanıcı bilgisini bellekte tut (login için pratiklik sağlayabilir)
        self.currentUser = user
        
        // HER AÇILIŞTA GİRİŞ EKRANI İSTENDİĞİ İÇİN OTOMATİK LOGİN KAPATILDI
        self.isAuthenticated = false 
    }
}
