import SwiftUI

struct AuthView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLogin = true
    
    // Register alanları
    @State private var name = ""
    @State private var birthDate = Date()
    
    var body: some View {
        AppContainer {
            VStack {
                Spacer()
                
                VStack(spacing: 32) {
                    
                    // MARK: - HEADER
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: "#121212"))
                                .frame(width: 70, height: 70)
                            
                            Path { path in
                                path.move(to: CGPoint(x: 20, y: 50))
                                path.addCurve(to: CGPoint(x: 50, y: 20), control1: CGPoint(x: 20, y: 30), control2: CGPoint(x: 40, y: 50))
                            }
                            .stroke(Color(hex: "#008285"), style: StrokeStyle(lineWidth: 3, dash: [4]))
                            
                            Circle()
                                .fill(Color(hex: "#FF5A5F"))
                                .frame(width: 12, height: 12)
                                .offset(x: -15, y: 15)
                            
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 24))
                                .foregroundColor(Color(hex: "#FF5A5F"))
                                .offset(x: 15, y: -15)
                                .shadow(radius: 4)
                        }
                        .frame(width: 70, height: 70)
                        .padding(.bottom, 4)
                        
                        Text("Routey")
                            .font(.system(size: 44, weight: .black, design: .rounded))
                            .foregroundColor(Color(hex: "#FF5A5F"))
                        
                        Text(isLogin
                             ? "Tekrar hoş geldiniz, giriş yapın"
                             : "Hemen hesap oluşturun ve keşfe başlayın")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // MARK: - INPUTS
                    VStack(spacing: 16) {
                        
                        // REGISTER FIELDS
                        if !isLogin {
                            
                            // Name
                            HStack(spacing: 12) {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                                
                                TextField("Adınız", text: $name)
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                            
                            // Birthdate
                            DatePicker("Doğum Tarihi",
                                       selection: $birthDate,
                                       displayedComponents: .date)
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(12)
                        }
                        
                        // Email
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.gray)
                            
                            TextField("E-posta Adresi", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                        
                        // Password
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                            
                            SecureField("Şifre", text: $password)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                        
                        // Error
                        if let error = authViewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .transition(.opacity)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // MARK: - BUTTONS
                    VStack(spacing: 20) {
                        
                        if authViewModel.isLoading {
                            ProgressView()
                                .padding()
                        } else {
                            AppButton(title: isLogin ? "Giriş Yap" : "Kayıt Ol") {
                                hideKeyboard()
                                
                                if isLogin {
                                    authViewModel.login(email: email, password: password)
                                } else {
                                    authViewModel.register(
                                        email: email,
                                        password: password,
                                        name: name,
                                        birthDate: birthDate
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Toggle
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                authViewModel.errorMessage = nil
                                isLogin.toggle()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(isLogin ? "Hesabınız yok mu?" : "Zaten hesabınız var mı?")
                                    .foregroundColor(.secondary)
                                
                                Text(isLogin ? "Kayıt Ol" : "Giriş Yap")
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            .font(.footnote)
                        }
                        .disabled(authViewModel.isLoading)
                    }
                }
                
                Spacer()
            }
        }
    }
}


// MARK: - KEYBOARD EXTENSION (HATA FIX)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil,
                                        from: nil,
                                        for: nil)
    }
}
