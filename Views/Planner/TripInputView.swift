import SwiftUI
import Combine

struct TripInputView: View {
    let mode: PlanMode
    let defaultCity: String?

    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel = TripViewModel()

    // UI State
    @State private var currentStep: Int
    var totalSteps: Int { mode == .manual ? 4 : 3 }

    // User Inputs
    @State private var city: String
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()

    @State private var accommodation: String = "Otel"
    let accommodations = ["Otel", "Hostel", "Airbnb", "Pansiyon", "Farketmez"]

    @State private var transportation: String = "Toplu Taşıma"
    let transportations = ["Toplu Taşıma", "Araç Kiralama", "Yürüyüş", "Farketmez"]

    @State private var countryCount: Int = 1
    @State private var budgetString: String = "10000"
    @State private var travelType: String = "Yalnız"
    let travelTypes = ["Yalnız", "Partner/Eş", "Aile", "Arkadaş Grubu"]

    @State private var companionCount: Int = 1
    @State private var companions: [Companion] = [Companion(age: 25, gender: "Kadın")]

    init(mode: PlanMode, defaultCity: String? = nil) {
        self.mode = mode
        self.defaultCity = defaultCity
        let prefilledCity = defaultCity ?? ""
        _city = State(initialValue: prefilledCity)
        // If a city is pre-filled in manual mode, skip straight to step 2 (dates)
        let startStep = (mode == .manual && !prefilledCity.isEmpty) ? 2 : 1
        _currentStep = State(initialValue: startStep)
    }

    // Validation
    var isNextButtonDisabled: Bool {
        if mode == .manual && currentStep == 1 {
            return city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            
            // HEADER & PROGRESS BAR
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: mode == .ai ? "sparkles.tv" : "map.fill")
                        .font(.title2)
                        .foregroundColor(Color(hex: "#008285"))
                    
                    Text(mode == .ai ? "Yapay Zeka Planı" : "Manuel Plan")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("Adım \(currentStep)/\(totalSteps)")
                        .font(.subheadline.bold())
                        .foregroundColor(Color(hex: "#008285"))
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                            .cornerRadius(3)
                        
                        Rectangle()
                            .fill(Color(hex: "#008285"))
                            .frame(width: geometry.size.width * CGFloat(currentStep) / CGFloat(totalSteps), height: 6)
                            .cornerRadius(3)
                            .animation(.spring(), value: currentStep)
                    }
                }
                .frame(height: 6)
                .padding(.horizontal)
            }
            .padding(.bottom, 20)
            
            // CONTENT
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Sayfa yapılarını bir diziye koyup ekrana basıyoruz
                    if mode == .manual {
                        destinationStepView().frame(width: geometry.size.width)
                        datesStepView().frame(width: geometry.size.width)
                        logisticsStepView().frame(width: geometry.size.width)
                        budgetCompanionsStepView().frame(width: geometry.size.width)
                    } else {
                        datesStepView().frame(width: geometry.size.width)
                        logisticsStepView().frame(width: geometry.size.width)
                        budgetCompanionsStepView().frame(width: geometry.size.width)
                    }
                }
                .frame(width: geometry.size.width, alignment: .leading)
                .offset(x: -CGFloat(currentStep - 1) * geometry.size.width)
                .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
            
            Spacer()
            
            // BOTTOM NAVIGATION
            HStack {
                if currentStep > 1 {
                    Button(action: {
                        withAnimation { currentStep -= 1 }
                    }) {
                        Text("Geri")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#008285"))
                            .padding(.vertical, 14)
                            .padding(.horizontal, 24)
                            .background(Color(hex: "#008285").opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                
                Spacer()
                
                if currentStep < totalSteps {
                    Button(action: {
                        withAnimation { currentStep += 1 }
                    }) {
                        Text("İleri")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 32)
                            .background(isNextButtonDisabled ? Color.gray : Color(hex: "#008285"))
                            .cornerRadius(12)
                    }
                    .disabled(isNextButtonDisabled)
                } else {
                    Button(action: generateTrip) {
                        Text("Rota Oluştur")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 32)
                            .background(viewModel.isLoading ? Color.gray : Color(hex: "#FF5A5F"))
                            .cornerRadius(12)
                            .shadow(color: Color(hex: "#FF5A5F").opacity(0.4), radius: 8, y: 4)
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .shadow(color: .black.opacity(0.05), radius: 5, y: -2)
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
        .fullScreenCover(isPresented: $viewModel.isLoading) {
            TripLoadingView(viewModel: viewModel)
        }
    }
    
    // MARK: - STEPS VIEWS
    
    @ViewBuilder
    private func destinationStepView() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Nereye gitmek istersin?")
                    .font(.title2.bold())
                    .padding(.top, 10)
                
                Text("Ziyaret etmek istediğin şehri veya ülkeyi yaz. Sana özel harika bir plan çıkaralım.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Şehir veya Ülke girin...", text: $city)
                        .font(.body)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(15)
                .shadow(color: .black.opacity(0.05), radius: 5, y: 3)
                
                Spacer()
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func datesStepView() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Ne zaman gidiyorsun?")
                    .font(.title2.bold())
                    .padding(.top, 10)
                
                Text("Seyahatinin başlangıç ve bitiş tarihlerini seç.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 0) {
                    DatePicker("Gidiş Tarihi", selection: $startDate, displayedComponents: .date)
                        .padding()
                        .background(Color(.systemBackground))
                    
                    Divider()
                        .padding(.leading, 16)
                    
                    DatePicker("Dönüş Tarihi", selection: $endDate, in: startDate..., displayedComponents: .date)
                        .padding()
                        .background(Color(.systemBackground))
                }
                .cornerRadius(15)
                .shadow(color: .black.opacity(0.05), radius: 5, y: 3)
                
                Spacer()
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func logisticsStepView() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Seyahat Detayları")
                    .font(.title2.bold())
                    .padding(.top, 10)
                
                Text("Bu seyahatte konaklama, ulaşım ve tempo tercihlerini belirle.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 20) {
                    // Konaklama
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Konaklama Tercihi")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                        
                        Picker("Konaklama", selection: $accommodation) {
                            ForEach(accommodations, id: \.self) { Text($0) }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                    
                    // Ulaşım
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Şehir İçi Ulaşım")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                        
                        Picker("Ulaşım", selection: $transportation) {
                            ForEach(transportations, id: \.self) { Text($0) }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                    
                    // Ülke/Şehir Sayısı
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gezilecek Şehir/Ülke Sayısı")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                        
                        Stepper(value: $countryCount, in: 1...20) {
                            Text("\(countryCount) Hedef")
                                .font(.body)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func budgetCompanionsStepView() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Bütçe ve Yol Arkadaşları")
                    .font(.title2.bold())
                    .padding(.top, 10)
                
                Text("Kimlerle gittiğini ve ortalama bütçeni belirle.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 20) {
                    // Bütçe
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Toplam Bütçe (₺)")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("₺")
                                .foregroundColor(.gray)
                            TextField("Örn: 25000", text: $budgetString)
                                .keyboardType(.numberPad)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                    
                    // Kiminle
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Kiminle Gidiyorsun?")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                        
                        Picker("Kiminle", selection: $travelType) {
                            ForEach(travelTypes, id: \.self) { Text($0) }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                    
                    if travelType != "Yalnız" {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Beraber Gideceğiniz Kişi Sayısı")
                                .font(.subheadline.bold())
                                .foregroundColor(.secondary)
                            
                            Stepper(value: $companionCount, in: 1...20) {
                                Text("\(companionCount) Kişi")
                                    .font(.body)
                            }
                            .onChange(of: companionCount) { newValue in
                                if newValue > companions.count {
                                    for _ in 0..<(newValue - companions.count) {
                                        companions.append(Companion(age: 25, gender: "Kadın"))
                                    }
                                } else if newValue < companions.count {
                                    companions.removeLast(companions.count - newValue)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Kişilerin Bilgileri")
                                .font(.subheadline.bold())
                                .foregroundColor(.secondary)
                            
                            ForEach(0..<companions.count, id: \.self) { index in
                                HStack {
                                    Text("\(index + 1). Kişi")
                                        .font(.subheadline)
                                        .frame(width: 60, alignment: .leading)
                                    
                                    TextField("Yaş", value: $companions[index].age, formatter: NumberFormatter())
                                        .keyboardType(.numberPad)
                                        .frame(width: 50)
                                        .padding(8)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                    
                                    Spacer()
                                    
                                    Picker("Cinsiyet", selection: $companions[index].gender) {
                                        Text("Kadın").tag("Kadın")
                                        Text("Erkek").tag("Erkek")
                                    }
                                    .pickerStyle(.menu)
                                    .padding(4)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .padding()
        .onAppear {
            // Consume the pre-filled city so it doesn't trigger again
            if router.plannerDestinationCity != nil {
                router.plannerDestinationCity = nil
            }
        }
    }
    
    // MARK: - ACTIONS
    
    private func generateTrip() {
        let weights = authVM.currentUser?.profileWeights ?? ["Kültür Kaşifi": 1.0]
        let destinationToUse = mode == .manual && !city.isEmpty ? city : nil
        
        let computedDays = max(1, Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1)
        let finalBudget = budgetString.isEmpty ? "Belirtilmemiş" : "\(budgetString) ₺"
        
        guard let currentUser = authVM.currentUser else { return }
        
        viewModel.generateTrip(
            destination: destinationToUse,
            budget: finalBudget,
            days: computedDays,
            travelType: travelType,
            profileWeights: weights,
            accommodation: accommodation,
            transportation: transportation,
            countryCount: countryCount,
            companionCount: travelType == "Yalnız" ? 0 : companionCount,
            companions: travelType == "Yalnız" ? [] : companions,
            startDate: startDate,
            endDate: endDate,
            user: currentUser
        )
    }
}
