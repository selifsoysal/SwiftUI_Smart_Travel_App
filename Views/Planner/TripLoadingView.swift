import SwiftUI

struct TripLoadingView: View {
    @ObservedObject var viewModel: TripViewModel
    @State private var planeY: CGFloat = 0
    @State private var planeRotation: Double = -5
    @State private var cloudOffset: CGFloat = 0
    @State private var opacity: Double = 0
    
    // Screen width for progress calculation
    private let screenWidth = UIScreen.main.bounds.width
    
    private var planeX: CGFloat {
        let startX: CGFloat = 40
        let endX: CGFloat = screenWidth - 40
        return startX + (endX - startX) * CGFloat(viewModel.loadingProgress)
    }
    
    var body: some View {
        ZStack {
            // Background Gradient (Sky)
            LinearGradient(colors: [Color(hex: "#008285"), Color(hex: "#00A2A5"), Color(hex: "#00C2C5")], startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            // Floating Clouds (Background)
            ForEach(0..<6) { i in
                Image(systemName: "cloud.fill")
                    .font(.system(size: CGFloat.random(in: 60...120)))
                    .foregroundColor(Color.white.opacity(0.2))
                    .offset(x: cloudOffset + CGFloat(i * 200) - 400, y: CGFloat(i * 120) - 300)
            }
            
            VStack(spacing: 50) {
                Spacer()
                
                // Animated Plane tied to progress
                ZStack(alignment: .leading) {
                    // Path Line
                    DashedLine()
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                        .foregroundColor(Color.white.opacity(0.2))
                        .frame(height: 1)
                        .padding(.horizontal, 40)
                    
                    VStack(spacing: 0) {
                        Image(systemName: "airplane")
                            .font(.system(size: 60))
                            .foregroundColor(Color.white)
                            .rotationEffect(.degrees(planeRotation))
                            .shadow(color: Color.black.opacity(0.15), radius: 15, y: 15)
                    }
                    .offset(x: planeX - 30, y: planeY) // -30 to center the plane icon
                    .animation(.spring(response: 1.0, dampingFraction: 0.8), value: viewModel.loadingProgress)
                }
                .frame(height: 150)
                
                VStack(spacing: 25) {
                    Text(viewModel.loadingMessage)
                        .font(.title3.bold())
                        .foregroundColor(Color.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .transition(.opacity)
                        .id(viewModel.loadingMessage)
                    
                    // Modern Progress Bar
                    VStack(spacing: 12) {
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 10)
                            
                            Capsule()
                                .fill(Color.white)
                                .frame(width: (screenWidth - 100) * CGFloat(viewModel.loadingProgress), height: 10)
                                .shadow(color: Color.white.opacity(0.6), radius: 8)
                        }
                        .frame(width: screenWidth - 100)
                        
                        Text("Maceraya %\(Int(viewModel.loadingProgress * 100)) Kaldı")
                            .font(.caption.bold())
                            .foregroundColor(Color.white.opacity(0.9))
                            .monospacedDigit()
                    }
                }
                .opacity(opacity)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text("AI TARAFINDAN TASARLANIYOR")
                }
                .font(.caption2.bold())
                .foregroundColor(Color.white.opacity(0.6))
                .tracking(2)
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 1.0)) {
                opacity = 1.0
            }
            startFloatingAnimation()
            startCloudAnimation()
        }
    }
    
    private func startFloatingAnimation() {
        // Subtle up-down floating to make it look alive
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            planeY = -15
            planeRotation = -2
        }
    }
    
    private func startCloudAnimation() {
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            cloudOffset = 800
        }
    }
}

// Fixed missing Shape struct
struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}
