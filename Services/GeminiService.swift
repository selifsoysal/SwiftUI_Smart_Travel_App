import Foundation
import GoogleGenerativeAI

final class GeminiService {
    static let shared = GeminiService()
    
    // TODO: Buraya yeni aldığın API anahtarını yapıştır
    private let apiKey = Config.geminiAPIKey
    
    private init() {}
    
    /// Kullanıcı verilerine göre Gemini API üzerinden gerçek zamanlı seyahat planı oluşturur
    func generateTripPlan(
        destination: String?,
        budget: String,
        days: Int,
        travelType: String,
        profileWeights: [String: Double],
        accommodation: String,
        transportation: String,
        countryCount: Int,
        companionCount: Int,
        companions: [Companion],
        user: User
    ) async throws -> GeminiTripPlan {
        let destinationValue = destination ?? "Popüler bir lokasyon"
        
        let config = GenerationConfig(
            temperature: 0.7,
            topP: 0.95,
            topK: 40,
            maxOutputTokens: 8192,
            responseMIMEType: "application/json"
        )
        
        let systemInstructionText = """
        Sen profesyonel bir seyahat planlayıcısın. Aşağıdaki JSON formatında, kullanıcıya özel ve detaylı bir rota oluşturmalısın.
        
        ÖNEMLİ: Her aktivite için GERÇEK ve DOĞRU GPS koordinatlarını (estimatedLat ve estimatedLng) sağlamalısın. Koordinatları 0.0 bırakma.
        
        KULLANILACAK JSON FORMATI:
        {
          "selectedDestination": "Şehir, Ülke",
          "tripTitle": "Rota Başlığı",
          "itinerary": [
            {
              "dayNumber": 1,
              "dateDescription": "Gün Başlığı",
              "activities": [
                {
                  "timeOfDay": "09:00",
                  "placeName": "Yer Adı",
                  "description": "Açıklama",
                  "estimatedLat": 48.8584,
                  "estimatedLng": 2.2945,
                  "costCategory": "Free/Paid"
                }
              ]
            }
          ],
          "generalTips": ["İpucu 1", "İpucu 2"]
        }
        """
        
        let model = GenerativeModel(
            name: "gemini-2.5-flash",
            apiKey: apiKey,
            generationConfig: config,
            systemInstruction: ModelContent(role: "system", parts: [.text(systemInstructionText)])
        )
        
        let companionsDetails = companions.map { "\($0.age) yaşında \($0.gender)" }.joined(separator: ", ")
        let companionText = companions.isEmpty ? "Yok" : "\(companionCount) kişi (\(companionsDetails))"
        
        let userPrompt = """
        Lütfen aşağıdaki kriterlere uygun, yaratıcı ve mantıklı bir seyahat planı hazırla:
        - Hedef: \(destinationValue)
        - Süre: \(days) gün
        - Bütçe: \(budget)
        - Seyahat Tipi: \(travelType)
        - Kullanıcı İlgi Alanları: \(profileWeights.description)
        - Tercih Edilen Konaklama: \(accommodation)
        - Tercih Edilen Ulaşım: \(transportation)
        - Toplam Ülke Hedefi: \(countryCount)
        - Refakatçiler: \(companionText)
        """
        
        let response = try await model.generateContent(userPrompt)
        
        guard let responseText = response.text else {
            throw NSError(domain: "GeminiError", code: 0, userInfo: [NSLocalizedDescriptionKey: "AI'dan boş yanıt geldi."])
        }
        
        // JSON'ı temizle (Markdown ```json ... ``` bloklarını veya ekstra metinleri ayıkla)
        let cleanedJson = cleanJsonResponse(responseText)
        guard let data = cleanedJson.data(using: .utf8) else {
            throw NSError(domain: "GeminiError", code: 1, userInfo: [NSLocalizedDescriptionKey: "JSON verisi oluşturulamadı."])
        }
        
        do {
            let decoder = JSONDecoder()
            var plan = try decoder.decode(GeminiTripPlan.self, from: data)
            
            plan.userId = user.id
            plan.creatorName = user.name
            plan.creatorBudget = budget
            plan.creatorTravelType = travelType
            plan.creatorAge = user.age
            plan.creatorGender = user.gender
            plan.creatorProfileWeights = profileWeights
            plan.creatorCompanions = companions
            
            return plan
        } catch {
            print("❌ DECODING ERROR: \(error)")
            print("RAW RESPONSE: \(responseText)") // Hata anında ham yanıtı görelim
            throw error
        }
    }
    
    /// Yapay zekadan gelen yanıttaki JSON bloğunu ayıklar
    private func cleanJsonResponse(_ text: String) -> String {
        var cleaned = text
        
        // 1. Markdown kod bloklarını temizle (```json ... ```)
        if let range = cleaned.range(of: "```json"), let endRange = cleaned.range(of: "```", options: .backwards, range: range.upperBound..<cleaned.endIndex) {
            cleaned = String(cleaned[range.upperBound..<endRange.lowerBound])
        } else if let range = cleaned.range(of: "```"), let endRange = cleaned.range(of: "```", options: .backwards, range: range.upperBound..<cleaned.endIndex) {
            cleaned = String(cleaned[range.upperBound..<endRange.lowerBound])
        }
        
        // 2. Başındaki ve sonundaki boşlukları temizle
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Belirtilen şehri seyahat ilgi alanlarına göre analiz eder (0.0 - 1.0 arası puanlar)
    func analyzeCityInterests(city: String) async throws -> [String: Double] {
        let config = GenerationConfig(responseMIMEType: "application/json")
        let model = GenerativeModel(name: "gemini-1.5-flash", apiKey: apiKey, generationConfig: config)
        
        let prompt = "Analyze '\(city)' location and rate these 5 categories from 0.0 to 1.0: Food, Culture, Nature, Luxury, History. Return ONLY JSON."
        let response = try await model.generateContent(prompt)
        
        guard let text = response.text, let data = text.data(using: .utf8) else { return [:] }
        return (try? JSONDecoder().decode([String: Double].self, from: data)) ?? [:]
    }
}
