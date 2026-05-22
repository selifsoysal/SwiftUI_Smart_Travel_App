import SwiftUI

struct CommunityTripDetailView: View {
    let trip: GeminiTripPlan
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with Creator Info
                    HStack(spacing: 15) {
                        Circle()
                            .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(trip.creatorName?.prefix(1) ?? "G")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(trip.creatorName ?? "Gizemli Gezgin")
                                .font(.headline)
                            
                            HStack(spacing: 8) {
                                if let age = trip.creatorAge {
                                    Text("\(age) Yaş")
                                }
                                if let type = trip.creatorTravelType {
                                    Text("• \(type)")
                                }
                                if let budget = trip.creatorBudget {
                                    Text("• \(BudgetRange.displayName(for: budget)) Bütçe")
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            
                            Text("Bu rotayı oluşturdu")
                                .font(.caption.bold())
                                .foregroundColor(.blue)
                                .padding(.top, 2)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    // The Itinerary (using TripResultView in read-only mode)
                    TripResultView(plan: trip, isReadOnly: true)
                }
            }
            .navigationTitle("Rota Detayı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
    }
}
