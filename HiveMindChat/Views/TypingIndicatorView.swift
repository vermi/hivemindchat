import SwiftUI

struct TypingIndicatorView: View {
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundColor(Color.gray)
                    .scaleEffect(index == 0 ? scale : 1)
                    .animation(Animation.easeInOut(duration: 0.5).repeatForever().delay(Double(index) * 0.2), value: scale)
            }
        }.onAppear {
            scale = 0.4
        }
    }
}
