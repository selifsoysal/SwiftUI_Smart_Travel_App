import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class SavedPlacesManager: ObservableObject {
    static let shared = SavedPlacesManager()
    
    @Published var savedPlaces: [Destination] = []
    private let db = Firestore.firestore()
    private let favoritesCollection = "favorites"
    private var listener: ListenerRegistration?
    
    private init() {
        setupListener()
    }
    
    func setupListener() {
        listener?.remove()
        
        guard let userId = Auth.auth().currentUser?.uid else {
            self.savedPlaces = []
            return
        }
        
        listener = db.collection(favoritesCollection)
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching favorites: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self.savedPlaces = documents.compactMap { doc -> Destination? in
                    try? doc.data(as: Destination.self)
                }
            }
    }
    
    func toggleFavorite(_ destination: Destination) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let docId = "\(userId)_\(destination.city)_\(destination.country)".replacingOccurrences(of: " ", with: "_")
        
        if isFavorite(destination) {
            db.collection(favoritesCollection).document(docId).delete()
        } else {
            var fav = destination
            fav.userId = userId
            try? db.collection(favoritesCollection).document(docId).setData(from: fav)
        }
    }
    
    func isFavorite(_ destination: Destination) -> Bool {
        return savedPlaces.contains(where: { $0.city == destination.city && $0.country == destination.country })
    }
    
    func deletePlace(at offsets: IndexSet) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        for index in offsets {
            let destination = savedPlaces[index]
            let docId = "\(userId)_\(destination.city)_\(destination.country)".replacingOccurrences(of: " ", with: "_")
            db.collection(favoritesCollection).document(docId).delete()
        }
    }
}
