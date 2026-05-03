import SwiftUI
import MapKit

struct TripResultView: View {
    let plan: GeminiTripPlan
    @StateObject private var savedTripsManager = SavedTripsManager.shared
    @State private var showSavedToast = false
    
    // Aktivitelerden harita pinleri üretir (lat/lng 0 olmayanlar)
    private var mapPins: [MapPin] {
        plan.itinerary.flatMap { $0.activities }.compactMap { activity in
            if activity.estimatedLat != 0.0 && activity.estimatedLng != 0.0 {
                return MapPin(name: activity.placeName, coordinate: CLLocationCoordinate2D(latitude: activity.estimatedLat, longitude: activity.estimatedLng))
            }
            return nil
        }
    }
    
    // Pinlerin lokasyonuna göre harita merkezini ayarlar
    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // 1) En tepede Hedef ve Başlık
                VStack(alignment: .leading, spacing: 8) {
                    Text(plan.selectedDestination)
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        
                    Text(plan.tripTitle)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // 2) Dinamik Harita Alanı
                if !mapPins.isEmpty {
                    Map(coordinateRegion: $region, annotationItems: mapPins) { pin in
                        MapMarker(coordinate: pin.coordinate, tint: .red)
                    }
                    .overlay(
                        Map {
                            if #available(iOS 17.0, *) {
                                // Farklı renkler listesi
                                let lineColors: [Color] = [.blue, .purple, .green, .orange, .pink, .teal, .indigo, .red]
                                
                                ForEach(Array(plan.itinerary.enumerated()), id: \.offset) { index, day in
                                    let dayPins = day.activities.compactMap {
                                        $0.estimatedLat != 0.0 && $0.estimatedLng != 0.0 ? CLLocationCoordinate2D(latitude: $0.estimatedLat, longitude: $0.estimatedLng) : nil
                                    }
                                    
                                    if !dayPins.isEmpty {
                                        // Pinleri Göster
                                        ForEach(Array(dayPins.enumerated()), id: \.offset) { pIndex, coord in
                                            Marker(day.activities[pIndex].placeName, coordinate: coord)
                                                .tint(lineColors[index % lineColors.count])
                                        }
                                        
                                        // Çizgiyi Göster
                                        MapPolyline(coordinates: dayPins)
                                            .stroke(lineColors[index % lineColors.count], lineWidth: 4)
                                    }
                                }
                            }
                        }
                        .opacity(mapPins.count > 0 ? 1 : 0) // Polyline üst üste ezsin
                    )
                    .frame(height: 250)
                    .cornerRadius(15)
                    .padding(.horizontal)
                    .shadow(radius: 5)
                    .onAppear {
                        if let first = mapPins.first {
                            region = MKCoordinateRegion(
                                center: first.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                            )
                        }
                    }
                }
                
                // 3) Yatay Kaydırılabilir General Tips Kartları
                if !plan.generalTips.isEmpty {
                    VStack(alignment: .leading) {
                        Text("İpuçları")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(plan.generalTips, id: \.self) { tip in
                                    Text(tip)
                                        .padding()
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(12)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .frame(width: 250)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                Divider()
                
                // 4) Seyahat Planı / Rota
                Text("Seyahat Planı")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                ForEach(plan.itinerary) { dayInfo in
                    VStack(alignment: .leading, spacing: 10) {
                        // Gün Başlığı
                        Text(dayInfo.dateDescription)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.top, 10)
                        
                        // Aktiviteler
                        ForEach(dayInfo.activities) { activity in
                            HStack(alignment: .top, spacing: 12) {
                                VStack {
                                    Text(activity.timeOfDay)
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                    Spacer()
                                }
                                .frame(width: 70, alignment: .leading)
                                
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack {
                                        Text(activity.placeName)
                                            .font(.headline)
                                        Spacer()
                                        Text(activity.costCategory)
                                            .font(.caption)
                                            .padding(4)
                                            .background(Color.green.opacity(0.2))
                                            .cornerRadius(6)
                                    }
                                    
                                    Text(activity.description)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.04), radius: 5, y: 3)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .navigationTitle("Plan Özeti")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    savedTripsManager.saveTrip(plan)
                    showSavedToast = true
                } label: {
                    Image(systemName: "bookmark.fill")
                        .foregroundColor(savedTripsManager.savedTrips.contains(where: { $0.id == plan.id }) ? .yellow : .blue)
                }
            }
        }
        .alert(isPresented: $showSavedToast) {
            Alert(title: Text("Kaydedildi"), message: Text("Rota başarıyla Profil ve Trips sayfasına eklendi."), dismissButton: .default(Text("Tamam")))
        }
    }
}

struct MapPin: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}

