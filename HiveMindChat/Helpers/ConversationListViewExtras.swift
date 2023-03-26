import SwiftUI
import OpenAISwift
import KeychainSwift

extension ConversationListView {
    func deleteConversation(at offsets: IndexSet) {
        let originalOffsets = offsets.map { indexedSortedConversations[$0].index }
        conversationListViewModel.conversations.remove(atOffsets: IndexSet(originalOffsets))
        DataManager.shared.saveConversationHistory(conversationListViewModel.conversations)
        
        if let selectedConversationIndex = selectedConversationIndex,
           originalOffsets.contains(selectedConversationIndex) {
            // Clear selectedConversationIndex if the selected conversation is deleted
            self.selectedConversationIndex = nil
        }
    }
    
    func loadConversationHistory() {
        conversationListViewModel.conversations = DataManager.shared.loadConversationHistory()
    }
    
    func getUserName() -> String {
        if let userName = UserDefaults.standard.string(forKey: "userName") {
            return userName
        } else {
            return "User"
        }
    }
    
    func presentEditConversationTitleAlert(conversation: Binding<Conversation>) {
        let alertController = UIAlertController(title: "Edit Conversation Title", message: "Enter a new title for this conversation.", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.text = conversation.wrappedValue.title
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            if let textField = alertController.textFields?.first, let newTitle = textField.text, !newTitle.isEmpty {
                conversation.wrappedValue.title = newTitle
                DataManager.shared.saveConversationHistory(conversationListViewModel.conversations)
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
    
    func createNewConversation() {
        let now = Date()
        let dateFormatter = ISO8601DateFormatter()
        let conversationTitle = "Text Chat " + dateFormatter.string(from: now)
        let userName = getUserName()
        let initialMessage = IdentifiableChatMessage(chatMessage: ChatMessage(role: .system, content: "You are HiveMind, an AI personal assistant designed to complement Siri by providing ideas, suggestions, and information where Siri's knowledge might fall short. You cannot access device files, send messages, set reminders, or interact with network or location services. If asked, kindly direct the user to Siri. Maintain a conversational, informal, respectful, cheerful, and helpful tone, prioritizing insightful and creative assistance. Address the user as \(userName) and greet them by name in your first message. Briefly explain your purpose and functionality without being overly verbose."
                                                                              
                                                                             ))
        let newConversation = Conversation(title: conversationTitle, messages: [initialMessage])
        withAnimation {
            conversationListViewModel.conversations.append(newConversation)
            DispatchQueue.main.async {
                selectedConversationIndex = conversationListViewModel.conversations.count - 1
            }
        }
    }
    
    func importConversationFromJSON() {
        conversationListViewModel.importConversationFromJSON()
    }
}
