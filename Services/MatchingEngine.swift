import Foundation

class MatchingEngine {
    
    /// Calculate match score based only on Budget and Traveler Type (50% each).
    /// Location and Dates act as MUST-HAVE filters (±3 days). Returns 0 if filters fail.
    static func calculateScore(currentUser: User, candidate: Traveler, currentUserTrips: [GeminiTripPlan]) -> Int {
        var passesFilter = false
        
        let calendar = Calendar.current
        
        // 1. HARD FILTER: Location + Date Overlap (±3 days)
        for userTrip in currentUserTrips {
            guard let userStart = userTrip.startDate, let userEnd = userTrip.endDate else { continue }
            
            for candidateTrip in candidate.plannedTrips {
                // Lokasyon kontrolü
                if candidateTrip.location.caseInsensitiveCompare(userTrip.selectedDestination) == .orderedSame || userTrip.selectedDestination.lowercased().contains(candidateTrip.location.lowercased()) {
                    
                    // Tarih kontrolü (±3 gün tolerans ile çakışma kontrolü)
                    // Toleranslı aralıklar
                    guard let toleratedStart = calendar.date(byAdding: .day, value: -3, to: userStart),
                          let toleratedEnd = calendar.date(byAdding: .day, value: 3, to: userEnd) else { continue }
                    
                    // İki zaman aralığının (A ve B) kesişmesi için -> A'nın başlangıcı <= B'nin bitişi && A'nın bitişi >= B'nin başlangıcı
                    if toleratedStart <= candidateTrip.endDate && toleratedEnd >= candidateTrip.startDate {
                        passesFilter = true
                        break
                    }
                }
            }
            if passesFilter { break }
        }
        
        if !passesFilter {
            return 0 // Ortak lokasyon/tarih yoksa eşleşme olmaz
        }
        
        print("🔍 [MatchingEngine] Filtreyi geçti: \(currentUser.name) <=> \(candidate.username)")
        
        var totalScore: Double = 0.0
        
        // 2. Budget (50 Puan)
        // Aynı -> 50, Yakın -> 35, Farklı -> 15
        if currentUser.budget == candidate.budget {
            totalScore += 50.0
        } else if (currentUser.budget == .low && candidate.budget == .medium) ||
                    (currentUser.budget == .medium && candidate.budget == .low) ||
                    (currentUser.budget == .medium && candidate.budget == .high) ||
                    (currentUser.budget == .high && candidate.budget == .medium) {
            totalScore += 35.0
        } else {
            totalScore += 15.0
        }
        
        // 3. Gezgin Tipi (50 Puan)
        // Aynı -> 50, Benzer/Ortak -> 35, Zıt -> 15 (Basit mantıkla aynıysa 50 değilse 35 verdik)
        if let currentProfile = currentUser.travelProfile {
            if currentProfile == candidate.travelerType {
                totalScore += 50.0
            } else {
                totalScore += 35.0
            }
        } else {
            totalScore += 35.0 // Profil seçilmemişse kısmi puan
        }
        
        let finalScore = min(100, Int(totalScore))
        print("✅ [MatchingEngine] \(candidate.username) için Toplam Eşleşme Puanı: %\(finalScore)")
        
        return finalScore
    }
}
