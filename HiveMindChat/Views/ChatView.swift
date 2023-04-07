// ChatView.swift

import SwiftUI
import OpenAISwift
import Combine
import MobileCoreServices

struct ChatView: View {
    @Binding var conversations: [Conversation]
    @EnvironmentObject var conversationListViewModel: ConversationListViewModel
    var selectedConversationIndex: Int
    
    @State var isTypingIndicatorVisible: Bool = true
    @State var messageInputHeight: CGFloat = 50
    @State var messageInput: String = ""
    @State var isInitialAssistantResponseFetched: Bool = false
    @State var scrollViewProxy: ScrollViewProxy? = nil
    
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
                }
                .onChange(of: conversations[selectedConversationIndex].messages.count) {_ in
                    scrollViewProxy.scrollTo(conversations[selectedConversationIndex].messages.count - 1)
                }
                .onAppear {
                    self.scrollViewProxy = scrollViewProxy
                }
            }
            
            HStack {
                TextField("HiveMind(model: \"gpt-3.5-turbo\")", text: $messageInput, axis: .vertical)
                    .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                    .lineLimit(...10)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .disabled(!isInitialAssistantResponseFetched)
                    .submitLabel(.send)
                    .onSubmit { sendMessage() }
            }
            .padding(.bottom)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        shareConversationAsImage()
                    }) {
                        Text("Share as Image")
                        Image(systemName: "photo")
                    }
                    Button(action: {
                        conversationListViewModel.shareConversationAsJSON(selectedConversationIndex: selectedConversationIndex)
                    }) {
                        Text("Share as JSON")
                        Image(systemName: "doc.text")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
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
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let lastIndex = conversations[selectedConversationIndex].messages.indices.last {
                        scrollViewProxy?.scrollTo(lastIndex, anchor: .bottom)
                    }
                }
            }
        }
    }
}
