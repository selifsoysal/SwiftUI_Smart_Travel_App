import SwiftUI

struct MatchAnalysisView: View {
    let details: MatchingScoreDetails
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Skor Rozeti
                    ZStack {
                        Circle()
                            .stroke(Color(hex: "#FF5A5F").opacity(0.1), lineWidth: 10)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(details.score) / 100)
                            .stroke(
                                LinearGradient(colors: [Color(hex: "#FF5A5F"), Color(hex: "#FE8C00")], startPoint: .topLeading, endPoint: .bottomTrailing),
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 0) {
                            Text("%\(details.score)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                            Text("Uyum")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("AI ANALİZİ")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                            .tracking(1)
                        
                        ForEach(details.explanations, id: \.self) { explanation in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(Color(hex: "#FF5A5F"))
                                    .font(.system(size: 14))
                                    .padding(.top, 2)
                                
                                Text(explanation)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Uyum Analizi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}
