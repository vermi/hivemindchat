import Foundation
import SwiftUI
import UniformTypeIdentifiers

class ConversationListViewModel: NSObject, ObservableObject, UIDocumentPickerDelegate {
    @Published var conversations: [Conversation]
    
    init(conversations: [Conversation]) {
        self.conversations = conversations
    }
    
    func importConversationFromJSON() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        documentPicker.shouldShowFileExtensions = true

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
                DataManager.shared.saveConversationHistory(self.conversations)
            }
        } catch {
            print("Error importing conversation from JSON: \(error)")
        }
    }
    
    func shareConversationAsJSON(selectedConversationIndex: Int) {
        let conversation = conversations[selectedConversationIndex]
        
        do {
            let jsonData = try JSONEncoder().encode(conversation)
            let jsonString = String(data: jsonData, encoding: .utf8)
            guard let jsonFileURL = saveJSONStringToTemporaryFile(jsonString: jsonString, title: conversation.title) else { return }
            
            let itemProvider = NSItemProvider(contentsOf: jsonFileURL)
            let activityViewController = UIActivityViewController(activityItems: [itemProvider as Any], applicationActivities: nil)
            
            // Set the ConversationListViewModel as the delegate for the document picker
            let documentPicker = UIDocumentPickerViewController(forExporting: [jsonFileURL])
            documentPicker.delegate = self
            documentPicker.shouldShowFileExtensions = true
            documentPicker.navigationItem.title = "\(conversation.title).json"
            documentPicker.directoryURL = FileManager.default.temporaryDirectory
            
            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
               let viewController = scene.windows.first?.rootViewController {
                viewController.present(documentPicker, animated: true, completion: nil)
            }
        } catch {
            print("Error encoding conversation to JSON: \(error)")
        }
    }
    
    func saveJSONStringToTemporaryFile(jsonString: String?, title: String) -> URL? {
        guard let jsonString = jsonString else { return nil }
        
        let fileName = "\(title).json"
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)

        do {
            try jsonString.write(to: fileURL, atomically: true, encoding: .utf8)
            
            let documentPicker = UIDocumentPickerViewController(forExporting: [fileURL])
            documentPicker.delegate = self
            documentPicker.shouldShowFileExtensions = true
            documentPicker.directoryURL = tempDirectory
            
            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
               let viewController = scene.windows.first?.rootViewController {
                viewController.present(documentPicker, animated: true, completion: nil)
            }
            
            return fileURL
        } catch {
            print("Error saving JSON string to file: \(error)")
            return nil
        }
    }
}
