import SwiftUI
import OpenAISwift

struct ConversationRow: View {
    var conversation: Conversation
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(conversation.title)
                .font(.headline)
            Text(conversation.messages.last?.chatMessage.role != .system ? conversation.messages.last?.chatMessage.content ?? "" : "")
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(1)
        }
    }
}
