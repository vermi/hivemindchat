import SwiftUI
import KeychainSwift

import SwiftUI
import KeychainSwift

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var openAIAPIToken: String = ""
    @State private var keychain = KeychainSwift()

    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 3)
                .frame(width: 40, height: 5)
                .foregroundColor(Color(.systemGray))
                .padding(.top)
            
            NavigationView {
                Form {
                    Section(header: Text("OpenAI API Token")) {
                        TextField("Enter your OpenAI API token", text: $openAIAPIToken)
                            .onAppear {
                                openAIAPIToken = keychain.get("openAIAPIToken") ?? ""
                            }
                    }
                }
                .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.bottom))
                .navigationTitle("Settings")
                .navigationBarItems(trailing: Button("Save") {
                    saveAPIToken()
                    dismiss()
                })
            }
        }
    }
    
    private func saveAPIToken() {
        keychain.set(openAIAPIToken, forKey: "openAIAPIToken")
    }
}
