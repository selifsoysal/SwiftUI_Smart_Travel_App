import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

final class AuthViewModel: ObservableObject {
    
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    private let db = DatabaseManager.shared
    private let userKey = "loggedInUser"

    init() {
        // Uygulama ilk açıldığında Firebase oturumunu kontrol et
        checkIfLoggedIn()
    }

    // MARK: - LOGIN
    func login(email: String, password: String) {
        errorMessage = nil
        if email.isEmpty || password.isEmpty {
            errorMessage = "Lütfen tüm alanları doldurun."
            return
        }
        
        isLoading = true
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            if let error = error {
                self.isLoading = false
                self.errorMessage = "Giriş hatası: \(error.localizedDescription)"
                return
            }
            
            guard let uid = authResult?.user.uid else {
                self.isLoading = false
                return
            }
            
            // Firestore'dan kullanıcı verilerini çek
            print("DEBUG: !!! Giriş Yapıldı, Firestore'dan kullanıcı aranıyor: \(uid) !!!")
            self.db.findUser(userId: uid) { user in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let user = user {
                        print("DEBUG: !!! Giriş Başarılı: \(user.name ?? "İsimsiz") !!!")
                        self.currentUser = user
                        self.isAuthenticated = true
                        self.saveUserToLocal(user)
                        
                        // Verileri yükle (Real-time dinleyicileri başlat)
                        SavedPlacesManager.shared.setupListener()
                        SavedTripsManager.shared.setupListener()
                        SocialManager.shared.loadSocialData(for: user.id)
                    } else {
                        print("DEBUG: !!! HATA: Giriş yapan kullanıcının verisi Firestore'da bulunamadı! !!!")
                        self.errorMessage = "Kullanıcı verileri bulunamadı."
                    }
                }
            }
        }
    }

    // MARK: - REGISTER
    func register(email: String, password: String, name: String, birthDate: Date, gender: String) {
        errorMessage = nil
        if email.isEmpty || password.isEmpty || name.isEmpty {
            errorMessage = "Lütfen tüm alanları doldurun."
            return
        }

        isLoading = true
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            if let error = error {
                self.isLoading = false
                self.errorMessage = "Kayıt hatası: \(error.localizedDescription)"
                return
            }
            
            guard let uid = authResult?.user.uid else {
                self.isLoading = false
                return
            }
            
            let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 18

            let newUser = User(
                id: uid,
                email: email,
                password: "", // Şifreyi Firestore'da tutmaya gerek yok
                name: name,
                age: age,
                gender: gender,
                profileWeights: [:], // Başlangıçta boş
                travelType: .solo,
                budget: .medium,
                isOnboardingCompleted: false
            )
            
            // Firestore'a kaydet
            self.db.saveUser(newUser) { error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let error = error {
                        self.errorMessage = "Profil oluşturulamadı: \(error.localizedDescription)"
                    } else {
                        self.currentUser = newUser
                        self.isAuthenticated = true
                        self.saveUserToLocal(newUser)
                        
                        SavedPlacesManager.shared.setupListener()
                        SavedTripsManager.shared.setupListener()
                        SocialManager.shared.loadSocialData(for: newUser.id)
                    }
                }
            }
        }
    }

    // MARK: - ONBOARDING COMPLETE
    func completeOnboarding(with weights: [String: Double], travelType: TravelType, budget: BudgetRange, companions: [Companion]) {
        guard var user = currentUser else { return }
        
        user.isOnboardingCompleted = true
        user.profileWeights = weights
        user.travelType = travelType
        user.budget = budget
        user.companions = companions
        
        self.currentUser = user
        self.saveUserToLocal(user)
        
        self.db.saveUser(user) { error in
            if let error = error {
                print("Onboarding güncelleme hatası: \(error.localizedDescription)")
            }
        }
    }

    func updateProfileImage(url: String) {
        guard var user = currentUser else { return }
        user.profileImageUrl = url
        self.currentUser = user
        self.saveUserToLocal(user)
        
        self.db.saveUser(user) { error in
            if let error = error {
                print("Profil fotoğrafı güncelleme hatası: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - LOGOUT
    func logout() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            isAuthenticated = false
            UserDefaults.standard.removeObject(forKey: userKey)
            
            DispatchQueue.main.async {
                AppRouter.shared.selectedTab = 0
                SavedPlacesManager.shared.setupListener()
                SavedTripsManager.shared.setupListener()
                // SocialManager dinleyicileri temizlenebilir (opsiyonel)
            }
        } catch {
            print("Çıkış hatası: \(error.localizedDescription)")
        }
    }

    // MARK: - PRIVATE METHODS
    private func saveUserToLocal(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userKey)
        }
    }

    private func checkIfLoggedIn() {
        if let firebaseUser = Auth.auth().currentUser {
            print("DEBUG: !!! Firebase Oturumu Açık: \(firebaseUser.uid) !!!")
            // Firebase'de oturum açık, Firestore'dan veriyi tazele
            db.findUser(userId: firebaseUser.uid) { [weak self] user in
                DispatchQueue.main.async {
                    if let user = user {
                        print("DEBUG: !!! Mevcut Kullanıcı Tazelendi: \(user.name ?? "İsimsiz") !!!")
                        self?.currentUser = user
                        self?.isAuthenticated = true
                        self?.saveUserToLocal(user)
                        
                        SavedPlacesManager.shared.setupListener()
                        SavedTripsManager.shared.setupListener()
                        SocialManager.shared.loadSocialData(for: user.id)
                    } else {
                        print("DEBUG: !!! UYARI: Oturum açık ama Firestore verisi bulunamadı! !!!")
                        self?.isAuthenticated = false
                    }
                }
            }
        } else {
            self.isAuthenticated = false
        }
    }
}
