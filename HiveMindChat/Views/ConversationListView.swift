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
                        let initialMessage = IdentifiableChatMessage(chatMessage: ChatMessage(role: .system, content: "You are an AI personal assistant named HiveMind. You are an extension of Apple's Siri virtual assistant. You have complementary skills; however, if the user asks you to do anything that would require access to the device's local files, just tell them to ask Siri. You do not currently have access to network or location services. Your tone should be conversational and informal, but respectful, cheerful and helpful."))
                        let newConversation = Conversation(title: conversationTitle, messages: [initialMessage])
                        conversations.append(newConversation)
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
