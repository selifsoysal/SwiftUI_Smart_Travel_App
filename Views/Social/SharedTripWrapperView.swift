import SwiftUI
import FirebaseAuth

struct SharedTripWrapperView: View {
    let tripId: String
    @State private var tripPlan: GeminiTripPlan?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Rota Yükleniyor...")
            } else if let plan = tripPlan {
                let isMine = plan.userId == Auth.auth().currentUser?.uid
                TripResultView(plan: plan, isReadOnly: !isMine)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("Rota detayları yüklenemedi.")
                        .font(.headline)
                }
            }
        }
        .task {
            tripPlan = await SavedTripsManager.getTrip(byId: tripId)
            isLoading = false
        }
    }
}
