import SwiftUI

struct FirstRunView: View {
    @AppStorage("isFirstRun") var isFirstRun: Bool = true
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Welcome to HiveMind Chat")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding()

            
            Text("To use this app, you'll need an OpenAI API Token. You can get one from:")
                .multilineTextAlignment(.center)
                .padding()
            
            Text("https://platform.openai.com/signup/")
                .foregroundColor(.blue)
                .underline()
                .onTapGesture {
                    if let url = URL(string: "https://platform.openai.com/signup/") {
                        UIApplication.shared.open(url)
                    }
                }
            
            Spacer()
            
            Button(action: {
                isFirstRun = false
            }) {
                Text("Let's Go!")
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
    }
}
