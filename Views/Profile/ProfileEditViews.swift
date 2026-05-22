import SwiftUI

struct EditTripView: View {
    @Environment(\.dismiss) var dismiss
    @State var trip: GeminiTripPlan
    var onSave: (GeminiTripPlan) -> Void
    
    @State private var editedTitle: String
    @State private var isPublic: Bool
    
    init(trip: GeminiTripPlan, onSave: @escaping (GeminiTripPlan) -> Void) {
        self._trip = State(initialValue: trip)
        self._editedTitle = State(initialValue: trip.tripTitle)
        self._isPublic = State(initialValue: trip.isPublic ?? false)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Rota Bilgileri") {
                    TextField("Rota Adı", text: $editedTitle)
                    Toggle("Toplulukta Paylaş", isOn: $isPublic)
                }
                
                Section("Detaylar") {
                    Text("Hedef: \(trip.selectedDestination)")
                        .foregroundColor(.secondary)
                    if let start = trip.startDate, let end = trip.endDate {
                        Text("\(start.formatted(date: .abbreviated, time: .omitted)) - \(end.formatted(date: .abbreviated, time: .omitted))")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Rotayı Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        var updatedTrip = trip
                        updatedTrip.tripTitle = editedTitle
                        updatedTrip.isPublic = isPublic
                        onSave(updatedTrip)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct EditEventView: View {
    @Environment(\.dismiss) var dismiss
    @State var event: ActivityEvent
    var onSave: (ActivityEvent) -> Void
    
    @State private var editedPlaceName: String
    @State private var editedTime: String
    
    init(event: ActivityEvent, onSave: @escaping (ActivityEvent) -> Void) {
        self._event = State(initialValue: event)
        self._editedPlaceName = State(initialValue: event.placeName)
        self._editedTime = State(initialValue: event.timeOfDay)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Etkinlik Bilgileri") {
                    TextField("Mekan Adı", text: $editedPlaceName)
                    TextField("Saat", text: $editedTime)
                }
                
                Section("Konum") {
                    Text(event.destination)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Etkinliği Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        var updatedEvent = event
                        updatedEvent.placeName = editedPlaceName
                        updatedEvent.timeOfDay = editedTime
                        onSave(updatedEvent)
                        dismiss()
                    }
                }
            }
        }
    }
}
