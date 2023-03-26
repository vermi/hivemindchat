import SwiftUI

struct ContentView: View {
    @State private var conversations: [Conversation] = []

    var body: some View {
        ConversationListView(viewModel: ConversationListViewModel(conversations: conversations))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
