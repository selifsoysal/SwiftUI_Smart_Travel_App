import SwiftUI
import Combine

struct TripInputView: View {
    let mode: PlanMode
    
    @StateObject private var viewModel = TripViewModel()
    
    @State private var city: String = ""
    @State private var budget: Double = 10000
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
    @State private var travelType: String = "Yalnız"
    
    let travelTypes = ["Yalnız", "Çift", "Aile", "Arkadaş"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                
                // HEADER
                VStack(spacing: 8) {
                    Image(systemName: mode == .ai ? "sparkles.tv" : "map.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                        .padding(.top, 10)
                    
                    Text(mode == .ai ? "Yapay Zeka Planı" : "Manuel Plan")
                        .font(.title2.bold())
                    
                    Text("Detayları seç ve gerisini bize bırak.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // HEDEF SEÇİMİ (MANUEL İÇİN)
                if mode == .manual {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("GİDECEĞİNİZ YER")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Şehir veya Ülke girin...", text: $city)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(15)
                        .shadow(color: .black.opacity(0.05), radius: 5, y: 3)
                    }
                }
                
                // DETAYLAR
                VStack(alignment: .leading, spacing: 20) {
                    Text("SEYAHAT DETAYLARI")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    // Seyahat Tarihleri
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Ne Zaman Gideceksin?")
                            .font(.subheadline.bold())
                        
                        DatePicker("Başlangıç Tarihi", selection: $startDate, displayedComponents: .date)
                        DatePicker("Bitiş Tarihi", selection: $endDate, in: startDate..., displayedComponents: .date)
                    }
                    
                    Divider()
                    
                    // Bütçe
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Bütçe")
                                .font(.subheadline.bold())
                            Spacer()
                            Text("\(Int(budget)) ₺")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                        
                        Slider(value: $budget, in: 1000...100000, step: 500)
                            .accentColor(.blue)
                    }
                    
                    Divider()
                    
                    // Kiminle
                    VStack(alignment: .leading) {
                        Text("Kiminle Gidiyorsun?")
                            .font(.subheadline.bold())
                        Picker("Kiminle", selection: $travelType) {
                            ForEach(travelTypes, id: \.self) { Text($0) }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(15)
                .shadow(color: .black.opacity(0.05), radius: 5, y: 3)
                
                Spacer(minLength: 20)
                
                // BUTON
                Button(action: generateTrip) {
                    HStack {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 8)
                            Text("Oluşturuluyor...")
                        } else {
                            Text("Harika Rota Oluştur")
                        }
                        Spacer()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .background(viewModel.isLoading ? Color.blue.opacity(0.7) : Color.blue)
                    .cornerRadius(15)
                    .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
                }
                .disabled(viewModel.isLoading || (mode == .manual && city.isEmpty))
                
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: Binding(
            get: { viewModel.generatedPlan != nil },
            set: { if !$0 { viewModel.generatedPlan = nil } }
        )) {
            if let plan = viewModel.generatedPlan {
                TripResultView(plan: plan)
            }
        }
        .alert(isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Alert(
                title: Text("Hata"),
                message: Text(viewModel.errorMessage ?? "Bilinmeyen hata"),
                dismissButton: .default(Text("Tamam"))
            )
        }
    }

    private func generateTrip() {
        let rawProfile = UserDefaults.standard.string(forKey: "travelType") ?? "Kültür"
        let destinationToUse = city.isEmpty ? nil : city
        
        let computedDays = max(1, Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1)
        
        viewModel.generateTrip(
            destination: destinationToUse,
            budget: "\(Int(budget)) ₺",
            days: computedDays,
            travelType: travelType,
            travelProfile: rawProfile,
            startDate: startDate,
            endDate: endDate
        )
    }
}

