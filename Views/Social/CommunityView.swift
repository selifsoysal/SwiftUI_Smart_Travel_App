import SwiftUI

struct CommunityView: View {
    @State private var selectedTab = 0 // 0: Rotalar, 1: Etkinlikler
    @Namespace private var animation
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Modern Tab Picker
                HStack(spacing: 0) {
                    TabButton(title: "Rotalar", icon: "map.fill", isSelected: selectedTab == 0, animation: animation) {
                        withAnimation(.spring()) { selectedTab = 0 }
                    }
                    TabButton(title: "Etkinlikler", icon: "calendar", isSelected: selectedTab == 1, animation: animation) {
                        withAnimation(.spring()) { selectedTab = 1 }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
                
                if selectedTab == 0 {
                    SharedFeedView(contentType: .trips)
                        .transition(.move(edge: .leading))
                } else {
                    SharedFeedView(contentType: .events)
                        .transition(.move(edge: .trailing))
                }
            }
            .navigationTitle("Topluluk")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        }
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    var badgeCount: Int = 0
    let animation: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: icon)
                        if badgeCount > 0 {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .offset(x: 4, y: -4)
                        }
                    }
                    Text(title)
                        .fontWeight(isSelected ? .bold : .medium)
                }
                .foregroundColor(isSelected ? Color(hex: "#008285") : .secondary)
                
                ZStack {
                    Capsule()
                        .fill(Color.clear)
                        .frame(height: 3)
                    if isSelected {
                        Capsule()
                            .fill(Color(hex: "#008285"))
                            .frame(height: 3)
                            .matchedGeometryEffect(id: "tab", in: animation)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

enum CommunityContentType {
    case trips, events
}

struct SharedFeedView: View {
    let contentType: CommunityContentType
    @EnvironmentObject var authVM: AuthViewModel
    @State private var selectedRouteFilter = 0 // 0: Tüm Rotalar, 1: Eşleşen Rotalar
    
    @State private var allPublicTrips: [GeminiTripPlan] = []
    @State private var publicEvents: [ActivityEvent] = []
    @State private var isLoading = true
    
    var filteredTrips: [GeminiTripPlan] {
        let othersTrips = allPublicTrips.filter { 
            $0.userId != authVM.currentUser?.id && 
            ($0.sharingMode == .fullTrip || ($0.sharingMode == nil && $0.isPublic == true))
        }
        if selectedRouteFilter == 0 {
            return othersTrips
        } else {
            let myDestinations = SavedTripsManager.shared.savedTrips.compactMap { $0.selectedDestination.lowercased() }
            return othersTrips.filter { trip in
                myDestinations.contains(where: { trip.selectedDestination.lowercased().contains($0) || $0.contains(trip.selectedDestination.lowercased()) })
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if contentType == .trips {
                // Route Filter Picker
                HStack(spacing: 12) {
                    FilterChip(title: "Tüm Rotalar", isSelected: selectedRouteFilter == 0) {
                        selectedRouteFilter = 0
                    }
                    FilterChip(title: "Eşleşen Rotalar", isSelected: selectedRouteFilter == 1) {
                        selectedRouteFilter = 1
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if isLoading {
                        VStack(spacing: 15) {
                            ProgressView()
                            Text("Yükleniyor...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                    } else {
                        if contentType == .events {
                            if publicEvents.isEmpty {
                                EmptyContentView(message: "Henüz bir etkinlik bulunmuyor.")
                            } else {
                                LazyVStack(spacing: 15) {
                                    let othersEvents = publicEvents.filter { 
                                        $0.hostId != authVM.currentUser?.id && 
                                        ($0.sharingMode == .specificEvents || $0.sharingMode == nil) 
                                    }
                                    if othersEvents.isEmpty {
                                        EmptyContentView(message: "Henüz bir etkinlik bulunmuyor.")
                                    } else {
                                        ForEach(othersEvents) { event in
                                            CommunityEventCard(event: event)
                                                .padding(.horizontal)
                                        }
                                    }
                                }
                            }
                        } else {
                            if filteredTrips.isEmpty {
                                EmptyContentView(message: selectedRouteFilter == 0 ? "Henüz bir rota bulunmuyor." : "Planlarınla eşleşen rota bulunamadı.")
                            } else {
                                LazyVStack(spacing: 15) {
                                    ForEach(filteredTrips) { trip in
                                        CommunityTripCard(trip: trip)
                                            .padding(.horizontal)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .task {
            allPublicTrips = await SavedTripsManager.getAllTripsGlobal()
            DatabaseManager.shared.fetchUpcomingEvents { events in
                self.publicEvents = events
                self.isLoading = false
            }
        }
    }
}


struct CommunityEventCard: View {
    let event: ActivityEvent
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var socialManager = SocialManager.shared
    @State private var matchResult: MatchingScoreDetails?
    @State private var showMatchDetails = false
    
    private var connectionStatus: ConnectionStatus? {
        guard let myId = authVM.currentUser?.id else { return nil }
        return socialManager.getRequestStatus(between: myId, and: event.hostId, tripId: event.tripId, eventId: event.id, tripDestination: event.destination)
    }
    
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
                    
                    if let count = event.participants?.count, count > 0 {
                        Text("+\(count) kişi katıldı")
                            .font(.caption2.bold())
                            .foregroundColor(.blue)
                    }
                }
                Spacer()
                Text(event.timeOfDay)
                    .font(.caption.bold())
                    .padding(6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Text(event.dateDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    if let avatar = event.hostAvatar, !avatar.isEmpty {
                        AsyncImage(url: URL(string: avatar)) { img in
                            img.resizable().scaledToFill()
                        } placeholder: {
                            Circle().fill(Color.gray.opacity(0.2))
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundColor(.gray)
                    }
                    Text(event.hostName)
                        .font(.caption.bold())
                    
                    if let match = matchResult, match.score > 0 {
                        Button(action: { showMatchDetails = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "brain.head.profile")
                                    .font(.caption2)
                                Text("%\(match.score) Uyum")
                                    .font(.caption2.bold())
                                Image(systemName: "info.circle")
                                    .font(.system(size: 8))
                            }
                            .foregroundColor(Color(hex: "#FF5A5F"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: "#FF5A5F").opacity(0.1))
                            .cornerRadius(4)
                        }
                        .alert(isPresented: $showMatchDetails) {
                            Alert(
                                title: Text("Uyum Analizi"),
                                message: Text(match.explanations.joined(separator: "\n\n")),
                                dismissButton: .default(Text("Tamam"))
                            )
                        }
                    }
                }
                Spacer()
                
                if event.hostId != authVM.currentUser?.id {
                    if connectionStatus == .accepted {
                        let targetTraveler = Traveler(
                            id: event.hostId,
                            username: event.hostName,
                            age: 0,
                            budget: .medium,
                            plannedTrips: []
                        )
                        let conns = socialManager.getGroupConnections(for: event.destination, or: event.tripId)
                        
                        NavigationLink(destination: ChatDetailView(targetTraveler: targetTraveler, providedConnections: conns)) {
                            Text("Mesaj Gönder")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 6)
                                .background(Color(hex: "#008285"))
                                .cornerRadius(10)
                        }
                    } else if connectionStatus == .pending {
                        Button(action: {
                            if let myId = authVM.currentUser?.id {
                                if let pendingReq = socialManager.getPendingRequest(between: myId, and: event.hostId, tripId: event.tripId, tripDestination: event.destination) {
                                    socialManager.withdrawRequest(requestId: pendingReq.id)
                                }
                            }
                        }) {
                            Text("İsteği Geri Çek")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 6)
                                .background(Color.orange.opacity(0.8))
                                .cornerRadius(10)
                        }
                    } else {
                        Button(action: {
                            guard let myId = authVM.currentUser?.id else { return }
                            socialManager.sendRequest(from: myId, to: event.hostId, tripId: event.tripId, eventId: event.id, tripDestination: event.destination, requestType: "event")
                        }) {
                            Text("Mesaj İsteği")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 6)
                                .background(Color(hex: "#FF5A5F"))
                                .cornerRadius(10)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
        .onAppear {
            if let myId = authVM.currentUser?.id {
                socialManager.loadSocialData(for: myId)
                
                // Eşleşme skoru hesapla
                if let user = authVM.currentUser {
                    Task {
                        let res = await NeuralMatchingEngine.shared.calculateEventMatch(user: user, event: event)
                        await MainActor.run {
                            self.matchResult = res
                        }
                    }
                }
            }
        }

    }
}

struct CommunityTripCard: View {
    let trip: GeminiTripPlan
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var socialManager = SocialManager.shared
    @State private var showDetail = false
    @State private var matchResult: MatchingScoreDetails?
    @State private var showMatchDetails = false
    
    private var connectionStatus: ConnectionStatus? {
        guard let myId = authVM.currentUser?.id, let creatorId = trip.userId else { return nil }
        return socialManager.getRequestStatus(between: myId, and: creatorId, tripId: trip.id, tripDestination: trip.selectedDestination)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header: User & Destination
            HStack(spacing: 12) {
                if let avatar = trip.creatorAvatar, !avatar.isEmpty {
                    AsyncImage(url: URL(string: avatar)) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        Circle().fill(Color.gray.opacity(0.2))
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(trip.creatorName?.prefix(1) ?? "G")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(trip.creatorName ?? "Gizemli Gezgin")
                        .font(.subheadline.bold())
                    Text(trip.selectedDestination)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                if let match = matchResult, match.score > 0 {
                    Button(action: { showMatchDetails = true }) {
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.1), lineWidth: 3)
                                .frame(width: 40, height: 40)
                            Circle()
                                .trim(from: 0, to: CGFloat(match.score) / 100)
                                .stroke(Color(hex: "#FF5A5F"), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .frame(width: 40, height: 40)
                                .rotationEffect(.degrees(-90))
                            VStack(spacing: 0) {
                                Text("%\(match.score)")
                                    .font(.system(size: 10, weight: .bold))
                                Image(systemName: "info.circle")
                                    .font(.system(size: 6))
                            }
                            .foregroundColor(Color(hex: "#FF5A5F"))
                        }
                    }
                    .sheet(isPresented: $showMatchDetails) {
                        MatchAnalysisView(details: match)
                    }
                } else {
                    Image(systemName: "airplane")
                        .foregroundColor(.blue.opacity(0.5))
                }
            }
            
            // Trip Title
            Text(trip.tripTitle)
                .font(.headline)
                .lineLimit(2)
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: {
                    showDetail = true
                }) {
                    Text("Detay Gör")
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                }
                
                if let creatorId = trip.userId, creatorId != authVM.currentUser?.id {
                    if connectionStatus == .accepted {
                        let targetTraveler = Traveler(
                            id: creatorId,
                            username: trip.creatorName ?? "Gezgin",
                            age: 0,
                            budget: .medium,
                            plannedTrips: []
                        )
                        let conns = socialManager.getGroupConnections(for: trip.selectedDestination, or: trip.id)
                        
                        NavigationLink(destination: ChatDetailView(targetTraveler: targetTraveler, providedConnections: conns)) {
                            Text("Mesaj Gönder")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(hex: "#008285"))
                                .cornerRadius(12)
                        }
                    } else if connectionStatus == .pending {
                        Button(action: {
                            if let myId = authVM.currentUser?.id {
                                if let pendingReq = socialManager.getPendingRequest(between: myId, and: creatorId, tripId: trip.id, tripDestination: trip.selectedDestination) {
                                    socialManager.withdrawRequest(requestId: pendingReq.id)
                                }
                            }
                        }) {
                            Text("İsteği Geri Çek")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.orange.opacity(0.8))
                                .cornerRadius(12)
                        }
                    } else {
                        Button(action: {
                            guard let myId = authVM.currentUser?.id else { return }
                            socialManager.sendRequest(from: myId, to: creatorId, tripId: trip.id, tripDestination: trip.selectedDestination, requestType: "trip")
                        }) {
                            Text("Mesaj İsteği")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(hex: "#FF5A5F"))
                                .cornerRadius(12)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
        .sheet(isPresented: $showDetail) {
            CommunityTripDetailView(trip: trip)
        }
        .onAppear {
            if let myId = authVM.currentUser?.id {
                socialManager.loadSocialData(for: myId)
                
                // Eşleşme skoru hesapla
                if let user = authVM.currentUser {
                    Task {
                        let res = await NeuralMatchingEngine.shared.calculateTripMatch(user: user, trip: trip)
                        await MainActor.run {
                            self.matchResult = res
                        }
                    }
                }
            }
        }

    }
}

struct EmptyContentView: View {
    let message: String
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "tray")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.3))
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}
