import SwiftUI

class DataManager {
    static let shared = DataManager()
    
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    private let conversationsKey = "conversations"
    
    private init() {}
    
    func saveConversationHistory(_ conversations: [Conversation]) {
        do {
            let data = try encoder.encode(conversations)
            UserDefaults.standard.set(data, forKey: conversationsKey)
        } catch {
            print("Error saving conversation history, error: \(error.localizedDescription)")
        }
    }
    
    func loadConversationHistory() -> [Conversation] {
        guard let data = UserDefaults.standard.data(forKey: conversationsKey) else {
            return []
        }
        
        do {
            let conversations = try decodeData([Conversation].self, from: data)
            return conversations
        } catch {
            print("Error loading conversation history, error: \(error.localizedDescription)")
            return []
        }
    }
    
    func decodeData<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try decoder.decode(type, from: data)
    }
}
