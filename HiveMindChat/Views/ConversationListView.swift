import SwiftUI
import OpenAISwift
import KeychainSwift

struct ConversationListView: View {
    @Binding var conversations: [Conversation]
    @State var selectedConversationIndex: Int?
    @State var keychain = KeychainSwift()
    @State var isAPITokenAlertPresented: Bool = false
    @State var editedConversationIndex: Int?
    
    var indexedSortedConversations: [(index: Int, conversation: Conversation)] {
        let sortedConversations = conversations.enumerated().sorted { left, right in
            if left.element.isFavorite != right.element.isFavorite {
                return left.element.isFavorite
            } else if left.element.timestamp != right.element.timestamp {
                return left.element.timestamp > right.element.timestamp
            }
            return left.offset < right.offset
        }
        return sortedConversations.map { ($0.offset, $0.element) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if conversations.isEmpty {
                    Text("No conversations yet. Why not start one?")
                } else {
                    ForEach(indexedSortedConversations, id: \.conversation.id) { indexedConversation in
                        let originalIndex = indexedConversation.index
                        let conversation = indexedConversation.conversation
                        NavigationLink(destination: ChatView(conversations: $conversations, selectedConversationIndex: originalIndex)) {
                            HStack {
                                Button(action: {
                                    conversations[originalIndex].isFavorite.toggle()
                                    DataManager.shared.saveConversationHistory(conversations)
                                    loadConversationHistory()
                                }) {
                                    Image(systemName: conversation.isFavorite ? "star.fill" : "star")
                                }
                                .buttonStyle(StarButtonStyle(isFavorite: conversation.isFavorite))
                                
                                ConversationRow(conversation: conversation)
                            }
                        }
                        .onChange(of: editedConversationIndex) { index in
                            if let index = index {
                                conversations[index].objectWillChange.send()
                                DataManager.shared.saveConversationHistory(conversations)
                            }
                        }
                        .tag(originalIndex)
                        .contextMenu {
                            Button(action: {
                                presentEditConversationTitleAlert(conversation: $conversations[originalIndex])
                            }) {
                                Text("Edit Title")
                                Image(systemName: "pencil")
                            }
                        }
                        .onAppear {
                            // Set the selectedConversationIndex when the NavigationLink appears
                            selectedConversationIndex = originalIndex
                        }
                    }
                    .onDelete(perform: deleteConversation)
                    .onMove(perform: { indices, newOffset in
                        conversations.move(fromOffsets: indices, toOffset: newOffset)
                        if let selectedConversationIndex = selectedConversationIndex,
                           indices.contains(selectedConversationIndex) {
                            // Update selectedConversationIndex if the selected conversation is moved
                            let newSelectedIndex = selectedConversationIndex - indices.count + newOffset
                            self.selectedConversationIndex = newSelectedIndex
                        }
                        DataManager.shared.saveConversationHistory(conversations)
                    })
                }
                
            }
            .id(UUID())
            .alert(isPresented: $isAPITokenAlertPresented) {
                Alert(
                    title: Text("OpenAI API Token Required"),
                    message: Text("Please enter your OpenAI API token in the Settings pane."),
                    primaryButton: .default(Text("Go to Settings"), action: {
                        showSettingsView()
                    }),
                    secondaryButton: .cancel()
                )
            }
            .onAppear {
                checkForOpenAIAPIToken()
                loadConversationHistory()
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Conversations")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showSettingsView()
                    }) {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        let now = Date()
                        let dateFormatter = ISO8601DateFormatter()
                        let conversationTitle = "Text Chat " + dateFormatter.string(from: now)
                        let userName = getUserName()
                        let initialMessage = IdentifiableChatMessage(chatMessage: ChatMessage(role: .system, content: "You are HiveMind, an AI personal assistant designed to complement Siri by providing ideas, suggestions, and information where Siri's knowledge might fall short. You cannot access device files, send messages, set reminders, or interact with network or location services. If asked, kindly direct the user to Siri. Maintain a conversational, informal, respectful, cheerful, and helpful tone, prioritizing insightful and creative assistance. Address the user as \(userName) and greet them by name in your first message. Briefly explain your purpose and functionality without being overly verbose."
                                                                                              
))
                        let newConversation = Conversation(title: conversationTitle, messages: [initialMessage])
                        withAnimation {
                            conversations.append(newConversation)
                            DispatchQueue.main.async {
                                    selectedConversationIndex = conversations.count - 1
                                }
                        }
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .toolbarBackground(Color(.systemBackground), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}
