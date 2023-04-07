import SwiftUI

struct CustomTextField: View {
    @Binding var text: String
    var placeholder: String
    var onSubmit: () -> Void
    var axis: Axis = .horizontal
    var lineLimitRange: ClosedRange<Int> = 1...1
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.gray)
                        .offset(y: (geometry.size.height - geometry.size.height / 2) / 2)
                }
                
                TextField("", text: $text, axis: axis)
                    .lineLimit(lineLimitRange)
                    .padding(.top, (geometry.size.height - geometry.size.height / 2) / 2)
                    .padding(.bottom, (geometry.size.height - geometry.size.height / 2) / 2)
                    .onSubmit(onSubmit)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding()
    }
}
