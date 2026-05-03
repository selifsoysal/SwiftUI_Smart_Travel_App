import SwiftUI

struct SwipeOnboardingView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = SwipeViewModel()
    
    @State private var offset: CGSize = .zero
    @State private var showResult = false
    @State private var resultProfile: TravelProfile?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gezgin Profilini Oluştur")
                        .font(.title2)
                        .fontWeight(.heavy)
                    Text("Tarzını keşfetmek için sağa veya sola kaydır")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(vm.items.count) Kaldı")
                    .font(.caption2.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.15))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 25)
            .padding(.top, 20)

            Spacer()

            // MARK: - Card Stack
            if vm.isLoading {
                VStack(spacing: 15) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Harika rotalar yükleniyor...")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            } else if let item = vm.currentItem {
                ZStack(alignment: .bottomLeading) {
                    GeometryReader { geo in
                        AsyncImage(url: URL(string: item.imageUrl)) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: geo.size.width, height: geo.size.height)
                                    .clipped()
                            } else {
                                Rectangle().fill(Color(UIColor.secondarySystemFill))
                            }
                        }
                    }
                    .frame(height: 500) // Ekrandan taşmaması için maxHeight / height ayarı
                    .clipShape(RoundedRectangle(cornerRadius: 35, style: .continuous))
                    
                    LinearGradient(
                        colors: [.black.opacity(0.8), .clear, .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: 500)
                    .clipShape(RoundedRectangle(cornerRadius: 35, style: .continuous))
                    
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.red)
                            Text("Popüler Destinasyon")
                                .foregroundColor(.white)
                        }
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(.bottom, 5)
                        
                        Text(item.title)
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                    }
                    .padding(30)
                }
                .padding(.horizontal, 20)
                .offset(x: offset.width, y: offset.height * 0.4)
                .rotationEffect(.degrees(Double(offset.width / 15)))
                .gesture(
                    DragGesture()
                        .onChanged { offset = $0.translation }
                        .onEnded { value in
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                if value.translation.width > 120 {
                                    offset = CGSize(width: 500, height: 0)
                                    vm.like()
                                    resetOffset()
                                } else if value.translation.width < -120 {
                                    offset = CGSize(width: -500, height: 0)
                                    vm.dislike()
                                    resetOffset()
                                } else {
                                    offset = .zero
                                }
                            }
                        }
                )
            }

            Spacer()

            // MARK: - Action Buttons
            HStack(spacing: 50) {
                Button(action: { handleManualSwipe(isLike: false) }) {
                    ZStack {
                        Circle()
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                            .frame(width: 75, height: 75)
                            .shadow(color: .black.opacity(0.08), radius: 15, y: 10)
                        Image(systemName: "xmark")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.red)
                    }
                }

                Button(action: { handleManualSwipe(isLike: true) }) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 85, height: 85)
                            .shadow(color: .green.opacity(0.3), radius: 20, y: 10)
                        Image(systemName: "heart.fill")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.bottom, 50)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            vm.loadData()
            vm.onFinish = { profile in
                self.resultProfile = profile
                self.showResult = true
            }
        }
        .fullScreenCover(isPresented: $showResult, onDismiss: {
            dismiss()
        }) {
            TravelResultView(profile: resultProfile ?? .culture)
        }
    }

    private func resetOffset() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            offset = .zero
        }
    }

    private func handleManualSwipe(isLike: Bool) {
        withAnimation(.easeOut(duration: 0.3)) {
            offset.width = isLike ? 500 : -500
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if isLike { vm.like() } else { vm.dislike() }
            offset = .zero
        }
    }
}
