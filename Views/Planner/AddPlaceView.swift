import SwiftUI
import MapKit

struct AddPlaceView: View {
    @Environment(\.presentationMode) var presentationMode
    let dayNumber: Int
    var onAdd: (Activity) -> Void
    
    @State private var searchQuery = ""
    @State private var searchResults: [PlaceDTO] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    
    @State private var selectedPlace: PlaceDTO? = nil
    @State private var selectedTime: Date = Date()
    
    private let placesService = GooglePlacesService()
    
    var body: some View {
        NavigationView {
            VStack {
                // Arama Çubuğu
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Mekan arayın (Örn: Eiffel Tower)", text: $searchQuery)
                        .onSubmit {
                            Task {
                                await searchPlaces()
                            }
                        }
                    
                    if !searchQuery.isEmpty {
                        Button(action: {
                            searchQuery = ""
                            searchResults.removeAll()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .padding()
                
                if isSearching {
                    ProgressView()
                        .padding()
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                List(searchResults, id: \.name) { place in
                    VStack(alignment: .leading) {
                        Button(action: {
                            withAnimation {
                                if selectedPlace?.name == place.name {
                                    selectedPlace = nil
                                } else {
                                    selectedPlace = place
                                }
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(place.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    if let address = place.formatted_address {
                                        Text(address)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: selectedPlace?.name == place.name ? "chevron.up.circle.fill" : "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if selectedPlace?.name == place.name {
                            Divider()
                                .padding(.vertical, 4)
                            
                            HStack {
                                Text("Saat Seçin:")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.secondary)
                                Spacer()
                                DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                
                                Button(action: {
                                    addSelectedPlace(place)
                                }) {
                                    Text("Ekle")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.blue)
                                        .cornerRadius(8)
                                }
                                .padding(.leading, 8)
                            }
                            .padding(.top, 4)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Gün \(dayNumber) İçin Yer Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func searchPlaces() async {
        guard !searchQuery.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        
        do {
            let results = try await placesService.fetchPlaces(query: searchQuery)
            DispatchQueue.main.async {
                self.searchResults = results
                if results.isEmpty {
                    self.errorMessage = "Sonuç bulunamadı."
                }
                self.isSearching = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Arama hatası: \(error.localizedDescription)"
                self.isSearching = false
            }
        }
    }
    
    private func addSelectedPlace(_ place: PlaceDTO) {
        let lat = place.geometry?.location.lat ?? 0.0
        let lng = place.geometry?.location.lng ?? 0.0
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeString = formatter.string(from: selectedTime)
        
        let newActivity = Activity(
            id: UUID(),
            timeOfDay: timeString,
            placeName: place.name,
            description: place.formatted_address ?? "Kullanıcı tarafından eklendi.",
            estimatedLat: lat,
            estimatedLng: lng,
            costCategory: "Özel"
        )
        
        onAdd(newActivity)
        presentationMode.wrappedValue.dismiss()
    }
}
