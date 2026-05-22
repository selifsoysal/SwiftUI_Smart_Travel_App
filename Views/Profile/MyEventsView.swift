import SwiftUI

@MainActor
struct MyEventsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var events: [ActivityEvent] = []
    @State private var selectedFilter = 0 // 0: Oluşturduklarım, 1: Katıldıklarım
    @Namespace private var animation
    @State private var editingEvent: ActivityEvent?
    @State private var eventToDelete: ActivityEvent?
    @State private var isLoading = false
    
    var filteredEvents: [ActivityEvent] {
        let currentUserId = authVM.currentUser?.id
        if selectedFilter == 0 {
            return events.filter { $0.hostId == currentUserId }
        } else {
            return events.filter { $0.hostId != currentUserId }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Modern Tab Picker (Community Style)
                HStack(spacing: 0) {
                    TabButton(title: "Oluşturduklarım", icon: "pencil.circle.fill", isSelected: selectedFilter == 0, animation: animation) {
                        withAnimation(.spring()) { selectedFilter = 0 }
                    }
                    TabButton(title: "Katıldıklarım", icon: "person.2.circle.fill", isSelected: selectedFilter == 1, animation: animation) {
                        withAnimation(.spring()) { selectedFilter = 1 }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 40)
                        } else if filteredEvents.isEmpty {
                            EmptyEventsState(selectedFilter: selectedFilter)
                        } else {
                            LazyVStack(spacing: 15) {
                                ForEach(filteredEvents) { event in
                                    MyEventCard(event: event, onEdit: { editingEvent = event }, onDelete: { eventToDelete = event })
                                }
                            }
                            .padding()
                        }
                    }
                    .padding(.vertical)
                }
                .background(Color(UIColor.systemGroupedBackground))
            }
            .navigationTitle("Etkinliklerim")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                fetchEvents()
            }
            .sheet(item: $editingEvent) { event in
                EditEventView(event: event) { updatedEvent in
                    DatabaseManager.shared.updateEvent(updatedEvent) { error in
                        if error == nil {
                            fetchEvents()
                        }
                    }
                }
            }
            .alert("Etkinliği Sil", isPresented: Binding(
                get: { eventToDelete != nil },
                set: { if !$0 { eventToDelete = nil } }
            )) {
                Button("İptal", role: .cancel) { eventToDelete = nil }
                Button("Sil", role: .destructive) {
                    if let event = eventToDelete {
                        deleteEvent(event)
                        eventToDelete = nil
                    }
                }
            } message: {
                Text("Bu etkinliği silmek istediğinize emin misiniz?")
            }
        }
    }
    
    private func fetchEvents() {
        guard let userId = authVM.currentUser?.id else { return }
        isLoading = true
        DatabaseManager.shared.fetchUserEvents(userId: userId) { fetchedEvents in
            self.events = fetchedEvents
            self.isLoading = false
        }
    }
    
    private func deleteEvent(_ event: ActivityEvent) {
        guard let id = event.id else { return }
        DatabaseManager.shared.deleteEvent(eventId: id) { error in
            if error == nil {
                fetchEvents()
            }
        }
    }
    
    private func leaveEvent(_ event: ActivityEvent) {
        guard let myId = authVM.currentUser?.id, let eid = event.id else { return }
        DatabaseManager.shared.leaveEvent(eventId: eid, userId: myId) { error in
            if error == nil {
                fetchEvents()
            }
        }
    }
}

struct EmptyEventsState: View {
    let selectedFilter: Int
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: selectedFilter == 0 ? "calendar.badge.exclamationmark" : "person.2.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.3))
            
            Text(selectedFilter == 0 ? "Henüz bir etkinlik oluşturmadınız." : "Henüz bir etkinliğe katılmadınız.")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(selectedFilter == 0 ? "Rotalarınızdaki aktiviteler için arkadaş bularak yeni etkinlikler oluşturun." : "Topluluk kısmından diğer gezginlerin etkinliklerine göz atın.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
}

struct MyEventCard: View {
    let event: ActivityEvent
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.destination.uppercased())
                        .font(.caption2.bold())
                        .foregroundColor(.blue)
                        .tracking(1)
                    
                    Text(event.placeName)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                Spacer()
                
                // Visible Management Menu
                Menu {
                    if event.hostId == authVM.currentUser?.id {
                        if let onEdit = onEdit {
                            Button(action: onEdit) {
                                Label("Düzenle", systemImage: "pencil")
                            }
                        }
                        
                        if let onDelete = onDelete {
                            Button(role: .destructive, action: onDelete) {
                                Label("Sil", systemImage: "trash")
                            }
                        }
                    } else {
                        Button(role: .destructive) {
                            if let myId = authVM.currentUser?.id, let eid = event.id {
                                DatabaseManager.shared.leaveEvent(eventId: eid, userId: myId) { _ in }
                            }
                        } label: {
                            Label("Ayrıl", systemImage: "person.badge.minus")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title3)
                        .foregroundColor(.gray.opacity(0.3))
                        .padding(4)
                }
                
                Text(event.timeOfDay)
                    .font(.caption.bold())
                    .padding(6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    .foregroundColor(.blue)
            }
            
            Text(event.dateDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Label("\(event.hostName)", systemImage: "person.circle.fill")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let count = event.participants?.count, count > 0 {
                    Text("\(count) Katılımcı")
                        .font(.caption2.bold())
                        .foregroundColor(Color(hex: "#008285"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(hex: "#008285").opacity(0.1))
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
}
