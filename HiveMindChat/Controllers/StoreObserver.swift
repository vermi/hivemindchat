import Foundation
import StoreKit

class StoreObserver: NSObject, ObservableObject, SKPaymentTransactionObserver, SKProductsRequestDelegate {
    @Published var purchaseState: PurchaseState = .idle
    @Published var localizedDonationPrice: String = ""
    @Published var donationProduct: SKProduct?
    var purchaseCompletion: (() -> Void)?
    
    func fetchDonationProduct() {
        // Replace "com.yourapp.donation" with the product identifier for your donation in-app purchase.
        let productID = "com.afakecompany.hivemind.donation"
        
        // Fetch the product
        let productRequest = SKProductsRequest(productIdentifiers: [productID])
        productRequest.delegate = self
        productRequest.start()
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        guard let product = response.products.first else {
            print("Product not found")
            return
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        let formattedPrice = formatter.string(from: product.price) ?? ""
        
        DispatchQueue.main.async {
            self.localizedDonationPrice = formattedPrice
            self.donationProduct = product // Set the donationProduct property
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                purchaseState = .processing
            case .purchased:
                print("Transaction successful: \(transaction)")
                queue.finishTransaction(transaction)
                purchaseState = .completed
                DispatchQueue.main.async {
                    self.purchaseCompletion?()
                }
            case .failed, .restored:
                print("Transaction failed or restored: \(transaction)")
                queue.finishTransaction(transaction)
                purchaseState = .idle
            default:
                break
            }
        }
    }
        
    func purchaseDonationProduct() {
        guard let product = donationProduct else {
            print("Donation product not found")
            return
        }
        
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    enum PurchaseState {
        case idle
        case processing
        case completed
    }
}
