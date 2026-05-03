import SwiftUI

struct ChatDetailView: View {
    let targetTraveler: Traveler
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var socialManager = SocialManager.shared
    
    @State private var messageText: String = ""
    @State private var activeConnection: ConnectionRequest?
    @State private var messages: [ChatMessage] = []
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(messages) { msg in
                            let isMe = msg.senderId == authVM.currentUser?.id
                            HStack {
                                if isMe { Spacer() }
                                
                                Text(msg.text)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(isMe ? Color(hex: "#008285") : Color(.secondarySystemBackground))
                                    .foregroundColor(isMe ? .white : .primary)
                                    .cornerRadius(16)
                                
                                if !isMe { Spacer() }
                            }
                            .id(msg.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _ in
                    if let last = messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            HStack(spacing: 12) {
                TextField("Mesaj yaz...", text: $messageText)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.title2)
                        .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : Color(hex: "#FF5A5F"))
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationTitle(targetTraveler.username)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.bottom))
        .onAppear {
            if let myId = authVM.currentUser?.id {
                socialManager.loadSocialData(for: myId)
                if let conn = socialManager.getActiveConnection(between: myId, and: targetTraveler.id) {
                    self.activeConnection = conn
                    self.messages = socialManager.getMessages(for: conn.id)
                }
            }
        }
        .onChange(of: socialManager.allMessages.count) { _ in
            if let conn = activeConnection {
                self.messages = socialManager.getMessages(for: conn.id)
            }
        }
    }
    
    private func sendMessage() {
        guard let myId = authVM.currentUser?.id, 
              let conn = activeConnection else { return }
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty {
            socialManager.sendMessage(connectionId: conn.id, senderId: myId, receiverId: targetTraveler.id, text: text)
            messageText = ""
        }
    }
}
