import SwiftUI

struct PlaceDetailView: View {
    let activity: Activity
    
    @State private var place: PlaceDTO?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    private let placesService = GooglePlacesService()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isLoading {
                    ProgressView("Detaylar yükleniyor...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else if let place = place {
                    // Fotoğraf
                    if let firstPhoto = place.photos?.first {
                        AsyncImage(url: URL(string: placesService.photoURL(photoRef: firstPhoto.photo_reference))) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(maxWidth: .infinity, minHeight: 250)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 250)
                                    .clipped()
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 100)
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Image(systemName: "photo.on.rectangle")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                            .foregroundColor(.gray)
                            .padding()
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(place.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        // Rating
                        if let rating = place.rating {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", rating))
                                    .fontWeight(.semibold)
                                Text("/ 5.0 (Google)")
                                    .foregroundColor(.secondary)
                            }
                            .font(.headline)
                        }
                        
                        // Adres
                        if let address = place.formatted_address {
                            HStack(alignment: .top) {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(.red)
                                Text(address)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        // Aktivite Detayı (Kendi planımızdaki)
                        Text("Aktivite Detayı")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text(activity.description)
                            .font(.body)
                        
                        HStack {
                            Text("Tahmini Maliyet:")
                                .fontWeight(.medium)
                            Text(activity.costCategory == "Paid" ? "Ücretli" : (activity.costCategory == "Free" ? "Ücretsiz" : activity.costCategory))
                                .foregroundColor(.green)
                        }
                        
                        HStack {
                            Text("Zaman Dilimi:")
                                .fontWeight(.medium)
                            Text(activity.timeOfDay)
                                .foregroundColor(.blue)
                        }
                        
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Mekan Detayı")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetchDetails()
        }
    }
    
    private func fetchDetails() async {
        do {
            let results = try await placesService.fetchPlaces(query: activity.placeName)
            if let firstMatch = results.first {
                self.place = firstMatch
            } else {
                self.errorMessage = "Mekan bulunamadı."
            }
        } catch {
            self.errorMessage = "Hata oluştu: \(error.localizedDescription)"
        }
        self.isLoading = false
    }
}
