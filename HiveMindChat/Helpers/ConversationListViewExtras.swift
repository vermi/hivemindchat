import SwiftUI
import OpenAISwift
import KeychainSwift

extension ConversationListView {
    func deleteConversation(at offsets: IndexSet) {
        let originalOffsets = offsets.map { indexedSortedConversations[$0].index }
        conversations.remove(atOffsets: IndexSet(originalOffsets))
        DataManager.shared.saveConversationHistory(conversations)
        
        if let selectedConversationIndex = selectedConversationIndex,
           originalOffsets.contains(selectedConversationIndex) {
            // Clear selectedConversationIndex if the selected conversation is deleted
            self.selectedConversationIndex = nil
        }
    }
    
    func loadConversationHistory() {
        conversations = DataManager.shared.loadConversationHistory()
    }
    
    func presentEditConversationTitleAlert(conversation: Binding<Conversation>) {
        let alertController = UIAlertController(title: "Edit Conversation Title", message: "Enter a new title for this conversation.", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.text = conversation.wrappedValue.title
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            if let textField = alertController.textFields?.first, let newTitle = textField.text, !newTitle.isEmpty {
                conversation.wrappedValue.title = newTitle
                DataManager.shared.saveConversationHistory(conversations)
                loadConversationHistory()
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let viewController = scene.windows.first?.rootViewController {
            viewController.present(alertController, animated: true, completion: nil)
        }
    }
    
    func showSettingsView() {
        let settingsView = SettingsView()
        let hostingController = UIHostingController(rootView: settingsView)
        
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let viewController = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            viewController.present(hostingController, animated: true, completion: nil)
        }
    }
    
    func checkForOpenAIAPIToken() {
        if keychain.get("openAIAPIToken") == nil {
            isAPITokenAlertPresented = true
        }
    }
    
    struct StarButtonStyle: ButtonStyle {
        var isFavorite: Bool
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .foregroundColor(isFavorite ? Color(.systemBlue) : Color(.systemGray))
                .opacity(configuration.isPressed ? 0.5 : 1.0)
                .scaleEffect(configuration.isPressed ? 0.8 : 1.0)
        }
    }
}
