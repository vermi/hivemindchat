import Foundation
import StoreKit

class StoreObserver: NSObject, ObservableObject, SKPaymentTransactionObserver, SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        guard let product = response.products.first else {
            print("Product not found")
            return
        }
        
        // Purchase the product
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                // Handle successful purchase or restore
                print("Transaction successful: \(transaction.payment.productIdentifier)")
                queue.finishTransaction(transaction)
                
            case .failed:
                // Handle failed transaction
                print("Transaction failed: \(transaction.payment.productIdentifier), error: \(String(describing: transaction.error))")
                queue.finishTransaction(transaction)
                
            default:
                break
            }
        }
    }
}
