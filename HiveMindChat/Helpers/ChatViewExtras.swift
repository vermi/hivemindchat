import SwiftUI
import OpenAISwift
import Combine
import MobileCoreServices

extension ChatView {
    func fetchInitialAssistantResponse() {
        Task {
            await chat(with: conversations[selectedConversationIndex].messages.map { $0.chatMessage }) { response in
                DispatchQueue.main.async {
                    conversations[selectedConversationIndex].messages.append(IdentifiableChatMessage(chatMessage: response))
                    isInitialAssistantResponseFetched = true
                    isTypingIndicatorVisible = false
                }
            }
        }
    }
    
    func safeMessages() -> [IdentifiableChatMessage] {
        if selectedConversationIndex >= 0 && selectedConversationIndex < conversations.count {
            return conversations[selectedConversationIndex].messages
        } else {
            return []
        }
    }
    
    func sendMessage() {
        guard !messageInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let newMessage = ChatMessage(role: .user, content: messageInput)
        conversations[selectedConversationIndex].messages.append(IdentifiableChatMessage(chatMessage: newMessage))
        messageInput = ""

        // Show typing indicator
        isTypingIndicatorVisible = true

        // Check if the user has just sent their first message
        if isFirstMessage() {
            // Send user's message to the OpenAISwift API and receive the assistant's response
            Task.init {
                await chat(with: conversations[selectedConversationIndex].messages.map { $0.chatMessage }) { assistantMessage in
                    DispatchQueue.main.async {
                        // Add the assistant's response to the conversation
                        conversations[selectedConversationIndex].messages.append(IdentifiableChatMessage(chatMessage: assistantMessage))
                        DataManager.shared.saveConversationHistory(conversations)

                        // Hide typing indicator
                        isTypingIndicatorVisible = false

                        // Generate the caption
                        generateCaption()
                    }
                }
            }
        } else {
            // Only send user's message and receive the assistant's response
            Task.init {
                await chat(with: conversations[selectedConversationIndex].messages.map { $0.chatMessage }) { assistantMessage in
                    DispatchQueue.main.async {
                        // Add the assistant's response to the conversation
                        conversations[selectedConversationIndex].messages.append(IdentifiableChatMessage(chatMessage: assistantMessage))
                        DataManager.shared.saveConversationHistory(conversations)

                        // Hide typing indicator
                        isTypingIndicatorVisible = false
                    }
                }
            }
        }
    }
    
    func isFirstMessage() -> Bool {
        let userMessages = conversations[selectedConversationIndex].messages.filter { $0.chatMessage.role == .user }
        return userMessages.count == 1
    }
    
    func generateCaption() {
        // Filter out system messages and the first assistant message
        let relevantMessages = conversations[selectedConversationIndex].messages
            .enumerated()
            .filter { (index, message) in
                if message.chatMessage.role == .assistant && index == 1 {
                    return false
                }
                return message.chatMessage.role != .system
            }
            .map { $0.element }

        // Concatenate the contents of the filtered messages
        let conversationContent = relevantMessages
            .map { $0.chatMessage.content }
            .joined(separator: " ")

        // Create a chat message for the caption prompt
        let promptMessage = ChatMessage(role: .system, content: "The main topic of the following conversation is: \(conversationContent). Generate a concise and easy-to-understand title that summarizes the main topic of this conversation.")

        // Send the chat message to the OpenAISwift API
        Task.init {
            await chat(with: [promptMessage]) { captionMessage in
                var caption = captionMessage.content.trimmingCharacters(in: .whitespacesAndNewlines)
                caption = caption.trimmingCharacters(in: CharacterSet(charactersIn: "\""))

                DispatchQueue.main.async {
                    // Set the conversation title.
                    conversations[selectedConversationIndex].title = caption
                    // Save conversation with the updated title.
                    DataManager.shared.saveConversationHistory(conversations)
                }
            }
        }
    }

    func loadChatHistory() {
        let chatHistory = conversations[selectedConversationIndex].loadChatHistory()
        if !chatHistory.isEmpty {
            conversations[selectedConversationIndex].messages = chatHistory
        }
    }
    
    func captureConversationAsImage() -> UIImage? {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        for message in conversations[selectedConversationIndex].messages {
            let chatMessageView = UIHostingController(rootView: ChatMessageView(message: message.chatMessage))
            chatMessageView.view.translatesAutoresizingMaskIntoConstraints = false
            stackView.addArrangedSubview(chatMessageView.view)
        }
        
        let containerView = UIView()
        containerView.backgroundColor = UIColor.systemBackground
        containerView.addSubview(stackView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            containerView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width)
        ])
        
        containerView.layoutIfNeeded()
        let targetSize = containerView.bounds.size
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let image = renderer.image { _ in
            containerView.drawHierarchy(in: CGRect(origin: .zero, size: targetSize), afterScreenUpdates: true)
        }
        
        return image
    }
    
    func saveImageToTemporaryFile(image: UIImage, title: String) -> URL? {
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let imageName = title.isEmpty ? "conversation" : title
        let fileURL = temporaryDirectoryURL.appendingPathComponent("\(imageName).jpg")
        
        do {
            let imageData = image.jpegData(compressionQuality: 1.0)
            try imageData?.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving image to temporary file: \(error.localizedDescription)")
            return nil
        }
    }
    
    func shareConversationAsImage() {
        let conversationTitle = conversations[selectedConversationIndex].title
        guard let image = captureConversationAsImage(),
              let imageURL = saveImageToTemporaryFile(image: image, title: conversationTitle) else { return }
        
        let itemProvider = NSItemProvider(contentsOf: imageURL)
        let activityViewController = UIActivityViewController(activityItems: [itemProvider as Any], applicationActivities: nil)
        
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let viewController = scene.windows.first?.rootViewController {
            viewController.present(activityViewController, animated: true, completion: nil)
        }
    }
}
