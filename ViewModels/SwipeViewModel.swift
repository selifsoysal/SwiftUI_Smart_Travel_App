import Foundation

@MainActor
final class SwipeViewModel: ObservableObject {
    @Published var items: [SwipeItem] = []
    @Published var currentItem: SwipeItem?
    @Published var isLoading = false

    var onFinish: ((TravelProfile) -> Void)?
    
    // Curated high-quality image dataset mapping to TravelProfiles
    let curatedData: [TravelProfile: [(String, String)]] = [
        .culture: [
            ("Louvre Müzesi, Paris", "https://images.unsplash.com/photo-1499856871958-5b9627545d1a?auto=format&fit=crop&q=80&w=1000"),
            ("Kyoto Tapınakları", "https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?auto=format&fit=crop&q=80&w=1000"),
            ("Kolezyum, Roma", "https://images.unsplash.com/photo-1552832230-c0197ef6f1dc?auto=format&fit=crop&q=80&w=1000")
        ],
        .nature: [
            ("İsviçre Alpleri", "https://images.unsplash.com/photo-1530122037265-a5f1f91d3b99?auto=format&fit=crop&q=80&w=1000"),
            ("Banff Milli Parkı", "https://images.unsplash.com/photo-1503614472-8c93d56e92ce?auto=format&fit=crop&q=80&w=1000"),
            ("İzlanda Şelaleleri", "https://images.unsplash.com/photo-1476610182048-b716b8518aae?auto=format&fit=crop&q=80&w=1000")
        ],
        .food: [
            ("Napoli Pizzacıları", "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&q=80&w=1000"),
            ("Tokyo Sokak Lezzetleri", "https://images.unsplash.com/photo-1553621042-f6e147245754?auto=format&fit=crop&q=80&w=1000"),
            ("Paris Kafeleri", "https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&q=80&w=1000")
        ],
        .luxury: [
            ("Dubai Gökdelenleri", "https://images.unsplash.com/photo-1512453979798-5ea266f8880c?auto=format&fit=crop&q=80&w=1000"),
            ("Santorini Villaları", "https://images.unsplash.com/photo-1570077188670-e3a8d69ac5f1?auto=format&fit=crop&q=80&w=1000"),
            ("Maldivler", "https://images.unsplash.com/photo-1512100356356-de1b84283e18?auto=format&fit=crop&q=80&w=1000")
        ],
        .history: [
            ("Machu Picchu", "https://images.unsplash.com/photo-1587595431973-160d0d94add1?auto=format&fit=crop&q=80&w=1000"),
            ("Petra, Ürdün", "https://images.unsplash.com/photo-1501232060322-aa87215ab531?auto=format&fit=crop&q=80&w=1000"),
            ("Mısır Piramitleri", "https://images.unsplash.com/photo-1503177119275-0aa32b3a9368?auto=format&fit=crop&q=80&w=1000")
        ]
    ]

    func loadData() {
        isLoading = true
        
        // Simulating a quick network fetch to show the loading screen transition beautifully
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            var allMappedItems: [SwipeItem] = []
            
            for (profile, places) in self.curatedData {
                let profileItems = places.map { (title, url) in
                    // In a real app we'd attach the profile to the item to score likes, 
                    // but since items are randomized, we just pass the info.
                    SwipeItem(title: title, imageUrl: url, tags: [profile.toInterest()]) 
                }
                allMappedItems.append(contentsOf: profileItems)
            }
            
            self.items = allMappedItems.shuffled() // Yüksek kaliteli 15 görsel listelendi
            self.currentItem = self.items.first
            self.isLoading = false
        }
    }

    // Basit bir skorlama (like edilirse etiketin skorunu arttır mantığı kurulabilir)
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
            currentItem = items[index + 1]
        } else {
            let winningTag = profileScores.max(by: { $0.value < $1.value })?.key ?? Interest.culture
            // Interest enumunu TravelProfile enumuna çeviriyoruz
            let winningProfile = getProfile(from: winningTag)
            onFinish?(winningProfile)
        }
    }
    
    private func getProfile(from interest: Interest) -> TravelProfile {
        switch interest {
        case .culture: return .culture
        case .nature: return .nature
        case .food: return .food
        case .luxury: return .luxury
        case .history: return .history
        case .nightlife: return .culture // fallback
        }
    }
}
