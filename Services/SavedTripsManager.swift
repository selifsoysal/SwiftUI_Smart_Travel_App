import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class SavedTripsManager: ObservableObject {
    static let shared = SavedTripsManager()
    
    @Published var savedTrips: [GeminiTripPlan] = []
    private let db = Firestore.firestore()
    private let tripsCollection = "trips"
    private var listener: ListenerRegistration?
    
    private init() {
        setupListener()
    }
    
    func setupListener() {
        // Eski dinleyiciyi temizle
        listener?.remove()
        
        guard let userId = Auth.auth().currentUser?.uid else {
            self.savedTrips = []
            return
        }
        
        // Firestore'dan bu kullanıcının sahibi olduğu veya katılımcı olduğu rotaları dinle
        listener = db.collection(tripsCollection)
            .whereFilter(Filter.orFilter([
                Filter.whereField("userId", isEqualTo: userId),
                Filter.whereField("participants", arrayContains: userId)
            ]))
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching trips: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self.savedTrips = documents.compactMap { doc -> GeminiTripPlan? in
                    if var trip = try? doc.data(as: GeminiTripPlan.self) {
                        if trip.id == nil {
                            trip.id = doc.documentID
                        }
                        return trip
                    }
                    return nil
                }.sorted(by: { ($0.startDate ?? Date.distantPast) > ($1.startDate ?? Date.distantPast) })
            }
    }
    
    // Diğer kullanıcıların rotalarını sorgulamak için (Eşleştirme motoru için)
    static func getTrips(for userId: String) async -> [GeminiTripPlan] {
        let db = Firestore.firestore()
        print("DEBUG: Fetching trips for user: \(userId)")
        do {
            let snapshot = try await db.collection("trips")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            let trips = snapshot.documents.compactMap { doc -> GeminiTripPlan? in
                do {
                    var trip = try doc.data(as: GeminiTripPlan.self)
                    if trip.id == nil {
                        trip.id = doc.documentID
                    }
                    return trip.isPublic == true ? trip : nil
                } catch {
                    print("DEBUG: Decoding error for trip \(doc.documentID): \(error)")
                    return nil
                }
            }
            print("DEBUG: Found \(trips.count) trips for user \(userId)")
            return trips
        } catch {
            print("DEBUG: Error fetching trips for user \(userId): \(error)")
            return []
        }
    }
    
    static func getAllTripsGlobal() async -> [GeminiTripPlan] {
        let db = Firestore.firestore()
        do {
            let snapshot = try await db.collection("trips").getDocuments()
            let trips = snapshot.documents.compactMap { doc -> GeminiTripPlan? in
                var trip = try? doc.data(as: GeminiTripPlan.self)
                if trip?.id == nil {
                    trip?.id = doc.documentID
                }
                return trip?.isPublic == true ? trip : nil
            }
            return trips
        } catch {
            print("DEBUG: Error fetching all trips globally: \(error)")
            return []
        }
    }
    
    static func getTrip(byId id: String) async -> GeminiTripPlan? {
        let db = Firestore.firestore()
        do {
            let doc = try await db.collection("trips").document(id).getDocument()
            return try doc.data(as: GeminiTripPlan.self)
        } catch {
            print("DEBUG: Error fetching trip with id \(id): \(error)")
            return nil
        }
    }
    
    func saveTrip(_ trip: GeminiTripPlan, user: User?) {
        var newTrip = trip
        newTrip.userId = user?.id
        newTrip.creatorName = user?.name
        newTrip.creatorAvatar = user?.profileImageUrl
        
        // Kullanıcı metadata'larını ekle
        newTrip.creatorProfileWeights = user?.profileWeights
        newTrip.creatorTravelType = user?.travelType?.rawValue
        newTrip.creatorBudget = user?.budget?.rawValue
        newTrip.creatorAge = user?.age
        newTrip.creatorGender = user?.gender
        newTrip.creatorCompanions = user?.companions


        
        // Eğer ID yoksa (AI'dan yeni geldiyse) yeni bir ID oluştur
        if newTrip.id == nil {
            newTrip.id = UUID().uuidString
        }
        
        guard let tripId = newTrip.id else { return }
        
        print("DEBUG: Saving trip to Firestore: \(newTrip.tripTitle)")
        do {
            // Eğer döküman varsa, katılımcıları korumak için participants alanını merge etmiyoruz, 
            // ama saveTrip genellikle yeni kaydetme veya tam güncelleme için kullanılır.
            try db.collection(tripsCollection).document(tripId).setData(from: newTrip, merge: true)
            print("DEBUG: Trip saved successfully!")
        } catch {
            print("DEBUG: Error saving trip: \(error)")
        }
    }
    
    func updateTripPublicStatus(tripId: String, isPublic: Bool) {
        db.collection(tripsCollection).document(tripId).updateData(["isPublic": isPublic])
    }

    func updateTripSharingMode(tripId: String, mode: SharingMode) {
        db.collection(tripsCollection).document(tripId).updateData([
            "sharingMode": mode.rawValue,
            "isPublic": (mode == .fullTrip)
        ])
    }

    
    func deleteTrip(_ trip: GeminiTripPlan) {
        guard let id = trip.id else { return }
        db.collection(tripsCollection).document(id).delete() { error in
            if let error = error {
                print("DEBUG: Error deleting trip: \(error.localizedDescription)")
            }
        }
    }

    func deleteTrip(at offsets: IndexSet) {
        for index in offsets {
            if let tripId = savedTrips[index].id {
                db.collection(tripsCollection).document(tripId).delete()
            }
        }
    }
    
    func updateTrip(_ trip: GeminiTripPlan) {
        guard let id = trip.id else { return }
        do {
            try db.collection(tripsCollection).document(id).setData(from: trip)
            print("DEBUG: Trip updated successfully")
        } catch {
            print("DEBUG: Error updating trip: \(error.localizedDescription)")
        }
    }
}
