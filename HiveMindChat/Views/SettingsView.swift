import SwiftUI
import KeychainSwift
import StoreKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var openAIAPIToken: String = ""
    @State private var keychain = KeychainSwift()
    @State private var userName: String = UserDefaults.standard.string(forKey: "userName") ?? "User"
    @State private var hasDonated: Bool = UserDefaults.standard.bool(forKey: "hasDonated")
    @StateObject private var storeObserver = StoreObserver()
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 3)
                .frame(width: 40, height: 5)
                .foregroundColor(Color(.systemGray))
                .padding(.top)
            
            NavigationView {
                VStack {
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
                    }
                    .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.bottom))
                    
                    Button(action: {
                        if storeObserver.purchaseState != .processing {
                            purchaseDonation()
                        }
                    }) {
                        Group {
                            if storeObserver.purchaseState == .processing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                VStack {
                                    if hasDonated {
                                        Image(systemName: "heart.fill")
                                            .resizable()
                                            .frame(width: 24, height: 24)
                                    } else {
                                        Text("Send a Tip")
                                            .font(.system(size: 18, weight: .bold, design: .default))
                                        Text(storeObserver.localizedDonationPrice)
                                            .font(.system(size: 14, weight: .regular, design: .default))
                                    }
                                }
                            }
                        }
                    }
                    .buttonStyle(PurchaseButtonStyle())
                    .padding(.bottom)
                }
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
            storeObserver.fetchDonationProduct()
        }
        .onDisappear {
            SKPaymentQueue.default().remove(storeObserver)
        }
    }
    
    private func saveAPIToken() {
        keychain.set(openAIAPIToken, forKey: "openAIAPIToken")
    }
    
    private func purchaseDonation() {
        let productID = "com.afakecompany.hivemind.donation"
        
        let productRequest = SKProductsRequest(productIdentifiers: [productID])
        productRequest.delegate = storeObserver
        productRequest.start()
        
        // Set the completion handler
        storeObserver.purchaseCompletion = {
            UserDefaults.standard.set(true, forKey: "hasDonated")
            hasDonated = true
        }
        
        storeObserver.purchaseDonationProduct()
    }
    
    struct PurchaseButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding()
                .foregroundColor(.white)
                .background(Color.green)
                .cornerRadius(8)
        }
    }
}
