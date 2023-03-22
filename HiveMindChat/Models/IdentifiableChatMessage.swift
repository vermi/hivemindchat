import Foundation
import OpenAISwift

struct IdentifiableChatMessage: Identifiable, Equatable, Codable {
    let id: UUID
    let chatMessage: ChatMessage

    static func ==(lhs: IdentifiableChatMessage, rhs: IdentifiableChatMessage) -> Bool {
        return lhs.id == rhs.id
    }

    enum CodingKeys: CodingKey {
        case id, chatMessage
    }

    init(id: UUID = UUID(), chatMessage: ChatMessage) {
        self.id = id
        self.chatMessage = chatMessage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        chatMessage = try container.decode(ChatMessage.self, forKey: .chatMessage)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(chatMessage, forKey: .chatMessage)
    }
}
