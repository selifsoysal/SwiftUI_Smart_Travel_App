import Foundation

class MatchingEngine {
    
    static func calculateScore(currentUser: User, candidate: Traveler, currentUserTrips: [GeminiTripPlan]) -> Int {
        // 1. Lokasyon ve Tarih Çakışması (ÖN ŞART)
        let overlappingTrips = findOverlappingTrips(myTrips: currentUserTrips, theirTrips: candidate.plannedTrips)
        
        // Eğer ortak bir lokasyon/tarih yoksa direkt 0 döndür
        if overlappingTrips.isEmpty {
            return 0
        }
        
        var totalScore = 40.0 // Lokasyon eşleştiği için başlangıç puanı
        
        // 2. Profil Benzerliği (%40 Ağırlık)
        if let myWeights = currentUser.profileWeights, let theirWeights = candidate.profileWeights {
            var similarity: Double = 0
            for (profile, weight) in myWeights {
                if let candidateWeight = theirWeights[profile] {
                    similarity += weight * candidateWeight
                }
            }
            totalScore += similarity * 40.0
        } else {
            totalScore += 20.0
        }
        
        // 3. Bütçe Uyumu (%10 Ağırlık)
        if currentUser.budget == candidate.budget {
            totalScore += 10.0
        } else if isBudgetCompatible(currentUser.budget, candidate.budget) {
            totalScore += 5.0
        }
        
        // 4. Yaş Uyumu (%10 Ağırlık)
        let ageDiff = abs((currentUser.age ?? 25) - candidate.age)
        if ageDiff <= 5 {
            totalScore += 10.0
        } else if ageDiff <= 12 {
            totalScore += 5.0
        }
        
        let finalScore = Int(min(totalScore, 100.0))
        print("✅ [MatchingEngine] \(candidate.username) için Eşleşme Puanı: %\(finalScore)")
        return finalScore
    }
    
    private static func findOverlappingTrips(myTrips: [GeminiTripPlan], theirTrips: [PlannedTrip]) -> [PlannedTrip] {
        var overlaps: [PlannedTrip] = []
        let calendar = Calendar.current
        
        for myTrip in myTrips {
            guard let myStart = myTrip.startDate, let myEnd = myTrip.endDate else { continue }
            
            for theirTrip in theirTrips {
                // Lokasyon kontrolü
                if theirTrip.location.caseInsensitiveCompare(myTrip.selectedDestination) == .orderedSame || 
                    myTrip.selectedDestination.lowercased().contains(theirTrip.location.lowercased()) {
                    
                    // ±3 gün toleranslı tarih kontrolü
                    guard let toleratedStart = calendar.date(byAdding: .day, value: -3, to: myStart),
                          let toleratedEnd = calendar.date(byAdding: .day, value: 3, to: myEnd) else { continue }
                    
                    if toleratedStart <= theirTrip.endDate && toleratedEnd >= theirTrip.startDate {
                        overlaps.append(theirTrip)
                    }
                }
            }
        }
        return overlaps
    }
    
    private static func isBudgetCompatible(_ b1: BudgetRange?, _ b2: BudgetRange?) -> Bool {
        guard let b1 = b1, let b2 = b2 else { return false }
        // Low ve High birbiriyle uyumsuz, Medium herkesle uyumlu gibi bir mantık
        if b1 == .medium || b2 == .medium { return true }
        return b1 == b2
    }
}
