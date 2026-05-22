import SwiftUI

struct TravelerDetailView: View {
    let traveler: Traveler
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Section
                    VStack(spacing: 12) {
                        Circle()
                            .fill(Color(hex: "#008285"))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text("\(traveler.username.prefix(1))")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
                        Text(traveler.username)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("\(traveler.age) Yaş")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Stats/Info Cards
                    HStack(spacing: 10) {
                        let dominantProfile = traveler.profileWeights?.max(by: { $0.value < $1.value })?.key ?? "Gezgin"
                        DetailInfoCard(title: "Profil", value: dominantProfile, icon: "person.text.rectangle")
                        DetailInfoCard(title: "Cinsiyet", value: traveler.gender ?? "Belirtilmemiş", icon: "person.fill.viewfinder")
                    DetailInfoCard(title: "Bütçe", value: traveler.budget.displayName, icon: "banknote")
                }
                .padding(.horizontal)
                
                // Bio Section
                if let bio = traveler.bio, !bio.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hakkında")
                            .font(.headline)
                        
                        Text(bio)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 30)
        }
            .navigationTitle("Gezgin Detayı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}

struct DetailInfoCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color(hex: "#008285"))
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct TripDetailCard: View {
    let trip: PlannedTrip
    
    var body: some View {
        HStack {
            Image(systemName: "airplane")
                .foregroundColor(Color(hex: "#FF5A5F"))
                .font(.title3)
                .frame(width: 40, height: 40)
                .background(Color(hex: "#FF5A5F").opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(trip.location)
                    .font(.headline)
                
                Text("\(formatDate(trip.startDate)) - \(formatDate(trip.endDate))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
}
