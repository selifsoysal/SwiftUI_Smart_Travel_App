import Foundation
import CoreML

/**
 * SmartMatchingEngine: Daha önce ML modeli kullanan bu motor, artık tamamen deterministik, 
 * grup dinamiklerini (çocuklar, eşler, cinsiyet, yalnız gezginler) analiz eden Gelişmiş Matematiksel Eşleşme kullanır.
 */
struct MatchingScoreDetails {
    var score: Int
    var explanations: [String]
}

class NeuralMatchingEngine {
    static let shared = NeuralMatchingEngine()
    
    private init() {}
    
    // Şehir profillerini kalıcı hafızada tutarak kotayı koruruz.
    private var cityProfileCache: [String: [String: Double]] = [:]
    private let cacheKey = "city_profile_cache_v1"
    
    private let placeTypeMapping: [String: String] = [
        "museum": "Kültür Kaşifi",
        "art_gallery": "Kültür Kaşifi",
        "church": "Kültür Kaşifi",
        "hindu_temple": "Kültür Kaşifi",
        "mosque": "Kültür Kaşifi",
        "synagogue": "Kültür Kaşifi",
        "city_hall": "Kültür Kaşifi",
        "park": "Doğa Sever",
        "natural_feature": "Doğa Sever",
        "campground": "Doğa Sever",
        "aquarium": "Doğa Sever",
        "zoo": "Doğa Sever",
        "mountain": "Doğa Sever",
        "restaurant": "Gurme Gezgin",
        "cafe": "Gurme Gezgin",
        "bakery": "Gurme Gezgin",
        "bar": "Gurme Gezgin",
        "winery": "Gurme Gezgin",
        "casino": "Lüks Tutkunu",
        "shopping_mall": "Lüks Tutkunu",
        "department_store": "Lüks Tutkunu",
        "night_club": "Lüks Tutkunu",
        "spa": "Lüks Tutkunu",
        "library": "Tarih Meraklısı",
        "university": "Tarih Meraklısı",
        "monument": "Tarih Meraklısı",
        "landmark": "Tarih Meraklısı"
    ]
    
    // CoreML Model Instance
    private var model: TravelMatcherNew? = {
        do {
            let config = MLModelConfiguration()
            return try TravelMatcherNew(configuration: config)
        } catch {
            print("DEBUG: CoreML Model yüklenemedi: \(error)")
            return nil
        }
    }()
    
    // MARK: - Core Advanced Matching Logic
    
    private func calculateDeterministicMatch(
        u1_weights: [String: Double]?,
        u2_weights: [String: Double]?,
        u1_age: Int?,
        u1_gender: String?,
        u1_travelType: String?,
        u1_companions: [Companion]?,
        u2_age: Int?,
        u2_gender: String?,
        u2_travelType: String?,
        u2_companions: [Companion]?,
        u1_budget: String?,
        u2_budget: String?,
        destination: String? = nil
    ) async -> MatchingScoreDetails {
        
        var explanations: [String] = []
        
        // --- 1. Base Information ---
        var u1_adults: [Int] = []
        var u1_children: [Int] = []
        if let a1 = u1_age { u1_adults.append(a1) }
        
        var u1_females = (u1_gender == "Kadın") ? 1 : 0
        var u1_males = (u1_gender == "Erkek") ? 1 : 0
        
        if let comps1 = u1_companions {
            for c in comps1 {
                if c.age >= 18 { u1_adults.append(c.age) } else { u1_children.append(c.age) }
                if c.gender == "Kadın" { u1_females += 1 } else if c.gender == "Erkek" { u1_males += 1 }
            }
        }
        
        var u2_adults: [Int] = []
        var u2_children: [Int] = []
        if let a2 = u2_age { u2_adults.append(a2) }
        
        var u2_females = (u2_gender == "Kadın") ? 1 : 0
        var u2_males = (u2_gender == "Erkek") ? 1 : 0
        
        if let comps2 = u2_companions {
            for c in comps2 {
                if c.age >= 18 { u2_adults.append(c.age) } else { u2_children.append(c.age) }
                if c.gender == "Kadın" { u2_females += 1 } else if c.gender == "Erkek" { u2_males += 1 }
            }
        }
        
        // ML Prediction (CoreML)
        let mlScore = predictWithCoreML(w1: u1_weights, w2: u2_weights, a1: u1_age, a2: u2_age, b1: u1_budget, b2: u2_budget)
        
        let profileSim = calculateProfileSimilarity(w1: u1_weights, w2: u2_weights, name1: "User1", name2: "User2") // 0.0 to 1.0
        
        // --- 2. Profile, Destination & Budget ---
        // Profil benzerliği (profileSim) artık ana skorun %80'ini belirliyor
        var totalScore = profileSim * 80.0
        
        // ML Prediction (CoreML) - Sadece destekleyici %20 ağırlık
        if let ml = mlScore {
            // ML skoru 0-100 arasındaysa 0-1 aralığına çek, ardından 20 puan üzerinden ekle
            let normalizedML = ml > 1.0 ? ml / 100.0 : ml
            totalScore += normalizedML * 20.0
        } else {
            totalScore += 10.0 // Fallback
        }
        
        // KRİTİK FİLTRE: İlgi alanları %70'in altındaysa asla "Mükemmel" diyemez.
        if profileSim >= 0.85 {
            explanations.append("Kültür, doğa ve yemek gibi ilgi alanlarınız mükemmel derecede uyuşuyor.")
        } else if profileSim >= 0.65 {
            explanations.append("Seyahat zevkleriniz genel olarak birbirine yakın görünüyor.")
        } else {
            explanations.append("İlgi alanlarınız ve seyahat tarzınız arasında belirgin farklar var.")
            totalScore = min(totalScore, 60.0)
        }
        
        // YENİ: Tekil Fark Kontrolü (Discrepancy Check) - Daha Derinlemesine
        // Eğer bir alanda uçurum varsa (Örn: 0.1 vs 0.6), skoru baltala.
        let maxDiff = calculateMaxInterestDiff(w1: u1_weights, w2: u2_weights)
        if maxDiff > 0.45 {
            totalScore *= 0.65 // %35 doğrudan ceza
            explanations.append("Temel seyahat zevklerinizden bazıları (örneğin lüks vs kültürel) birbirine tamamen zıt olduğu için uyum puanı ciddi oranda düşürüldü.")
            print("⚠️ DISCREPANCY PENALTY: MaxDiff: \(maxDiff), Score dropped to: \(totalScore)")
        } else if maxDiff > 0.30 {
            totalScore *= 0.80 // %20 doğrudan ceza
            explanations.append("Bazı seyahat zevkleriniz arasında belirgin farklar olduğu için uyum puanı düşürüldü.")
            print("⚠️ DISCREPANCY PENALTY: MaxDiff: \(maxDiff), Score dropped to: \(totalScore)")
        }
        
        print("🔍 MATCH DEBUG [Step 1]: ProfileSim: \(String(format: "%.2f", profileSim)), ML: \(String(format: "%.2f", mlScore ?? 0)), Base Score: \(totalScore)")
        
        if let destName = destination, !destName.isEmpty {
            let destInterests = await getDestinationInterests(for: destName)
            let destSim = calculateProfileSimilarity(w1: u1_weights, w2: destInterests, name1: "User", name2: "Dest(\(destName))")
            totalScore += destSim * 5.0 // Destinasyon etkisi düşürüldü
            
            if destSim > 0.8 {
                explanations.append("İlgi alanlarınız, '\(destName)' rotasıyla örtüşüyor.")
            }
        }
        
        // --- Bütçe Analizi (Çarpan Olarak) ---
        let b1_score = budgetToScore(u1_budget)
        let b2_score = budgetToScore(u2_budget)
        let b1_amount = extractAmount(u1_budget)
        let b2_amount = extractAmount(u2_budget)
        
        let budgetDiff = abs(b1_score - b2_score)
        var budgetMultiplier = 1.0
        
        if budgetDiff == 0 {
            if let a1 = b1_amount, let a2 = b2_amount, a1 > 0, a2 > 0 {
                let ratio = max(a1, a2) / min(a1, a2)
                if ratio > 2.5 { budgetMultiplier = 0.85 } // %15 ceza
                else if ratio > 1.5 { budgetMultiplier = 1.05 } // %5 bonus
                else { budgetMultiplier = 1.10 } // %10 bonus
            } else {
                budgetMultiplier = 1.05
            }
        } else if budgetDiff == 2 {
            budgetMultiplier = 0.70 // %30 ceza
        }
        
        totalScore *= budgetMultiplier
        print("🔍 MATCH DEBUG [Step 1.5]: BudgetMultiplier: \(budgetMultiplier), Score: \(totalScore)")
        
        // --- 3. Base Group Information ---
        let avgAdult1 = u1_adults.isEmpty ? 25.0 : Double(u1_adults.reduce(0, +)) / Double(u1_adults.count)
        let avgAdult2 = u2_adults.isEmpty ? 25.0 : Double(u2_adults.reduce(0, +)) / Double(u2_adults.count)
        let adultAgeDiff = abs(avgAdult1 - avgAdult2)
        
        // --- 4. Group Dynamics (Bonus/Penalty Layer) ---
        var groupBonus = 0.0
        let t1 = u1_travelType ?? "Bilinmiyor"
        let t2 = u2_travelType ?? "Bilinmiyor"
        
        let hasChildren1 = !u1_children.isEmpty
        let hasChildren2 = !u2_children.isEmpty
        
        // A. Child Dynamics
        if hasChildren1 && hasChildren2 {
            let avgChild1 = Double(u1_children.reduce(0, +)) / Double(u1_children.count)
            let avgChild2 = Double(u2_children.reduce(0, +)) / Double(u2_children.count)
            let childAgeDiff = abs(avgChild1 - avgChild2)
            
            if childAgeDiff <= 3 {
                groupBonus += 15.0
                explanations.append("Yol arkadaşlarınız ve karşı tarafın çocukları yaşıt olduğu için oyun/aktivite uyumu sağlandı (+15 Puan).")
            } else if childAgeDiff <= 7 {
                groupBonus += 5.0
                explanations.append("Her iki grubun da seyahat rotasında çocuklu aile dinamikleri bulunduğu için pozitif etki sağlandı (+5 Puan).")
            } else {
                groupBonus -= 20.0
                explanations.append("Gruplarınızdaki çocukların yaş farkı (Örn: Bebek vs Ergen) çok yüksek. Aktivite uyuşmazlığı olacağı için puan önemli ölçüde düşürüldü (-20 Puan).")
            }
        } else if hasChildren1 != hasChildren2 {
            if t1 == "Yalnız" || t2 == "Yalnız" || t1 == "Çift/Partner" || t2 == "Çift/Partner" {
                groupBonus -= 25.0
                explanations.append("Çocuksuz veya yalnız bir profilin, küçük çocuklu bir grupla seyahat etmesi dinamiği bozacağı için uyum puanı ciddi oranda düşürüldü (-25 Puan).")
            }
        }
        
        // B. Travel Type Dynamics
        if t1 == "Aile" && t2 == "Aile" {
            groupBonus += 10.0
            explanations.append("İki grup da Aile olduğu için ortak seyahat dinamikleri sebebiyle bonus puan eklendi.")
        } else if (t1 == "Yalnız" && t2 == "Aile") || (t1 == "Aile" && t2 == "Yalnız") {
            groupBonus -= 30.0
            explanations.append("Aile tatili konseptine yalnız bir gezginin katılması zor olacağı için puan çok yüksek oranda düşürüldü.")
        } else if t1 == "Yalnız" && t2 == "Yalnız" {
            groupBonus += 5.0
            explanations.append("İki taraf da yalnız gezgin olduğu için eşleşme ihtimali arttı.")
        }
        
        // C. Gender Dynamics
        let isAllFemale1 = (u1_females > 0 && u1_males == 0)
        let isAllFemale2 = (u2_females > 0 && u2_males == 0)
        let isAllMale1 = (u1_males > 0 && u1_females == 0)
        let isAllMale2 = (u2_males > 0 && u2_females == 0)
        
        if (isAllFemale1 && isAllMale2) || (isAllMale1 && isAllFemale2) {
            groupBonus -= 20.0
            explanations.append("Grupların cinsiyet dağılımı (tamamen erkek vs tamamen kadın) uyum göstermediği için puan düşürüldü.")
        } else if (isAllFemale1 && isAllFemale2) {
            // Bonus aşağıda multiplier içinde ayrıca veriliyor, burada da ufak bir ekleme yapılabilir
            groupBonus += 5.0
        }
        
        // Add groupBonus to totalScore
        totalScore += groupBonus
        
        // --- 5. Multiplicative Bonuses (Çarpan Sistemi) ---
        // Artık +10 puan eklemek yerine, mevcut puanı %X artırıyoruz.
        // Eğer taban puan (ilgi alanı) düşükse, bonuslar onu 100 yapamaz.
        var multiplier = 1.0
        
        if u1_travelType == TravelType.solo.rawValue && u2_travelType == TravelType.solo.rawValue {
            multiplier += 0.05 // %5 bonus
        }
        
        if isAllFemale1 && isAllFemale2 {
            multiplier += 0.10 // %10 bonus
            explanations.append("Sadece kadınlardan oluşan güvenli seyahat grubu uyumu yakalandı.")
        }
        
        totalScore *= multiplier
        print("🔍 MATCH DEBUG [Step 2]: Multiplier: \(multiplier), Total After Multiplier: \(totalScore)")
        
        totalScore = min(max(totalScore, 0.0), 100.0)
        
        // --- 6. Adjustments (Uyum Düzenlemeleri) ---
        // Yaş farkı etkisi
        if adultAgeDiff <= 5 {
            explanations.append("Gruptaki yetişkinlerin yaş ortalamaları birbirine oldukça yakın.")
        } else if adultAgeDiff > 10 {
            let penalty = (adultAgeDiff - 10) * 2.0
            totalScore -= penalty
            explanations.append("Yetişkin yaş ortalamalarınız arasındaki belirgin fark (\(Int(adultAgeDiff)) yaş), ortak seyahat dinamikleri açısından uyum puanını olumsuz etkiliyor.")
        }
        
        // --- 7. Hard Limits (Kritik Sınırlar) ---
        if adultAgeDiff > 20 {
            totalScore = min(totalScore, 40.0)
            explanations.append("Gruplar arası yaş farkı çok yüksek (20+ yaş) olduğu için genel uyum düşük seviyede sınırlandırıldı.")
        } else if adultAgeDiff > 15 {
            totalScore = min(totalScore, 65.0)
            explanations.append("Gruplar arası yaş farkı (15+ yaş) nedeniyle genel uyum puanına üst sınır getirildi.")
        }
        
        if budgetDiff == 2 {
            totalScore = min(totalScore, 55.0)
            explanations.append("Bütçe beklentileri tamamen zıt olduğu için uyum puanı üst seviyeden kısıtlandı.")
        }
        
        // --- 8. Data Integrity Check ---
        if u2_weights == nil || u2_weights!.isEmpty {
            // Karşı tarafın ilgi alanı verisi yoksa puanı %30 düşür (0.7 ile çarp) 
            // Ama asla 40'a sabitleme, eldeki diğer verilere güven
            totalScore *= 0.7
            explanations.append("⚠️ Karşı tarafın ilgi alanı verileri henüz tam olarak tanımlanmamış. Mevcut diğer bilgilere (yaş, bütçe, seyahat tipi) dayanarak tahmini bir puan hesaplandı.")
        }
        
        let finalPercentage = Int(min(max(totalScore, 0.0), 100.0))
        print("🔍 MATCH DEBUG [Final]: Final Score: %\(finalPercentage)")
        
        return MatchingScoreDetails(score: finalPercentage, explanations: explanations)
    }
    
    // MARK: - Public Methods
    
    func calculateMatchScore(user1: User, user2: Traveler, destination: String? = nil) async -> MatchingScoreDetails {
        return await calculateDeterministicMatch(
            u1_weights: user1.profileWeights,
            u2_weights: user2.profileWeights,
            u1_age: user1.age,
            u1_gender: user1.gender,
            u1_travelType: user1.travelType?.rawValue,
            u1_companions: user1.companions,
            u2_age: user2.age,
            u2_gender: user2.gender,
            u2_travelType: user2.travelType?.rawValue,
            u2_companions: user2.companions,
            u1_budget: user1.budget?.rawValue,
            u2_budget: user2.budget.rawValue,
            destination: destination
        )
    }
    
    func calculateEventMatch(user: User, event: ActivityEvent) async -> MatchingScoreDetails {
        return await calculateDeterministicMatch(
            u1_weights: user.profileWeights,
            u2_weights: event.hostProfileWeights,
            u1_age: user.age,
            u1_gender: user.gender,
            u1_travelType: user.travelType?.rawValue,
            u1_companions: user.companions,
            u2_age: event.hostAge,
            u2_gender: event.hostGender,
            u2_travelType: event.hostTravelType,
            u2_companions: event.hostCompanions,
            u1_budget: user.budget?.rawValue,
            u2_budget: event.hostBudget,
            destination: event.destination
        )
    }
    
    func calculateTripMatch(user: User, trip: GeminiTripPlan) async -> MatchingScoreDetails {
        var creatorWeights = trip.creatorProfileWeights
        var creatorTravelType = trip.creatorTravelType
        var creatorBudget = trip.creatorBudget
        var creatorAge = trip.creatorAge
        var creatorGender = trip.creatorGender
        var creatorCompanions = trip.creatorCompanions
        
        // Eğer rotada bu bilgiler eksikse (eski rota), Firestore'dan güncel kullanıcıyı çekmeyi dene
        if (creatorWeights == nil || creatorWeights!.isEmpty), let creatorId = trip.userId {
            print("🔍 MATCH: Rota içinde sahiplik verisi eksik, Firestore'dan güncel veri çekiliyor: \(creatorId)")
            let latestCreator = await withCheckedContinuation { continuation in
                DatabaseManager.shared.findUser(userId: creatorId) { user in
                    continuation.resume(returning: user)
                }
            }
            
            if let latest = latestCreator {
                creatorWeights = latest.profileWeights
                creatorTravelType = latest.travelType?.rawValue
                creatorBudget = latest.budget?.rawValue
                creatorAge = latest.age
                creatorGender = latest.gender
                creatorCompanions = latest.companions
            }
        }
        
        return await calculateDeterministicMatch(
            u1_weights: user.profileWeights,
            u2_weights: creatorWeights,
            u1_age: user.age,
            u1_gender: user.gender,
            u1_travelType: user.travelType?.rawValue,
            u1_companions: user.companions,
            u2_age: creatorAge,
            u2_gender: creatorGender,
            u2_travelType: creatorTravelType,
            u2_companions: creatorCompanions,
            u1_budget: user.budget?.rawValue,
            u2_budget: creatorBudget,
            destination: trip.selectedDestination
        )
    }
    
    func calculateDestinationMatch(user: User, destination: Destination) -> Int {
        return calculateRecommendationScore(user: user, cityInterests: destination.interests ?? [:])
    }
    
    func calculateRecommendationScore(user: User, cityInterests: [String: Double]) -> Int {
        let userWeights = normalizeWeights(user.profileWeights ?? [:])
        let cityWeights = normalizeWeights(cityInterests)
        
        var dotProduct: Double = 0
        for (key, val) in userWeights {
            if let cityVal = cityWeights[key] {
                dotProduct += val * cityVal
            }
        }
        
        // Noktasal çarpım (Dot Product) 0.0-1.0 arasındadır. 100 ile çarparak yüzdeye çeviriyoruz.
        // Eğer sonuç çok düşük kalırsa logaritmik veya doğrusal bir ölçeklendirme eklenebilir.
        // Şimdilik ham dot product (x100) en adil sonucu verir.
        return Int(min(dotProduct * 150, 100.0)) // 1.5 katsayısı ile biraz daha belirgin farklar oluşturuyoruz
    }

    func analyzeCityWithPlaces(city: String) async -> [String: Double] {
        let cityKey = city.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cityProfileCache.isEmpty { loadCache() }
        if let cached = cityProfileCache[cityKey] { return cached }
        
        let service = GooglePlacesService()
        do {
            let places = try await service.fetchPlaces(query: "\(city) tourist attractions")
            var counts: [String: Double] = [:]
            var totalHits: Double = 0
            
            for place in places {
                guard let types = place.types else { continue }
                for type in types {
                    if let category = placeTypeMapping[type] {
                        counts[category, default: 0] += 1
                        totalHits += 1
                    }
                }
            }
            
            if totalHits > 0 {
                var interests: [String: Double] = [:]
                for (cat, count) in counts {
                    interests[cat] = count / totalHits
                }
                
                cityProfileCache[cityKey] = interests
                saveCache()
                return interests
            }
        } catch {
            print("🏙️ PLACES ERROR: \(error)")
        }
        
        return [:]
    }

    // MARK: - CoreML Prediction Helper
    
    private func predictWithCoreML(w1: [String: Double]?, w2: [String: Double]?, a1: Int?, a2: Int?, b1: String?, b2: String?) -> Double? {
        guard let model = model, let w1 = w1, let w2 = w2 else { return nil }
        
        do {
            let w1_norm = normalizeWeights(w1)
            let w2_norm = normalizeWeights(w2)
            
            let cultureDiff = abs((w1_norm["culture"] ?? 0.0) - (w2_norm["culture"] ?? 0.0))
            let natureDiff = abs((w1_norm["nature"] ?? 0.0) - (w2_norm["nature"] ?? 0.0))
            let foodDiff = abs((w1_norm["food"] ?? 0.0) - (w2_norm["food"] ?? 0.0))
            let luxuryDiff = abs((w1_norm["luxury"] ?? 0.0) - (w2_norm["luxury"] ?? 0.0))
            let historyDiff = abs((w1_norm["history"] ?? 0.0) - (w2_norm["history"] ?? 0.0))
            
            let ageDiff = Double(abs((a1 ?? 25) - (a2 ?? 25))) / 40.0
            let b1_score = Double(budgetToScore(b1))
            let b2_score = Double(budgetToScore(b2))
            let budgetDiff = abs(b1_score - b2_score) / 2.0
            
            let input = TravelMatcherNewInput(
                culture_diff: cultureDiff,
                nature_diff: natureDiff,
                food_diff: foodDiff,
                luxury_diff: luxuryDiff,
                history_diff: historyDiff,
                age_diff: ageDiff,
                budget_diff: budgetDiff
            )
            
            let prediction = try model.prediction(input: input)
            return prediction.match_score
        } catch {
            print("DEBUG: CoreML Prediction hatası: \(error)")
            return nil
        }
    }

    // MARK: - Helpers
    
    private func budgetToScore(_ budget: String?) -> Int {
        guard let b = budget, !b.isEmpty else { return 1 }
        
        // 1. Kategorik Eşleşme (Onboarding veya Profil verisi)
        let lowKeywords = ["Low", "Düşük", "Ekonomik", "Economic"]
        let medKeywords = ["Medium", "Orta", "Standart", "Standard"]
        let highKeywords = ["High", "Yüksek", "Lüks", "Luxury"]
        
        if lowKeywords.contains(where: { b.contains($0) }) { return 0 }
        if highKeywords.contains(where: { b.contains($0) }) { return 2 }
        if medKeywords.contains(where: { b.contains($0) }) { return 1 }
        
        // 2. Sayısal Eşleşme (Rota oluşturma verisi - örn: "25000 TL")
        // Rakam dışındaki her şeyi temizle
        let numericString = b.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let amount = Double(numericString), amount > 0 {
            // Güncel Türkiye ve Global seyahat maliyetlerine göre gerçekçi baremler:
            if amount < 15000 { return 0 }      // 15.000 TL altı: Ekonomik/Sırt Çantalı
            if amount < 50000 { return 1 }      // 15.000 - 50.000 TL arası: Standart/Konforlu
            return 2                           // 50.000 TL üstü: Lüks/Premium
        }
        
        return 1 // Belirsiz durumlarda "Orta" bütçe en güvenli liman
    }
    
    private func extractAmount(_ budget: String?) -> Double? {
        guard let b = budget else { return nil }
        let numericString = b.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Double(numericString)
    }
    
    private func getDestinationInterests(for city: String) async -> [String: Double] {
        let cityKey = city.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Önce Hafızadaki Cache'e bak
        if cityProfileCache.isEmpty { loadCache() }
        
        if let cached = cityProfileCache[cityKey] {
            print("🏙️ AI CACHE: \(city) profili hafızadan alındı.")
            return cached
        }
        
        // 2. Eğer Cache'de yoksa Gemini'ye sor
        print("🏙️ AI ANALYZING: \(city) profili Gemini ile analiz ediliyor...")
        do {
            let aiInterests = try await GeminiService.shared.analyzeCityInterests(city: city)
            if !aiInterests.isEmpty {
                cityProfileCache[cityKey] = aiInterests
                saveCache() // Kalıcı olarak kaydet
                return aiInterests
            }
        } catch {
            print("🏙️ AI ERROR: Şehir analizi başarısız: \(error)")
        }
        
        // 3. Fallback (Gemini başarısız olursa eski statik mantık)
        let cityLower = cityKey
        var interests: [String: Double] = [:]
        
        if cityLower.contains("paris") || cityLower.contains("rome") || cityLower.contains("istanbul") || cityLower.contains("athens") {
            interests["Kültür Kaşifi"] = 0.9
            interests["Tarih Tutkunu"] = 0.8
        } else if cityLower.contains("alps") || cityLower.contains("patagonia") || cityLower.contains("cappadocia") || cityLower.contains("banff") {
            interests["Doğa Tutkunu"] = 0.9
            interests["Macera Arayan"] = 0.8
        } else if cityLower.contains("maldives") || cityLower.contains("bali") || cityLower.contains("phuket") || cityLower.contains("antalya") {
            interests["Deniz Keyfi"] = 0.9
            interests["Lüks Gezgin"] = 0.7
        } else {
            interests["Kültür Kaşifi"] = 0.6
            interests["Lezzet Avcısı"] = 0.6
        }
        
        return interests
    }
    
    // MARK: - Persistence Logic
    private func saveCache() {
        if let encoded = try? JSONEncoder().encode(cityProfileCache) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
        }
    }
    
    private func loadCache() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let decoded = try? JSONDecoder().decode([String: [String: Double]].self, from: data) {
            self.cityProfileCache = decoded
            print("🏙️ AI PERSISTENCE: \(decoded.count) şehir profili hafızadan yüklendi.")
        }
    }
    
    private func calculateProfileSimilarity(w1: [String: Double]?, w2: [String: Double]?, name1: String = "User1", name2: String = "User2") -> Double {
        guard let w1 = w1, let w2 = w2, !w1.isEmpty, !w2.isEmpty else { return 0.5 }
        
        let w1_norm = normalizeWeights(w1)
        let w2_norm = normalizeWeights(w2)
        
        let allKeys = Set(w1_norm.keys).union(w2_norm.keys)
        var totalDiff: Double = 0
        var count: Double = 0
        
        for key in allKeys {
            let v1 = w1_norm[key] ?? 0.0
            let v2 = w2_norm[key] ?? 0.0
            
            let diff = abs(v1 - v2)
            print("   -> Key: \(key) | \(name1): \(v1) | \(name2): \(v2) | Diff: \(diff)")
            
            // RMS (Root Mean Square) mantığı: Farkın karesini alarak büyük farkları cezalandırıyoruz.
            totalDiff += (diff * diff) 
            count += 1
        }
        
        if count == 0 { return 0.5 }
        
        let rmsDiff = sqrt(totalDiff / count)
        let similarity = 1.0 - rmsDiff
        
        return max(min(similarity, 1.0), 0.0)
    }
    
    private func normalizeWeights(_ weights: [String: Double]) -> [String: Double] {
        var normalized: [String: Double] = [:]
        
        for (key, value) in weights {
            let k = key.lowercased()
            if k.contains("kültür") || k.contains("culture") { normalized["culture"] = value }
            else if k.contains("doğa") || k.contains("nature") { normalized["nature"] = value }
            else if k.contains("gurme") || k.contains("lezzet") || k.contains("food") { normalized["food"] = value }
            else if k.contains("lüks") || k.contains("luxury") { normalized["luxury"] = value }
            else if k.contains("tarih") || k.contains("history") { normalized["history"] = value }
            else if k.contains("macera") || k.contains("adventure") { normalized["adventure"] = value }
            else if k.contains("deniz") || k.contains("sea") || k.contains("beach") { normalized["sea"] = value }
            else if k.contains("kış") || k.contains("winter") || k.contains("snow") { normalized["winter"] = value }
            else { normalized[k] = value }
        }
        
        return normalized
    }
    
    private func calculateMaxInterestDiff(w1: [String: Double]?, w2: [String: Double]?) -> Double {
        guard let w1 = w1, let w2 = w2 else { return 0 }
        let w1_norm = normalizeWeights(w1)
        let w2_norm = normalizeWeights(w2)
        let allKeys = Set(w1_norm.keys).union(w2_norm.keys)
        
        var maxD: Double = 0
        for key in allKeys {
            let v1 = w1_norm[key] ?? 0.0
            let v2 = w2_norm[key] ?? 0.0
            maxD = max(maxD, abs(v1 - v2))
        }
        return maxD
    }
}

