import Foundation
import Combine

class Conversation: Identifiable, Codable, ObservableObject {
    var id: UUID
    @Published var title: String
    @Published var messages: [IdentifiableChatMessage]
    var timestamp: Date
    @Published var isFavorite: Bool
    
    init(id: UUID? = nil, title: String, messages: [IdentifiableChatMessage] = []) {
        self.id = id ?? UUID()
        self.title = title
        self.messages = messages
        self.timestamp = Date()
        self.isFavorite = false
    }
    
    func saveTitle() {
        UserDefaults.standard.set(title, forKey: "\(id.uuidString)_title")
    }
    
    func saveChatHistory() {
        let key = "\(id.uuidString)_messages"
        do {
            let data = try DataManager.shared.encoder.encode(messages)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Error saving chat history for conversation \(id.uuidString), error: \(error.localizedDescription)")
        }
    }
    
    func loadChatHistory() -> [IdentifiableChatMessage] {
        let key = "\(id.uuidString)_messages"
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return []
        }
        
        do {
            let chatHistory = try DataManager.shared.decodeData([IdentifiableChatMessage].self, from: data)
            return chatHistory
        } catch {
            print("Error loading chat history for conversation \(id.uuidString), error: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: Codable conformance for classes
    enum CodingKeys: CodingKey {
        case id, title, messages, timestamp, isFavorite
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        messages = try container.decode([IdentifiableChatMessage].self, forKey: .messages)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
        
        _ = self.$messages.sink(receiveValue: { _ in
            self.saveChatHistory()
        })
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(messages, forKey: .messages)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(isFavorite, forKey: .isFavorite)
    }
}
