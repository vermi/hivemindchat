import SwiftUI
import OpenAISwift
import KeychainSwift

struct ConversationListView: View {
    @EnvironmentObject var conversationListViewModel: ConversationListViewModel // Add environment object here
    
    @State var selectedConversationIndex: Int?
    @State var keychain = KeychainSwift()
    @State var isAPITokenAlertPresented: Bool = false
    @State var editedConversationIndex: Int?
    @State var isNewConversationLinkActive: Bool = false
    
    var indexedSortedConversations: [(index: Int, conversation: Conversation)] {
        let sortedConversations = conversationListViewModel.conversations.enumerated().sorted { left, right in
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
        List {
            if conversationListViewModel.conversations.isEmpty {
                Text("No conversations yet. Why not start one?")
            } else {
                ForEach(indexedSortedConversations, id: \.conversation.id) { indexedConversation in
                    let originalIndex = indexedConversation.index
                    let conversation = indexedConversation.conversation
                    NavigationLink(destination: ChatView(conversations: $conversationListViewModel.conversations, selectedConversationIndex: originalIndex)
                        .environmentObject(conversationListViewModel)
                    ) {
                        HStack {
                            Button(action: {
                                conversationListViewModel.conversations[originalIndex].isFavorite.toggle()
                                DataManager.shared.saveConversationHistory(conversationListViewModel.conversations)
                                loadConversationHistory()
                            }) {
                                Image(systemName: conversation.isFavorite ? "star.fill" : "star")
                            }
                            .buttonStyle(StarButtonStyle(isFavorite: conversation.isFavorite))
                            
                            ConversationRow(conversation: conversation)
                        }
                    }
                    .listRowSeparator(.hidden)
                    .onChange(of: editedConversationIndex) { index in
                        if let index = index {
                            conversationListViewModel.conversations[index].objectWillChange.send()
                            DataManager.shared.saveConversationHistory(conversationListViewModel.conversations)
                        }
                    }
                    .tag(originalIndex)
                    .contextMenu {
                        Button(action: {
                            presentEditConversationTitleAlert(conversation: $conversationListViewModel.conversations[originalIndex])
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
                    conversationListViewModel.conversations.move(fromOffsets: indices, toOffset: newOffset)
                    if let selectedConversationIndex = selectedConversationIndex,
                       indices.contains(selectedConversationIndex) {
                        // Update selectedConversationIndex if the selected conversation is moved
                        let newSelectedIndex = selectedConversationIndex - indices.count + newOffset
                        self.selectedConversationIndex = newSelectedIndex
                    }
                    DataManager.shared.saveConversationHistory(conversationListViewModel.conversations)
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
        .navigationBarItems(
            leading: Button(action: {
                showSettingsView()
            }) {
                Image(systemName: "gear")
            },
            trailing: Menu {
                Button(action: {
                    createNewConversation()
                }) {
                    Text("New Conversation")
                    Image(systemName: "square.and.pencil")
                }
                Button(action: {
                    importConversationFromJSON()
                }) {
                    Text("Import from JSON")
                    Image(systemName: "square.and.arrow.down")
                }
            } label: {
                Image(systemName: "plus")
            }
        )
        .background(
            NavigationLink("", destination: ChatView(conversations: $conversationListViewModel.conversations, selectedConversationIndex: conversationListViewModel.conversations.count - 1)
                .environmentObject(conversationListViewModel), isActive: $isNewConversationLinkActive)
            .opacity(0)
        )
    }
}
