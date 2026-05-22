import SwiftUI
import MapKit
import FirebaseAuth

struct TripResultView: View {
    let plan: GeminiTripPlan
    @State private var editablePlan: GeminiTripPlan
    
    @StateObject private var savedTripsManager = SavedTripsManager.shared
    @StateObject var socialManager = SocialManager.shared
    @EnvironmentObject var authVM: AuthViewModel
    
    @State private var showSavedToast = false
    @State private var showEventToast = false
    @State private var selectedDayForAdd: Int?
    @State private var selectedDayIndex: Int = 0
    @State private var showSharingSelection = false
    @State private var sharingConflictAlert = false
    @State private var mapPosition: MapCameraPosition = .automatic
    
    var isReadOnly: Bool
    
    init(plan: GeminiTripPlan, isReadOnly: Bool = false) {
        self.plan = plan
        self.isReadOnly = isReadOnly
        
        var initialPlan = plan
        if initialPlan.id == nil {
            initialPlan.id = UUID().uuidString
        }
        self._editablePlan = State(initialValue: initialPlan)
    }
    
    private var mapPins: [MapPin] {
        guard editablePlan.itinerary.indices.contains(selectedDayIndex) else { return [] }
        return editablePlan.itinerary[selectedDayIndex].activities.compactMap { activity in
            if activity.estimatedLat != 0.0 && activity.estimatedLng != 0.0 {
                return MapPin(name: activity.placeName, coordinate: CLLocationCoordinate2D(latitude: activity.estimatedLat, longitude: activity.estimatedLng))
            }
            return nil
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                participantsSection
                daySelectorSection
                mapSection
                tipsSection
                Divider().padding(.horizontal)
                itinerarySection
                matchSection
                Spacer(minLength: 50)
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .navigationTitle("Plan Özeti")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            updateMapPosition()
        }
        .alert(isPresented: $showSavedToast) {
            Alert(title: Text("Kaydedildi"), message: Text("Rota başarıyla Profil ve Rotalarım sayfasına eklendi."), dismissButton: .default(Text("Tamam")))
        }
        .overlay(
            Group {
                if showEventToast {
                    VStack {
                        Spacer()
                        Text("Etkinlik başarıyla Keşfet panosuna eklendi!")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                            .padding(.bottom, 40)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation { showEventToast = false }
                        }
                    }
                }
            }
        )
        .sheet(isPresented: $showSharingSelection) {
            SharingSelectionView { mode in
                updateSharingMode(mode)
            }
            .presentationDetents([.height(300)])
        }
        .sheet(item: Binding<AddDayItem?>(
            get: { selectedDayForAdd.map { AddDayItem(dayIndex: $0) } },
            set: { selectedDayForAdd = $0?.dayIndex }
        )) { item in
            let dayNum = editablePlan.itinerary[item.dayIndex].dayNumber
            AddPlaceView(dayNumber: dayNum) { newActivity in
                var updatedPlan = editablePlan
                updatedPlan.itinerary[item.dayIndex].activities.append(newActivity)
                updatedPlan.itinerary[item.dayIndex].activities.sort { $0.timeOfDay < $1.timeOfDay }
                editablePlan = updatedPlan
                savedTripsManager.updateTrip(editablePlan)
            }
        }
    }
    
    // MARK: - Sub-views
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(plan.selectedDestination)
                .font(.largeTitle)
                .fontWeight(.heavy)
            
            Text(plan.tripTitle)
                .font(.title3)
                .foregroundColor(.secondary)
            
            if !isReadOnly {
                let isSaved = savedTripsManager.savedTrips.contains(where: { $0.id == editablePlan.id })
                if !isSaved {
                    Button {
                        withAnimation {
                            savedTripsManager.saveTrip(editablePlan, user: authVM.currentUser)
                            showSavedToast = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "bookmark.fill")
                            Text("Rotayı Kaydet")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#008285"))
                        .cornerRadius(12)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            Text("Rota Kaydedildi").font(.subheadline.bold()).foregroundColor(.green)
                            Spacer()
                        }
                        .padding(.vertical, 8).padding(.horizontal).background(Color.green.opacity(0.1)).cornerRadius(10)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Topluluk Paylaşımı").font(.headline)
                            let sharingText: String = {
                                switch editablePlan.sharingMode {
                                case .fullTrip: return "Bu rota şu an toplulukta herkes tarafından görülebilir."
                                case .specificEvents: return "Sadece seçtiğiniz aktiviteler toplulukta görülebilir."
                                default: return "Bu rota şu an sadece size özel."
                                }
                            }()
                            Text(sharingText).font(.caption).foregroundColor(.secondary)
                            
                            HStack(spacing: 15) {
                                Button(action: { showSharingSelection = true }) {
                                    Text("Değiştir").font(.subheadline.bold()).foregroundColor(Color(hex: "#008285"))
                                }
                                
                                if editablePlan.sharingMode != .none {
                                    Button(role: .destructive, action: { updateSharingMode(.none) }) {
                                        Text("Paylaşımı Durdur").font(.subheadline.bold()).foregroundColor(.red)
                                    }
                                }
                            }
                        }
                        .padding().background(Color.gray.opacity(0.05)).cornerRadius(12)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var participantsSection: some View {
        Group {
            if let tripId = editablePlan.id, savedTripsManager.savedTrips.contains(where: { $0.id == tripId }) {
                TripParticipantsView(trip: savedTripsManager.savedTrips.first(where: { $0.id == tripId }) ?? editablePlan)
                    .padding(.top, 10)
                Divider().padding(.horizontal)
            }
        }
    }
    
    private var daySelectorSection: some View {
        Group {
            if !editablePlan.itinerary.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(editablePlan.itinerary.enumerated()), id: \.offset) { index, day in
                            Button(action: {
                                withAnimation {
                                    selectedDayIndex = index
                                    updateMapPosition()
                                }
                            }) {
                                Text("\(day.dayNumber). Gün")
                                    .font(.subheadline).fontWeight(.bold).padding(.horizontal, 16).padding(.vertical, 10)
                                    .background(selectedDayIndex == index ? Color(hex: "#008285") : Color(.systemGray6))
                                    .foregroundColor(selectedDayIndex == index ? .white : .primary).cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private var mapSection: some View {
        Group {
            if !mapPins.isEmpty {
                Map(position: $mapPosition) {
                    ForEach(mapPins) { pin in
                        Marker(pin.name, coordinate: pin.coordinate).tint(.blue)
                    }
                    if mapPins.count > 1 {
                        MapPolyline(coordinates: mapPins.map { $0.coordinate }).stroke(.blue, lineWidth: 4)
                    }
                }
                .frame(height: 250).cornerRadius(15).padding(.horizontal).shadow(radius: 5)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "map.slash").font(.title2).foregroundColor(.gray.opacity(0.5))
                    Text("Bu gün için konum verisi sağlanamadı.").font(.caption).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity).frame(height: 150).background(Color.gray.opacity(0.05)).cornerRadius(15).padding(.horizontal)
            }
        }
    }
    
    private var tipsSection: some View {
        Group {
            if !editablePlan.generalTips.isEmpty {
                VStack(alignment: .leading) {
                    Text("İpuçları").font(.headline).padding(.horizontal)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(editablePlan.generalTips, id: \.self) { tip in
                                Text(tip).padding().background(Color.blue.opacity(0.1)).cornerRadius(12)
                                    .fixedSize(horizontal: false, vertical: true).frame(width: 250)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    private var itinerarySection: some View {
        Group {
            if editablePlan.itinerary.indices.contains(selectedDayIndex) {
                let dayInfo = editablePlan.itinerary[selectedDayIndex]
                VStack(alignment: .leading, spacing: 12) {
                    Text(dayInfo.dateDescription).font(.headline).foregroundColor(.secondary).padding(.horizontal)
                    
                    ForEach(Array(dayInfo.activities.enumerated()), id: \.offset) { actIndex, activity in
                        ActivityRowView(activity: activity, canEdit: !isReadOnly, onDelete: {
                            deleteActivity(at: IndexSet(integer: actIndex), dayIndex: selectedDayIndex)
                        }, onCreateEvent: {
                            if editablePlan.sharingMode == .none {
                                updateSharingMode(.specificEvents)
                            }
                            createEvent(for: activity, dayInfo: dayInfo)
                        })
                    }
                    
                    if !isReadOnly {
                        Button(action: { selectedDayForAdd = selectedDayIndex }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Yeni Yer Ekle")
                            }
                            .font(.headline).foregroundColor(.blue).padding(.vertical, 8)
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    private var matchSection: some View {
        EmptyView()
    }
    
    // MARK: - Logic
    
    private func updateMapPosition() {
        if let firstPin = mapPins.first {
            let region = MKCoordinateRegion(
                center: firstPin.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            mapPosition = .region(region)
        } else {
            mapPosition = .automatic
        }
    }
    
    private func updateSharingMode(_ mode: SharingMode) {
        editablePlan.sharingMode = mode
        editablePlan.isPublic = (mode == .fullTrip)
        if let tid = editablePlan.id {
            savedTripsManager.updateTripSharingMode(tripId: tid, mode: mode)
        }
    }
    
    private func deleteActivity(at offsets: IndexSet, dayIndex: Int) {
        var updatedPlan = editablePlan
        updatedPlan.itinerary[dayIndex].activities.remove(atOffsets: offsets)
        editablePlan = updatedPlan
        savedTripsManager.updateTrip(editablePlan)
    }
    
    private func createEvent(for activity: Activity, dayInfo: DailyItinerary) {
        guard let user = authVM.currentUser, let uid = Auth.auth().currentUser?.uid else { return }
        
        // Eğer zaten varsa sil (Toggle mantığı)
        if let existing = socialManager.myEvents.first(where: { $0.activityId == activity.id.uuidString && $0.tripId == (editablePlan.id ?? "") }) {
            socialManager.deleteEvent(eventId: existing.id ?? "", userId: uid)
            return
        }
        
        let event = ActivityEvent(
            hostId: uid,
            hostName: user.name ?? "Gezgin",
            hostAvatar: user.profileImageUrl,
            hostProfileWeights: user.profileWeights,
            hostTravelType: user.travelType?.rawValue,
            hostBudget: user.budget?.rawValue,
            hostAge: user.age,
            hostGender: user.gender,
            hostCompanions: user.companions,
            tripId: editablePlan.id ?? UUID().uuidString,
            activityId: activity.id.uuidString,
            destination: editablePlan.selectedDestination,
            placeName: activity.placeName,
            dateDescription: dayInfo.dateDescription,
            timeOfDay: activity.timeOfDay,
            createdAt: Date(),
            sharingMode: .specificEvents
        )
        
        DatabaseManager.shared.saveEvent(event) { error in
            if error == nil {
                DispatchQueue.main.async {
                    withAnimation { self.showEventToast = true }
                    self.socialManager.loadSocialData(for: uid)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ActivityRowView: View {
    let activity: Activity
    var canEdit: Bool
    var onDelete: () -> Void
    var onCreateEvent: () -> Void
    
    @StateObject private var socialManager = SocialManager.shared
    
    var isEventCreated: Bool {
        socialManager.myEvents.contains { $0.activityId == activity.id.uuidString }
    }
    
    var body: some View {
        NavigationLink(destination: PlaceDetailView(activity: activity)) {
            HStack(alignment: .top, spacing: 12) {
                VStack {
                    Text(activity.timeOfDay)
                        .font(.subheadline).fontWeight(.bold).foregroundColor(.blue)
                    Spacer()
                }
                .frame(width: 70, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(activity.placeName).font(.headline)
                        Spacer()
                        Text(activity.costCategory == "Paid" ? "Ücretli" : (activity.costCategory == "Free" ? "Ücretsiz" : activity.costCategory))
                            .font(.caption).padding(4).background(Color.green.opacity(0.2)).cornerRadius(6)
                        
                        if canEdit {
                            Button(action: onDelete) {
                                Image(systemName: "trash").foregroundColor(.red)
                            }
                        }
                    }
                    
                    Text(activity.description).font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.leading)
                    
                    if canEdit {
                        Button(action: onCreateEvent) {
                            HStack {
                                Image(systemName: isEventCreated ? "checkmark.circle.fill" : "person.2.badge.plus")
                                Text(isEventCreated ? "İstek Yayında" : "Bu Etkinlik İçin Arkadaş Bul")
                            }
                            .font(.caption).fontWeight(.semibold).foregroundColor(.white)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(isEventCreated ? Color.green : Color(hex: "#FF5A5F")).cornerRadius(12)
                        }
                        .padding(.top, 4)
                        .buttonStyle(PlainButtonStyle()) // Önemli: NavigationLink içinde butonun çalışması için
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}

struct SharingSelectionView: View {
    let onSelect: (SharingMode) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Topluluk Paylaşım Modu").font(.headline).padding(.top)
            Text("Diğer gezginlerin sizi nasıl bulmasını istersiniz?").font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center).padding(.horizontal)
            
            VStack(spacing: 12) {
                Button {
                    onSelect(.fullTrip)
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Tüm Rota İçin Eşleş").font(.headline)
                            Text("Tüm seyahat boyunca size eşlik edecek bir grup oluşturur.").font(.caption)
                        }
                        Spacer()
                        Image(systemName: "person.2.fill")
                    }
                    .padding().background(Color(hex: "#008285")).foregroundColor(.white).cornerRadius(12)
                }
                
                Button {
                    onSelect(.specificEvents)
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Aktivite Bazlı Eşleş").font(.headline)
                            Text("Sadece seçtiğiniz müze, yemek vb. aktiviteler için arkadaş bulur.").font(.caption)
                        }
                        Spacer()
                        Image(systemName: "list.bullet.indent")
                    }
                    .padding().background(Color.orange).foregroundColor(.white).cornerRadius(12)
                }
            }
            .padding(.horizontal)
            Spacer()
        }
    }
}

struct AddDayItem: Identifiable {
    let id = UUID()
    let dayIndex: Int
}

struct MapPin: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}
