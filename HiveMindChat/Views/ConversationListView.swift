import SwiftUI
import OpenAISwift
import KeychainSwift

struct ConversationListView: View {
    @StateObject var viewModel: ConversationListViewModel
    @State var selectedConversationIndex: Int?
    @State var keychain = KeychainSwift()
    @State var isAPITokenAlertPresented: Bool = false
    @State var editedConversationIndex: Int?
    
    var indexedSortedConversations: [(index: Int, conversation: Conversation)] {
        let sortedConversations = viewModel.conversations.enumerated().sorted { left, right in
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
                if viewModel.conversations.isEmpty {
                    Text("No conversations yet. Why not start one?")
                } else {
                    ForEach(indexedSortedConversations, id: \.conversation.id) { indexedConversation in
                        let originalIndex = indexedConversation.index
                        let conversation = indexedConversation.conversation
                        NavigationLink(destination: ChatView(conversations: $viewModel.conversations, selectedConversationIndex: originalIndex)) {
                            HStack {
                                Button(action: {
                                    viewModel.conversations[originalIndex].isFavorite.toggle()
                                    DataManager.shared.saveConversationHistory(viewModel.conversations)
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
                                viewModel.conversations[index].objectWillChange.send()
                                DataManager.shared.saveConversationHistory(viewModel.conversations)
                            }
                        }
                        .tag(originalIndex)
                        .contextMenu {
                            Button(action: {
                                presentEditConversationTitleAlert(conversation: $viewModel.conversations[originalIndex])
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
                        viewModel.conversations.move(fromOffsets: indices, toOffset: newOffset)
                        if let selectedConversationIndex = selectedConversationIndex,
                           indices.contains(selectedConversationIndex) {
                            // Update selectedConversationIndex if the selected conversation is moved
                            let newSelectedIndex = selectedConversationIndex - indices.count + newOffset
                            self.selectedConversationIndex = newSelectedIndex
                        }
                        DataManager.shared.saveConversationHistory(viewModel.conversations)
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
                    Menu {
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
                }
            }
            .toolbarBackground(Color(.systemBackground), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}
