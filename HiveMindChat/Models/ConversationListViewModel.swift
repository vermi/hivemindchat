import Foundation
import SwiftUI
import UniformTypeIdentifiers

class ConversationListViewModel: NSObject, ObservableObject, UIDocumentPickerDelegate {
    @Published var conversations: [Conversation]
    
    init(conversations: [Conversation]) {
        self.conversations = conversations
    }
    
    func importConversationFromJSON() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.hivemind])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let viewController = scene.windows.first?.rootViewController {
            viewController.present(documentPicker, animated: true, completion: nil)
        }
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        do {
            let jsonData = try Data(contentsOf: url)
            let importedConversation = try JSONDecoder().decode(Conversation.self, from: jsonData)
            
            DispatchQueue.main.async {
                withAnimation {
                    self.conversations.append(importedConversation)
                }
            }
        } catch {
            print("Error importing conversation from JSON: \(error)")
        }
    }
}
