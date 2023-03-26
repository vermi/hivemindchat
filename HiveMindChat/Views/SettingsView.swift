import SwiftUI
import KeychainSwift
import StoreKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var openAIAPIToken: String = ""
    @State private var keychain = KeychainSwift()
    @State private var userName: String = UserDefaults.standard.string(forKey: "userName") ?? "User"
    @StateObject private var storeObserver = StoreObserver()
    
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
                    Section(header: Text("Form of Address")) {
                        TextField("Name", text: $userName)
                            .disableAutocorrection(true)
                            .autocapitalization(.words)
                    }
                    Section(header: Text("Tip the Developer")) {
                        Button(action: {
                            purchaseDonation()
                        }){
                            Text("Send a Tip for US$0.99")
                        }
                    }
                }
                .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.bottom))
                .navigationTitle("Settings")
                .navigationBarItems(trailing: Button("Save") {
                    saveAPIToken()
                    UserDefaults.standard.setValue(userName, forKey: "userName")
                    dismiss()
                })
            }
        }
        .onAppear {
            SKPaymentQueue.default().add(storeObserver)
        }
        .onDisappear {
            SKPaymentQueue.default().remove(storeObserver)
        }
    }
    
    private func saveAPIToken() {
        keychain.set(openAIAPIToken, forKey: "openAIAPIToken")
    }
    
    private func purchaseDonation() {
        // Replace "com.yourapp.donation" with the product identifier for your donation in-app purchase.
        let productID = "com.afakecompany.hivemind.donation"
        
        // Fetch the product
        let productRequest = SKProductsRequest(productIdentifiers: [productID])
        productRequest.delegate = storeObserver
        productRequest.start()
    }
}

