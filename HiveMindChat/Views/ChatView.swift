// ChatView.swift

import SwiftUI
import OpenAISwift
import Combine
import MobileCoreServices

struct ChatView: View {
    @Binding var conversations: [Conversation]
    var selectedConversationIndex: Int
    
    @State var scrollPublisher = PassthroughSubject<Void, Never>()
    @State var isTypingIndicatorVisible: Bool = true
    @State var messageInputHeight: CGFloat = 50
    @State var messageInput: String = ""
    @State var isInitialAssistantResponseFetched: Bool = false
    
    struct ViewHeightKey: PreferenceKey {
        typealias Value = CGFloat
        static var defaultValue: CGFloat = 0
        
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }
    
    var body: some View {
        VStack {
            if isTypingIndicatorVisible {
                TypingIndicatorView()
                    .padding(.top)
                    .transition(.scale)
            }
            
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    LazyVStack(spacing: 8) { // Add spacing between messages
                        ForEach(conversations[selectedConversationIndex].messages) { identifiableChatMessage in
                            ChatMessageView(message: identifiableChatMessage.chatMessage)
                                .contextMenu {
                                    Button(action: {
                                        UIPasteboard.general.string = identifiableChatMessage.chatMessage.content
                                    }) {
                                        Text("Copy")
                                        Image(systemName: "doc.on.doc")
                                    }
                                    Button(action: {
                                        conversations[selectedConversationIndex].messages.removeAll()
                                        DataManager.shared.saveConversationHistory(conversations)
                                    }) {
                                        Text("Clear History")
                                        Image(systemName: "trash")
                                    }
                                    Button(action: {
                                        let conversationTitle = conversations[selectedConversationIndex].title
                                        guard let image = captureConversationAsImage(),
                                              let imageURL = saveImageToTemporaryFile(image: image, title: conversationTitle) else { return }
                                        
                                        let itemProvider = NSItemProvider(contentsOf: imageURL)
                                        let activityViewController = UIActivityViewController(activityItems: [itemProvider as Any], applicationActivities: nil)
                                        
                                        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                                           let viewController = scene.windows.first?.rootViewController {
                                            viewController.present(activityViewController, animated: true, completion: nil)
                                        }
                                    }) {
                                        Text("Share as Image")
                                        Image(systemName: "square.and.arrow.up")
                                    }
                                }
                        }
                    }
                    .padding(.top, 8) // Add padding to the top of the message list
                    .padding(.bottom, messageInputHeight + 16)
                    .background(Color(.systemGray6)) // Set the background color of the message list
                }.onReceive(scrollPublisher, perform: { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        withAnimation {
                            scrollViewProxy.scrollTo(conversations[selectedConversationIndex].messages.last?.id, anchor: .bottom)
                        }
                    }
                })
            }
            
            HStack {
                CustomTextField(text: $messageInput, placeholder: "SiriGPT(model: \"gpt-3.5-turbo\")", onCommit: {
                    sendMessage()
                })
                .background(GeometryReader { geometry in
                    Color.clear.preference(key: ViewHeightKey.self, value: geometry.size.height)
                })
                .onPreferenceChange(ViewHeightKey.self) { height in
                    withAnimation {
                        messageInputHeight = height >= 40 ? height : 40
                    }
                }
                .frame(height: messageInputHeight) // Update the frame
                .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                .padding(.horizontal)
                .disabled(!isInitialAssistantResponseFetched)
            }.padding(.bottom)
        }
        .background(Color(.systemGray6))
        .onAppear {
            loadChatHistory()
            if !isInitialAssistantResponseFetched && !conversations[selectedConversationIndex].messages.contains(where: { $0.chatMessage.role == .assistant }) {
                fetchInitialAssistantResponse()
            } else {
                isInitialAssistantResponseFetched = true
                isTypingIndicatorVisible = false
            }
        }
    }
}
