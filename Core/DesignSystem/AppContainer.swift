import SwiftUI

struct AppContainer<Content: View>: View {

    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack {
            Spacer()
            content
            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
    }
}
