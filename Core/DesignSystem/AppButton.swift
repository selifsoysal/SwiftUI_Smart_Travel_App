import SwiftUI

struct AppButton: View {

    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.appBody)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppStyle.primary)
                .cornerRadius(14)
        }
    }
}
