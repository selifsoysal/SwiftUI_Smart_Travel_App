import Foundation
import Combine

@MainActor
class TripViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var generatedPlan: GeminiTripPlan? = nil
    
    // Uygulama içerisinden çağrılacak asıl planlama fonksiyonu
    func generateTrip(destination: String?, budget: String, days: Int, travelType: String, travelProfile: String, startDate: Date? = nil, endDate: Date? = nil) {
        isLoading = true
        errorMessage = nil
        generatedPlan = nil
        
        Task {
            do {
                var plan = try await GeminiService.shared.generateTripPlan(
                    destination: destination,
                    budget: budget,
                    days: days,
                    travelType: travelType,
                    travelProfile: travelProfile
                )
                // Enjekte edilen tarihleri plan objesine bağla
                plan.startDate = startDate
                plan.endDate = endDate
                self.generatedPlan = plan
            } catch {
                self.errorMessage = "Plan oluşturulurken hata oluştu: \(error.localizedDescription)"
            }
            self.isLoading = false
        }
    }
}
