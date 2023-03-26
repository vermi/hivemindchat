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
        
        print("Picked document at URL: \(url)")
        
        // Start accessing the security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            print("Could not start accessing security scoped resource")
            return
        }
        
        do {
            let jsonData = try Data(contentsOf: url)
            let importedConversation = try JSONDecoder().decode(Conversation.self, from: jsonData)
            
            DispatchQueue.main.async {
                withAnimation {
                    self.conversations.append(importedConversation)
                }
                DataManager.shared.saveConversationHistory(self.conversations)
            }
            
            print("Imported conversation: \(importedConversation)")
            print("Current conversations: \(self.conversations)")
        } catch {
            print("Error importing conversation from JSON: \(error)")
        }
        
        // Stop accessing the security-scoped resource
        url.stopAccessingSecurityScopedResource()
    }
    
    func shareConversationAsJSON(selectedConversationIndex: Int) {
        let conversation = conversations[selectedConversationIndex]
        let jsonFilename = "\(conversation.title).json"

        do {
            let jsonData = try JSONEncoder().encode(conversation)
            guard let jsonFileURL = saveJSONDataToTemporaryFile(jsonData: jsonData, filename: jsonFilename) else { return }

            let activityViewController = UIActivityViewController(activityItems: [jsonFileURL], applicationActivities: nil)

            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
               let viewController = scene.windows.first?.rootViewController {
                viewController.present(activityViewController, animated: true, completion: nil)
            }
        } catch {
            print("Error encoding conversation to JSON: \(error)")
        }
    }

    func saveJSONDataToTemporaryFile(jsonData: Data, filename: String) -> URL? {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(filename)

        do {
            try jsonData.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            print("Error saving JSON data to file: \(error)")
            return nil
        }
    }
}
