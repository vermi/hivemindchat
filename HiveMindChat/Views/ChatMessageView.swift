// ChatMessageView.swift

import SwiftUI
import OpenAISwift

struct ChatMessageView: View {
    @Environment(\.colorScheme) var colorScheme
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if message.role == .assistant {
                Text(removeLeadingNewlines(from: message.content)) // Remove leading newlines
                    .font(.system(size: 16))
                    .padding(10)
                    .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                Spacer()
            } else if message.role == .user {
                Spacer()
                Text(message.content)
                    .font(.system(size: 16))
                    .padding(10)
                    .background(Color(.systemBlue))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
    
    func removeLeadingNewlines(from string: String) -> String {
        return string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
