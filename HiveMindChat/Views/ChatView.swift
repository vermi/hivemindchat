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
                        ForEach(0..<safeMessages().count, id: \.self) { index in
                            let identifiableChatMessage = safeMessages()[index]
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
                                }
                        }
                    }.listRowSeparator(.hidden)
                        .padding(.top, 8) // Add padding to the top of the message list
                        .padding(.bottom, messageInputHeight + 16)
                        .background(Color(.systemBackground)) // Set the background color of the message list
                }.onReceive(scrollPublisher, perform: { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        withAnimation {
                            scrollViewProxy.scrollTo(conversations[selectedConversationIndex].messages.last?.id, anchor: .bottom)
                        }
                    }
                })
            }
            
            HStack {
                CustomTextField(text: $messageInput, placeholder: "HiveMind(model: \"gpt-3.5-turbo\")", onCommit: {
                    sendMessage()
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                }
                .contextMenu {
                    Button(action: {
                        shareConversationAsImage()
                    }) {
                        Text("Share as Image")
                        Image(systemName: "photo")
                    }
                    Button(action: {
                        shareConversationAsJSON()
                    }) {
                        Text("Share as JSON")
                        Image(systemName: "doc.text")
                    }
                }
            }
        }
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .background(Color(.systemBackground))
        .onAppear {
            DispatchQueue.main.async {
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
}
