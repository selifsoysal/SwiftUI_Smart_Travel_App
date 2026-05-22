import Foundation

@MainActor
final class SwipeViewModel: ObservableObject {
    @Published var items: [SwipeItem] = []
    @Published var currentItem: SwipeItem?
    @Published var isLoading = false
    @Published var currentIndex: Int = 0

    var onFinish: (([String: Double]) -> Void)?
    
    // Curated high-quality image dataset mapping to TravelProfiles
    let curatedData: [TravelProfile: [(String, String)]] = [
        .culture: [
            ("Louvre Müzesi, Paris", "https://images.unsplash.com/photo-1549144511-f099e773c147?auto=format&fit=crop&q=80&w=1000"),
            ("Kyoto Tapınakları, Japonya", "https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?auto=format&fit=crop&q=80&w=1000"),
            ("Ayasofya Camii, İstanbul", "https://images.unsplash.com/photo-1541432901042-2d8bd64b4a9b?auto=format&fit=crop&q=80&w=1000")
        ],
        .nature: [
            ("İsviçre Alpleri", "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&q=80&w=1000"),
            ("Banff Milli Parkı, Kanada", "https://images.unsplash.com/photo-1503614472-8c93d56e92ce?auto=format&fit=crop&q=80&w=1000"),
            ("İzlanda Şelaleleri", "https://images.unsplash.com/photo-1476610182048-b716b8518aae?auto=format&fit=crop&q=80&w=1000")
        ],
        .food: [
            ("Napoli Pizzacıları, İtalya", "https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&q=80&w=1000"),
            ("Tokyo Sokak Lezzetleri", "https://images.unsplash.com/photo-1553621042-f6e147245754?auto=format&fit=crop&q=80&w=1000"),
            ("Paris Kafeleri", "https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&q=80&w=1000")
        ],
        .luxury: [
            ("Dubai Gökdelenleri", "https://images.unsplash.com/photo-1512453979798-5ea266f8880c?auto=format&fit=crop&q=80&w=1000"),
            ("Santorini Villaları, Yunanistan", "https://images.unsplash.com/photo-1613395877344-13d4a8e0d49e?auto=format&fit=crop&q=80&w=1000"),
            ("Maldivler Resorları", "https://images.unsplash.com/photo-1512100356356-de1b84283e18?auto=format&fit=crop&q=80&w=1000")
        ],
        .history: [
            ("Machu Picchu, Peru", "https://images.unsplash.com/photo-1587595431973-160d0d94add1?auto=format&fit=crop&q=80&w=1000"),
            ("Petra Antik Kenti, Ürdün", "https://images.unsplash.com/photo-1501232060322-aa87215ab531?auto=format&fit=crop&q=80&w=1000"),
            ("Giza Piramitleri, Mısır", "https://images.unsplash.com/photo-1503177119275-0aa32b3a9368?auto=format&fit=crop&q=80&w=1000")
        ]
    ]

    func loadData() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            var allMappedItems: [SwipeItem] = []
            
            for (profile, places) in self.curatedData {
                let profileItems = places.map { (title, url) in
                    SwipeItem(title: title, imageUrl: url, tags: [profile.toInterest()]) 
                }
                allMappedItems.append(contentsOf: profileItems)
            }
            
            self.items = allMappedItems.shuffled()
            self.currentItem = self.items.first
            self.isLoading = false
        }
    }

    private var profileScores: [Interest: Int] = [:]
    
    func like() {
        if let current = currentItem, let tag = current.tags.first {
            profileScores[tag, default: 0] += 1
        }
        next()
    }
    
    func dislike() {
        next()
    }

    private func next() {
        guard let current = currentItem,
              let index = items.firstIndex(where: { $0.id == current.id }) else { return }
        
        if index + 1 < items.count {
            currentIndex += 1
            currentItem = items[index + 1]
        } else {
            currentIndex += 1
            // YÜZDESEL HESAPLAMA
            let totalLikes = profileScores.values.reduce(0, +)
            var weights: [String: Double] = [:]
            
            if totalLikes > 0 {
                for (interest, score) in profileScores {
                    let profileName = getProfile(from: interest).rawValue
                    weights[profileName] = Double(score) / Double(totalLikes)
                }
            } else {
                // Hiçbirini beğenmediyse varsayılan olarak Kültür %100
                weights[TravelProfile.culture.rawValue] = 1.0
            }
            
            onFinish?(weights)
        }
    }
    
    private func getProfile(from interest: Interest) -> TravelProfile {
        switch interest {
        case .culture: return .culture
        case .nature: return .nature
        case .food: return .food
        case .luxury: return .luxury
        case .history: return .history
        case .nightlife: return .culture
        }
    }
}
