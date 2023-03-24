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
        let userMessage = ChatMessage(role: .user, content: messageInput)
        conversations[selectedConversationIndex].messages.append(IdentifiableChatMessage(chatMessage: userMessage))
        scrollPublisher.send()
        
        DataManager.shared.saveConversationHistory(conversations) // Save the entire conversation history here
        
        messageInput = ""
        isTypingIndicatorVisible = true
        
        Task {
            await chat(with: conversations[selectedConversationIndex].messages.map { $0.chatMessage }) { response in
                DispatchQueue.main.async {
                    conversations[selectedConversationIndex].messages.append(IdentifiableChatMessage(chatMessage: response))
                    isTypingIndicatorVisible = false
                    scrollPublisher.send()
                    
                    DataManager.shared.saveConversationHistory(conversations) // Save the entire conversation history here
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
}
