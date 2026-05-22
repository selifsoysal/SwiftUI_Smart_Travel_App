import Foundation
import Combine

@MainActor
class TripViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var loadingProgress: Double = 0.0
    @Published var loadingMessage: String = "Maceran hazırlanıyor..."
    @Published var errorMessage: String? = nil
    @Published var generatedPlan: GeminiTripPlan? = nil
    
    private var progressTimer: Timer?
    
    func generateTrip(
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
        startDate: Date,
        endDate: Date,
        user: User
    ) {
        isLoading = true
        loadingProgress = 0.0
        loadingMessage = "Maceran hazırlanıyor..."
        errorMessage = nil
        generatedPlan = nil
        
        // Start simulated progress
        startSimulatedProgress()
        
        Task {
            do {
                var plan = try await GeminiService.shared.generateTripPlan(
                    destination: destination,
                    budget: budget,
                    days: days,
                    travelType: travelType,
                    profileWeights: profileWeights,
                    accommodation: accommodation,
                    transportation: transportation,
                    countryCount: countryCount,
                    companionCount: companionCount,
                    companions: companions,
                    user: user
                )
                // Inject dates
                plan.startDate = startDate
                plan.endDate = endDate
                
                // Finish progress
                stopSimulatedProgress()
                self.loadingProgress = 1.0
                self.loadingMessage = "Rota tamamlandı!"
                
                // Small delay to show completion
                try? await Task.sleep(nanoseconds: 500_000_000)
                
                self.generatedPlan = plan
                self.isLoading = false
            } catch {
                self.isLoading = false
                stopSimulatedProgress()
                
                // Alert çakışmasını önlemek için bekle
                try? await Task.sleep(nanoseconds: 500_000_000)
                self.errorMessage = "Plan oluşturulurken hata oluştu: \(error.localizedDescription)"
            }
        }
    }
    
    private func startSimulatedProgress() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                if self.loadingProgress < 0.9 {
                    self.loadingProgress += 0.02
                    
                    // Update messages based on progress
                    if self.loadingProgress > 0.7 {
                        self.loadingMessage = "Harita üzerinde rotalar çiziliyor..."
                    } else if self.loadingProgress > 0.4 {
                        self.loadingMessage = "En iyi mekanlar seçiliyor..."
                    } else if self.loadingProgress > 0.2 {
                        self.loadingMessage = "Kişiliğine uygun aktiviteler taranıyor..."
                    }
                }
            }
        }
    }
    
    private func stopSimulatedProgress() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
}
