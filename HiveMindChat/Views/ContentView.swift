import SwiftUI

struct ContentView: View {
    @StateObject var conversationListViewModel = ConversationListViewModel(conversations: [])
    @AppStorage("isFirstRun") var isFirstRun = true

    var body: some View {
        NavigationStack {
            if isFirstRun {
                FirstRunView()
            } else {
                ConversationListView()
                    .environmentObject(conversationListViewModel)
            }
        }
    }
}

