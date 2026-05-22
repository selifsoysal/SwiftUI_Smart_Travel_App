import Foundation

// MARK: - Enums

// Kartların etiketleri
enum Interest: String, CaseIterable, Codable {
    case food, culture, nature, nightlife, luxury, history
}

// Gezginin profili
enum TravelProfile: String, Codable, CaseIterable {
    case nature = "Doğa Sever"
    case culture = "Kültür Kaşifi"
    case food = "Gurme Gezgin"
    case luxury = "Lüks Tutkunu"
    case history = "Tarih Meraklısı"
}

extension TravelProfile {
    func toInterest() -> Interest {
        switch self {
        case .culture: return .culture
        case .nature: return .nature
        case .food: return .food
        case .luxury: return .luxury
        case .history: return .history
        }
    }
}

// Kiminle seyahat ediliyor?
enum TravelType: String, CaseIterable, Identifiable, Codable {
    case solo = "Yalnız"
    case partner = "Partner/Eş"
    case family = "Aile"
    case friends = "Arkadaş Grubu"
    
    var id: String { self.rawValue }
}

// Bütçe aralığı
enum BudgetRange: String, CaseIterable, Identifiable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .low: return "Düşük"
        case .medium: return "Orta"
        case .high: return "Yüksek"
        }
    }
    
    static func displayName(for raw: String?) -> String {
        guard let raw = raw else { return "Belirtilmemiş" }
        return BudgetRange(rawValue: raw)?.displayName ?? raw
    }
}

enum PlanMode: String, Codable, Identifiable {
    case ai
    case manual
    
    var id: String { self.rawValue }
}

enum SharingMode: String, Codable {
    case none
    case fullTrip
    case specificEvents
}

