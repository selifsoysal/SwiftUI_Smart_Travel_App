import Foundation
import GoogleGenerativeAI

final class GeminiService {
    static let shared = GeminiService()
    
    // TODO: Gerçek projenizde API anahtarınızı güvenli bir şekilde saklayın (örn: xcconfig veya plist)
    private let apiKey = "AIzaSyDxlJkYMtdaFZUpsYwzxruzGIAv8CrHvbY"
    
    private init() {}
    
    /// Kullanıcı verilerine göre Gemini API üzerinden seyahat planı oluşturur
    func generateTripPlan(
        destination: String?,
        budget: String,
        days: Int,
        travelType: String,
        travelProfile: String
    ) async throws -> GeminiTripPlan {
        
        let destinationValue = (destination == nil || destination!.isEmpty) ? "Farketmez" : destination!
        
        // JSON formatında dönmesi için GenerationConfig ayarlıyoruz
        let config = GenerationConfig(
            responseMIMEType: "application/json"
        )
        
        // Kullanıcı girdilerini entegre ettiğimiz System Instruction
        let systemInstructionText = """
        Sen uzman bir yapay zeka seyahat asistanısın. Görevin, kullanıcının verdiği bilgilere dayanarak optimize edilmiş, mantıklı ve gerçekçi bir seyahat rotası oluşturmaktır.

        KULLANICI GİRDİLERİ:
        - Hedef Lokasyon: \(destinationValue) (Eğer 'Farketmez' veya boş ise bütçeye, tipe ve gün sayısına en uygun rotayı SEN SEÇ.)
        - Kalınacak Gün Sayısı: TAM OLARAK \(days) GÜN
        - Toplam Bütçe: \(budget)
        - Gezgin Tipi (TravelType): \(travelType)
        - Gezgin Profili (TravelProfile): \(travelProfile)

        KURALLAR:
        1. Lokasyon & Süre: Rota kesinlikle \(days) günlük olmalıdır. Eksik veya fazla gün üretme.
        2. Mantıklı Haritalandırma: Bir günde gidilecek mekanların birbirine coğrafi olarak YAKIN (yürüme veya kısa transit mesafesinde) olmasını sağla. Farklı uçlardaki mekanları aynı güne koyma. Rotanın mantıklı bir harita (polyline) bağlantısı olabilsin.
        3. Koordinatlar: Tahmini koordinatları (lat/lng) doğruya EN YAKIN şekilde ver.
        4. Kesin Format: Yanıtını SADECE aşağıdaki JSON formatında ver. Swift "Codable" yapısı JSON dışı her şeyde çöker.

        BEKLENEN JSON FORMATI:
        {
          "selectedDestination": "Şehir, Ülke (Senin seçtiğin veya kullanıcının girdiği nihai lokasyon)",
          "tripTitle": "Seyahatin profiline uygun ilgi çekici başlığı",
          "itinerary": [
            {
              "dayNumber": 1,
              "dateDescription": "1. Gün",
              "activities": [
                {
                  "timeOfDay": "Sabah",
                  "placeName": "Mekan Adı",
                  "description": "Burada ne yapılacağına dair net açıklama.",
                  "estimatedLat": 0.0000,
                  "estimatedLng": 0.0000,
                  "costCategory": "₺₺"
                }
              ]
            }
          ],
          "generalTips": [
            "Seçilen lokasyon veya profile özel kısa ipucu"
          ]
        }
        """
        
        // Modeli oluşturuyoruz (gemini-flash-latest)
        let model = GenerativeModel(
            name: "gemini-flash-latest",
            // API key'i başlatırken pass ediyoruz
            apiKey: apiKey,
            generationConfig: config,
            systemInstruction: ModelContent(role: "system", parts: [.text(systemInstructionText)])
        )
        
        // İstek göndereceğimiz Prompt
        let userPrompt = "Lütfen belirtilen bilgilere ve kurallara dayanarak JSON formatında seyahat rotasını oluştur."
        
        // API İsteği
        let response = try await model.generateContent(userPrompt)
        
        // Gelen yanıtın JSON Text'ini parse etme
        guard let responseText = response.text, let data = responseText.data(using: .utf8) else {
            throw NSError(domain: "GeminiError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Yanıt metni alınamadı veya veriye dönüştürülemedi."])
        }
        
        // JSON'ı Model'lerimize (GeminiTripPlan vb.) dönüştürüyoruz
        let decoder = JSONDecoder()
        let tripPlan = try decoder.decode(GeminiTripPlan.self, from: data)
        
        return tripPlan
    }
}
