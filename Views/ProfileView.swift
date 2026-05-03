import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var savedTripsManager = SavedTripsManager.shared
    @StateObject private var savedPlacesManager = SavedPlacesManager.shared
    
    @State private var showOnboarding = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    
                    // USER CARD
                    VStack(spacing: 20) {
                        // Avatar Section
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 120, height: 120)
                                .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
                            
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.white)
                            
                            // Badge
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.green)
                                        .background(Color.white.clipShape(Circle()))
                                        .font(.title2)
                                        .shadow(radius: 2)
                                }
                            }
                            .frame(width: 115, height: 115)
                        }
                        
                        VStack(spacing: 8) {
                            Text(authVM.currentUser?.name.uppercased() ?? "PROFILİN")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .tracking(1.5)
                            
                            Text(authVM.currentUser?.travelProfile?.rawValue ?? "Gezgin")
                                .font(.title.bold())
                                .foregroundColor(.primary)
                        }
                        
                        // Stats Card
                        HStack(spacing: 0) {
                            ProfileStat(title: "Rotalar", value: "\(savedTripsManager.savedTrips.count)")
                            Divider().frame(height: 40)
                            ProfileStat(title: "Favoriler", value: "\(savedPlacesManager.savedPlaces.count)")
                            Divider().frame(height: 40)
                            ProfileStat(title: "Seviye", value: "Başlangıç")
                        }
                        .padding(.vertical, 15)
                        .frame(maxWidth: .infinity)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(20)
                        .padding(.horizontal)
                        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                    }
                    .padding(.top, 20)
                    
                    // Settings List
                    VStack(spacing: 0) {
                        NavigationLink(destination: TripsView()) {
                            ProfileMenuRow(icon: "map.fill", iconColor: .blue, title: "Kayıtlı Rotalarım")
                        }
                        Divider().padding(.leading, 60)
                        
                        NavigationLink(destination: FavoritePlacesView()) {
                            ProfileMenuRow(icon: "heart.fill", iconColor: .red, title: "Favori Mekanlarım")
                        }
                        Divider().padding(.leading, 60)
                        
                        Button {
                            showOnboarding = true
                        } label: {
                            ProfileMenuRow(icon: "arrow.triangle.2.circlepath", iconColor: .orange, title: "Seyahat Tipimi Tekrar Belirle")
                        }
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(20)
                    .padding(.horizontal)
                    .shadow(color: .black.opacity(0.03), radius: 10, y: 5)
                    
                    Spacer(minLength: 20)
                    
                    Button {
                        // Çıkış yapıldığında
                        authVM.logout()
                    } label: {
                        Text("Çıkış Yap")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(15)
                            .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            .navigationTitle("Profilim")
            .navigationBarTitleDisplayMode(.large)
            .fullScreenCover(isPresented: $showOnboarding) {
                SwipeOnboardingView()
            }
        }
    }
}

// Yardımcı View Parçaları
struct ProfileStat: View {
    let title: String
    let value: String
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ProfileMenuRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundColor(iconColor)
            }
            
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Color.gray.opacity(0.5))
        }
        .padding()
        .contentShape(Rectangle())
    }
}
