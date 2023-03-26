import SwiftUI

struct ContentView: View {
    @StateObject var conversationListViewModel = ConversationListViewModel(conversations: [])

    var body: some View {
        NavigationStack {
            ConversationListView()
                .environmentObject(conversationListViewModel)
        }
    }
}
