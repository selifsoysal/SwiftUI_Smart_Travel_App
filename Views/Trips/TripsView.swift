import SwiftUI

struct TripsView: View {
    @StateObject private var savedTripsManager = SavedTripsManager.shared
    
    var body: some View {
        NavigationStack {
            AppContainer {
                if savedTripsManager.savedTrips.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "map.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.gray.opacity(0.3))
                        
                        Text("Henüz kaydedilmiş rotanız yok.")
                            .font(.title3.bold())
                            .foregroundColor(.secondary)
                        
                        Text("Planla sekmesinden yeni harika rotalar oluşturup kaydedin.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(savedTripsManager.savedTrips) { trip in
                            NavigationLink(destination: TripResultView(plan: trip)) {
                                SavedTripCard(trip: trip)
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .padding(.vertical, 8)
                        }
                        .onDelete(perform: savedTripsManager.deleteTrip)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Rotalarım")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct SavedTripCard: View {
    let trip: GeminiTripPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.selectedDestination)
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                    
                    Text("\(trip.itinerary.count) Günlük Rota")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            Text(trip.tripTitle)
                .font(.caption)
                .foregroundColor(.black.opacity(0.7))
                .lineLimit(2)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
    }
}
