import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var router: AppRouter
    @StateObject private var vm = DiscoverViewModel()
    @StateObject private var socialManager = SocialManager.shared

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 25) {

                    // 1. HERO / SEARCH AREA
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nereye gitmek\nistersin?")
                            .font(.system(size: 32, weight: .bold))
                            .lineSpacing(4)

                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Şehir, müze veya aktivite ara...", text: $vm.searchText)
                                .autocorrectionDisabled()
                                .submitLabel(.search)
                                .onSubmit {
                                    Task { await vm.searchDestinations(query: vm.searchText) }
                                }
                            if vm.isSearching {
                                ProgressView().scaleEffect(0.7)
                            } else if !vm.searchText.isEmpty {
                                Button(action: {
                                    vm.searchText = ""
                                    vm.searchResults = []
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .onChange(of: vm.searchText) { newValue in
                        if newValue.isEmpty {
                            vm.searchResults = []
                        } else {
                            Task {
                                try? await Task.sleep(nanoseconds: 600_000_000)
                                if vm.searchText == newValue {
                                    await vm.searchDestinations(query: newValue)
                                }
                            }
                        }
                    }

                    // SEARCH RESULTS LIST — appears right under the search bar
                    if !vm.searchText.isEmpty && !vm.isSearching && !vm.searchResults.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(vm.searchResults) { dest in
                                Button {
                                    router.navigateToPlanner(with: dest.city)
                                    vm.searchText = ""
                                    vm.searchResults = []
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(Color(hex: "#008285"))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(dest.city)
                                                .font(.subheadline.bold())
                                                .foregroundColor(.primary)
                                            Text(dest.country)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "arrow.right.circle")
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                }
                                if dest.id != vm.searchResults.last?.id {
                                    Divider().padding(.leading, 52)
                                }
                            }
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
                        .padding(.horizontal)
                    }
                    if vm.searchText.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(vm.categories, id: \.self) { category in
                                    CategoryPill(title: category, isSelected: vm.selectedCategory == category) {
                                        vm.selectedCategory = category
                                        Task { await vm.fetchRecommended(for: category, currentUser: authVM.currentUser) }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    if vm.isLoading {
                        VStack {
                            ProgressView()
                            Text("Senin için harika yerler buluyoruz...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                        .padding(.top, 50)
                    } else {

                        // 3. RECOMMENDED FOR YOU — horizontal cards, above Popular
                        if !vm.filteredRecommended.isEmpty {
                            VStack(alignment: .leading, spacing: 15) {
                                HStack {
                                    Text(vm.searchText.isEmpty ? "Senin İçin Önerilenler" : "Önerilenler")
                                        .font(.title3.bold())
                                    Spacer()
                                }
                                .padding(.horizontal)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(vm.filteredRecommended) { dest in
                                            Button {
                                                router.navigateToPlanner(with: dest.city)
                                            } label: {
                                                DestinationCardView(destination: dest)
                                                    .frame(width: 260)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }

                        // 4. POPULAR DESTINATIONS / SEARCH RESULTS
                        if !vm.filteredTrending.isEmpty {
                            VStack(alignment: .leading, spacing: 15) {
                                HStack {
                                    Text(vm.searchText.isEmpty ? "Trend Rotalar" : "Arama Sonuçları")
                                        .font(.title3.bold())
                                    Spacer()
                                }
                                .padding(.horizontal)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(vm.filteredTrending) { dest in
                                            Button {
                                                router.navigateToPlanner(with: dest.city)
                                            } label: {
                                                DestinationCardView(destination: dest)
                                                    .frame(width: 280)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }

                        // Empty state when search has no results
                        if vm.filteredTrending.isEmpty && vm.filteredRecommended.isEmpty && !vm.searchText.isEmpty && !vm.isSearching {
                            VStack(spacing: 16) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray.opacity(0.4))
                                Text("\"\(vm.searchText)\" için sonuç bulunamadı.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                        }
                    }
                }
                .padding(.bottom, 30)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if let user = authVM.currentUser {
                        HStack(spacing: 10) {
                            if let url = user.profileImageUrl, !url.isEmpty {
                                AsyncImage(url: URL(string: url)) { img in
                                    img.resizable().scaledToFill()
                                } placeholder: {
                                    Circle().fill(Color.gray.opacity(0.2))
                                }
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Text(user.name?.prefix(1) ?? "U")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Merhaba,")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                Text(user.name ?? "Gezgin")
                                    .font(.system(size: 14, weight: .bold))
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        router.navigateToNotifications()
                    }) {
                        ZStack {
                            Image(systemName: "bell.fill")
                                .font(.title3)
                                .foregroundColor(.primary)
                            
                            if socialManager.totalUnreadCount > 0 {
                                Text("\(socialManager.totalUnreadCount)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(5)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: 10, y: -10)
                            }
                        }
                    }
                }
            }
            .task {
                await vm.load(currentUser: authVM.currentUser)
                if let userId = authVM.currentUser?.id {
                    socialManager.loadSocialData(for: userId)
                }
                // İlk açılışta önerilenleri de yükle
                await vm.fetchRecommended(for: "Tümü", currentUser: authVM.currentUser)
            }
        }
    }
}

// Sub-views
struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}
