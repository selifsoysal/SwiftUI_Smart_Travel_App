import SwiftUI

struct TravelResultView: View {
    let weights: [String: Double]
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    private var sortedProfiles: [(key: String, value: Double)] {
        weights.sorted { $0.value > $1.value }
    }

    private var topProfile: String {
        sortedProfiles.first?.key ?? "Kültür Kaşifi"
    }

    @State private var selectedType: TravelType = .solo
    @State private var selectedBudget: BudgetRange = .medium
    @State private var companions: [Companion] = []
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    VStack(spacing: 8) {
                        Text("ANALİZ TAMAMLANDI")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.blue)
                            .kerning(2)
                        
                        Text("Karakteristik Gezgin Profilin")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)

                    // MARK: - Badge Area
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.05))
                                .frame(width: 140, height: 140)
                            
                            Text(getEmoji(for: topProfile))
                                .font(.system(size: 60))
                        }

                        VStack(spacing: 6) {
                            Text(topProfile.uppercased())
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                            
                            Text(getDescription(for: topProfile))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    }

                    // MARK: - Preferences Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Seyahat Tercihlerin")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Nasıl Seyahat Edersin?").font(.subheadline.bold())
                            Picker("Gezgin Tipi", selection: $selectedType) {
                                ForEach(TravelType.allCases) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: selectedType) { newValue in
                                if newValue == .solo {
                                    companions = []
                                } else if companions.isEmpty {
                                    companions = [Companion(age: 25, gender: "Kadın")]
                                }
                            }
                        }
                        
                        if selectedType != .solo {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Yanındakiler").font(.subheadline.bold())
                                    Spacer()
                                    Button(action: { companions.append(Companion(age: 25, gender: "Kadın")) }) {
                                        Label("Ekle", systemImage: "plus.circle.fill")
                                            .font(.caption.bold())
                                    }
                                }
                                
                                ForEach(0..<companions.count, id: \.self) { index in
                                    HStack {
                                        Picker("Yaş", selection: $companions[index].age) {
                                            ForEach(18...80, id: \.self) { age in
                                                Text("\(age)").tag(age)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        
                                        Picker("Cinsiyet", selection: $companions[index].gender) {
                                            Text("Kadın").tag("Kadın")
                                            Text("Erkek").tag("Erkek")
                                        }
                                        .pickerStyle(.menu)
                                        
                                        Button(action: { companions.remove(at: index) }) {
                                            Image(systemName: "minus.circle.fill").foregroundColor(.red)
                                        }
                                    }
                                    .padding(8)
                                    .background(Color.gray.opacity(0.05))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Bütçen?").font(.subheadline.bold())
                            Picker("Bütçe", selection: $selectedBudget) {
                                ForEach(BudgetRange.allCases) { budget in
                                    Text(budget.displayName).tag(budget)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .padding(.horizontal, 30)

                    Button(action: {
                        withAnimation {
                            authVM.completeOnboarding(
                                with: weights,
                                travelType: selectedType,
                                budget: selectedBudget,
                                companions: companions
                            )
                            dismiss()
                        }
                    }) {
                        HStack {
                            Text("Keşfetmeye Başla")
                            Image(systemName: "arrow.right")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.blue)
                        .cornerRadius(18)
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private func getEmoji(for profileName: String) -> String {
        if profileName.contains("Kültür") { return "🏛️" }
        if profileName.contains("Doğa") { return "🏔️" }
        if profileName.contains("Lezzet") { return "🍝" }
        if profileName.contains("Lüks") { return "💎" }
        if profileName.contains("Tarih") { return "📜" }
        return "🌍"
    }

    private func getDescription(for profileName: String) -> String {
        if profileName.contains("Kültür") { return "Sen bir kültür elçisisin! Müzeler ve şehir ruhu tam sana göre." }
        if profileName.contains("Doğa") { return "Doğa senin evin! Dağlar ve temiz hava ile yenilenmeye hazırsın." }
        if profileName.contains("Lezzet") { return "Midenin sesini dinliyorsun! En lezzetli duraklar seni bekliyor." }
        if profileName.contains("Lüks") { return "Konfor senin için öncelik! Premium deneyimlerin tadını çıkar." }
        if profileName.contains("Tarih") { return "Geçmişin izindesin! Antik kentler senin tutkun." }
        return "Keşfetmeyi seven bir ruhun var!"
    }
}
