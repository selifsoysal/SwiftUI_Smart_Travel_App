import SwiftUI

struct PlannerView: View {
    // TripMode yerine PlanMode kullanıyoruz
    @State private var selectedMode: PlanMode? = nil

    var body: some View {
        NavigationStack {
            AppContainer {
                VStack(spacing: AppSpacing.lg) {
                    Spacer()

                    VStack(spacing: AppSpacing.md) {
                        Button {
                            selectedMode = .ai
                        } label: {
                            TripModeCard(
                                title: "Yapay Zeka Önerisi",
                                subtitle: "Kişiliğine en uygun rotayı AI belirlesin",
                                iconName: "sparkles",
                                gradient: [Color.blue, Color.purple]
                            )
                        }

                        Button {
                            selectedMode = .manual
                        } label: {
                            TripModeCard(
                                title: "Kendin Seç",
                                subtitle: "Gideceğin lokasyonu sen belirle",
                                iconName: "map.fill",
                                gradient: [Color.orange, Color.red]
                            )
                        }
                    }

                    Spacer()
                }
            }
            .navigationTitle("Seyahatini Planla")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(item: $selectedMode) { mode in
                // Artık mode, PlanMode tipinde olduğu için hatasız çalışır
                TripInputView(mode: mode)
            }
        }
    }
}
