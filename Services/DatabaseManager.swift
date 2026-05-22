import Foundation
import FirebaseFirestore

class DatabaseManager {
    static let shared = DatabaseManager()
    private let db = Firestore.firestore()
    private let usersCollection = "users"

    func getAllUsers(completion: @escaping ([User]) -> Void) {
        print("DEBUG: Fetching all users from Firestore...")
        db.collection(usersCollection).getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, error == nil else {
                print("DEBUG: Error fetching users: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }
            
            print("DEBUG: Found \(documents.count) user documents in Firestore.")
            let users = documents.compactMap { doc -> User? in
                do {
                    return try doc.data(as: User.self)
                } catch {
                    print("DEBUG: Decoding error for user \(doc.documentID): \(error)")
                    return nil
                }
            }
            print("DEBUG: Successfully decoded \(users.count) users.")
            completion(users)
        }
    }

    func saveUser(_ user: User, completion: @escaping (Error?) -> Void) {
        print("DEBUG: Saving user \(user.id) to Firestore...")
        do {
            try db.collection(usersCollection).document(user.id).setData(from: user, completion: completion)
        } catch {
            print("DEBUG: Exception saving user: \(error)")
            completion(error)
        }
    }

    func findUser(userId: String, completion: @escaping (User?) -> Void) {
        print("DEBUG: Finding user \(userId) in Firestore...")
        db.collection(usersCollection).document(userId).getDocument { snapshot, error in
            guard let snapshot = snapshot, snapshot.exists, error == nil else {
                print("DEBUG: User \(userId) not found or error: \(error?.localizedDescription ?? "None")")
                completion(nil)
                return
            }
            do {
                let user = try snapshot.data(as: User.self)
                completion(user)
            } catch {
                print("DEBUG: Decoding error for found user \(userId): \(error)")
                completion(nil)
            }
        }
    }
    
    // MARK: - Activity Events
    private let eventsCollection = "activity_events"
    
    func saveEvent(_ event: ActivityEvent, completion: @escaping (Error?) -> Void) {
        do {
            let ref = db.collection(eventsCollection).document()
            var newEvent = event
            newEvent.id = ref.documentID
            try ref.setData(from: newEvent, completion: completion)
        } catch {
            completion(error)
        }
    }
    
    func fetchUpcomingEvents(completion: @escaping ([ActivityEvent]) -> Void) {
        db.collection(eventsCollection)
            .order(by: "createdAt", descending: true)
            .limit(to: 20)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents, error == nil else {
                    completion([])
                    return
                }
                let events = documents.compactMap { doc -> ActivityEvent? in
                    var event = try? doc.data(as: ActivityEvent.self)
                    event?.id = doc.documentID
                    return event
                }
                completion(events)
            }
    }
    
    func fetchUserEvents(userId: String, completion: @escaping ([ActivityEvent]) -> Void) {
        db.collection(eventsCollection)
            .whereFilter(Filter.orFilter([
                Filter.whereField("hostId", isEqualTo: userId),
                Filter.whereField("participants", arrayContains: userId)
            ]))
            .getDocuments { snapshot, error in
                if let error = error {
                    print("DEBUG: Error fetching user events: \(error.localizedDescription)")
                    completion([])
                    return
                }
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                let events = documents.compactMap { doc -> ActivityEvent? in
                    var event = try? doc.data(as: ActivityEvent.self)
                    event?.id = doc.documentID
                    return event
                }
                .sorted(by: { $0.createdAt > $1.createdAt })
                completion(events)
            }
    }
    
    func leaveEvent(eventId: String, userId: String, completion: @escaping (Error?) -> Void) {
        db.collection(eventsCollection).document(eventId).updateData([
            "participants": FieldValue.arrayRemove([userId])
        ]) { error in
            completion(error)
        }
    }
    
    func deleteEvent(eventId: String, completion: @escaping (Error?) -> Void) {
        print("DEBUG: Deleting event with ID: \(eventId)")
        db.collection(eventsCollection).document(eventId).delete { error in
            if let error = error {
                print("DEBUG: Error deleting event: \(error.localizedDescription)")
            } else {
                print("DEBUG: Event deleted successfully!")
            }
            completion(error)
        }
    }
    
    func updateEvent(_ event: ActivityEvent, completion: @escaping (Error?) -> Void) {
        guard let id = event.id else {
            completion(NSError(domain: "DatabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Event ID missing"]))
            return
        }
        do {
            try db.collection(eventsCollection).document(id).setData(from: event, completion: completion)
        } catch {
            completion(error)
        }
    }
}
