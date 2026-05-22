import SwiftUI
import FirebaseAuth
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var savedTripsManager = SavedTripsManager.shared
    @StateObject private var savedPlacesManager = SavedPlacesManager.shared
    @StateObject var socialManager = SocialManager.shared
    
    @State private var showOnboarding = false
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var profileImage: Image? = nil
    @State private var showCharacterDetails = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    
                    // USER HEADER CARD
                    VStack(spacing: 20) {
                        // Avatar Section
                        VStack {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 100, height: 100)
                                    .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
                                
                                if let url = authVM.currentUser?.profileImageUrl, !url.isEmpty {
                                    AsyncImage(url: URL(string: url)) { img in
                                        img.resizable().scaledToFill()
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                } else if let profileImage = profileImage {
                                    profileImage
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(.white)
                                }
                                
                                // Verified Badge
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundColor(.green)
                                            .background(Color.white.clipShape(Circle()))
                                            .font(.title3)
                                            .shadow(radius: 2)
                                    }
                                }
                                .frame(width: 95, height: 95)
                            }
                            
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                Text("Fotoğraf Değiştir")
                                    .font(.caption.bold())
                                    .foregroundColor(.blue)
                                    .padding(.top, 4)
                            }
                        }
                        .onChange(of: selectedItem) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    if let uiImage = UIImage(data: data) {
                                        // Görüntüyü küçültelim (Performans ve Veritabanı limiti için)
                                        if let compressedData = uiImage.jpegData(compressionQuality: 0.2) {
                                            let base64String = compressedData.base64EncodedString()
                                            let dataURL = "data:image/jpeg;base64,\(base64String)"
                                            
                                            await MainActor.run {
                                                self.profileImage = Image(uiImage: uiImage)
                                                authVM.updateProfileImage(url: dataURL)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        VStack(spacing: 5) {
                            Text(authVM.currentUser?.name ?? "Gezgin")
                                .font(.title3.bold())
                            
                            let dominantProfile = authVM.currentUser?.profileWeights?.max(by: { $0.value < $1.value })?.key ?? "Yeni Gezgin"
                            Text(dominantProfile)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Quick Stats
                        HStack(spacing: 0) {
                            ProfileStatPill(title: "Rotalar", value: "\(savedTripsManager.savedTrips.count)")
                            Divider().frame(height: 30)
                            ProfileStatPill(title: "Etkinlikler", value: "\(socialManager.myEvents.count)")
                        }
                        .padding(.top, 10)
                    }
                    .padding(.vertical, 30)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(25)
                    .padding(.horizontal)
                    .shadow(color: .black.opacity(0.05), radius: 10, y: 5)

                    // SEYAHAT TERCİHLERİ VE KİŞİSEL BİLGİLER
                    if let user = authVM.currentUser {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("KİŞİSEL ÖZELLİKLER")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                                .tracking(1)
                                .padding(.horizontal, 5)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                                ProfileDetailBadge(icon: "person.text.rectangle", title: "Yaş", value: user.age != nil ? "\(user.age!)" : "-")
                                ProfileDetailBadge(icon: "figure.stand", title: "Cinsiyet", value: user.gender ?? "-")
                                ProfileDetailBadge(icon: "airplane.departure", title: "Seyahat Tipi", value: user.travelType?.rawValue ?? "-")
                                ProfileDetailBadge(icon: "banknote", title: "Bütçe", value: user.budget?.rawValue ?? "-")
                            }
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(20)
                        .padding(.horizontal)
                        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                    }

                    // KARAKTER ANALİZİ
                    if let weights = authVM.currentUser?.profileWeights, !weights.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Button(action: { withAnimation { showCharacterDetails.toggle() } }) {
                                HStack {
                                    Text("KARAKTER ANALİZİ")
                                        .font(.caption.bold())
                                        .foregroundColor(.secondary)
                                        .tracking(1)
                                    Spacer()
                                    Image(systemName: showCharacterDetails ? "chevron.up" : "chevron.down")
                                        .font(.caption2.bold())
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if showCharacterDetails {
                                let sortedWeights = weights.sorted { $0.value > $1.value }
                                
                                ForEach(sortedWeights, id: \.key) { profile, weight in
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(profile)
                                                .font(.subheadline.bold())
                                            Spacer()
                                            Text("%\(Int(weight * 100))")
                                                .font(.caption.monospacedDigit())
                                                .foregroundColor(Color(hex: "#008285"))
                                        }
                                        
                                        GeometryReader { geo in
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.gray.opacity(0.1))
                                                    .frame(height: 8)
                                                
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(LinearGradient(colors: [Color(hex: "#008285"), Color(hex: "#00A2A5")], startPoint: .leading, endPoint: .trailing))
                                                    .frame(width: geo.size.width * CGFloat(weight), height: 8)
                                            }
                                        }
                                        .frame(height: 8)
                                    }
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            } else {
                                // Mini summary when collapsed
                                let dominant = weights.max(by: { $0.value < $1.value })?.key ?? ""
                                Text("Ağırlıklı olarak \(dominant) özelliklerine sahipsiniz.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(20)
                        .padding(.horizontal)
                        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                    }

                    // MENU SECTION
                    VStack(spacing: 0) {
                        NavigationLink(destination: TripsView()) {
                            ProfileMenuRowItem(icon: "map.fill", iconColor: .blue, title: "Rotalarım")
                        }
                        Divider().padding(.horizontal)
                        NavigationLink(destination: MyEventsView()) {
                            ProfileMenuRowItem(icon: "calendar", iconColor: .pink, title: "Etkinliklerim")
                        }
                        Divider().padding(.horizontal)
                        Button { showOnboarding = true } label: {
                            ProfileMenuRowItem(icon: "arrow.triangle.2.circlepath", iconColor: .orange, title: "Analizi Tekrarla")
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(20)
                    .padding(.horizontal)
                    .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                    
                    Button {
                        authVM.logout()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Çıkış Yap")
                        }
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }
                    .padding(.top, 10)
                    
                    Spacer(minLength: 40)
                }
                .padding(.top, 10)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Profilim")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showOnboarding) {
                SwipeOnboardingView()
            }
        }
    }
}

struct ProfileStatPill: View {
    let title: String
    let value: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline.bold())
                .foregroundColor(.primary)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ProfileMenuRowItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding()
        .contentShape(Rectangle())
    }
}

struct ProfileDetailBadge: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color(hex: "#008285"))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
            }
            Spacer()
        }
        .padding(10)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}
