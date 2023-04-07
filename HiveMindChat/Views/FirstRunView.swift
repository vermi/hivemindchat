import SwiftUI

struct FirstRunView: View {
    @AppStorage("isFirstRun") var isFirstRun: Bool = true
    @State private var showSafari: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Welcome to HiveMind Chat")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding()
            
            Text("You will be asked to enter your OpenAI API Token on the next screen.\n\nIf you don't have one, you can sign up below.")
                .multilineTextAlignment(.center)
                .padding()
            
            Button(action: {
                showSafari.toggle()
            }) {
                Text("Sign Up")
                    .bold()
                    .padding(.vertical, 10)
                    .padding(.horizontal, 40)
                    .background(Color(.systemBackground))
                    .foregroundColor(.primary)
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary, lineWidth: 1))
            }
            
            Spacer()
            
            Button(action: {
                isFirstRun = false
            }) {
                Text("Continue")
                    .bold()
                    .padding(.vertical, 10)
                    .padding(.horizontal, 40)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .fullScreenCover(isPresented: $showSafari, content: {
            SFSafariViewWrapper(url: URL(string: "https://platform.openai.com/signup/")!)
        })
    }
}
