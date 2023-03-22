// APIInterface.swift

import Foundation
import OpenAISwift
import KeychainSwift

func chat(with chatMessages: [ChatMessage], onResponseReceived: @escaping (ChatMessage) -> Void) async {
    let keychain = KeychainSwift()
    guard let authToken = keychain.get("openAIAPIToken") else {
        print("API token not found")
        return
    }
    
    do {
        let openAI = OpenAISwift(authToken: authToken)
        let result = try await openAI.sendChat(with: chatMessages)
        
        if let response = result.choices.first?.message.content {
            let assistantMessage = ChatMessage(role: .assistant, content: response)
            onResponseReceived(assistantMessage)
        } else {
            print("No response")
        }
    } catch {
        print("Something went wrong")
        print("Error: \(error.localizedDescription)")
    }
}
