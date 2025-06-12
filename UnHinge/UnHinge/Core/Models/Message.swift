import Foundation
import FirebaseFirestore

public struct Message: Codable, Identifiable {
    public let id: String
    public let senderId: String
    public let receiverId: String
    public let content: String
    public let timestamp: Date
    public let isRead: Bool
    public let type: MessageType
    
    public enum MessageType: String, Codable {
        case text
        case image
        case meme
        case reaction
    }
    
    public init(id: String = UUID().uuidString,
                senderId: String,
                receiverId: String,
                content: String,
                timestamp: Date = Date(),
                isRead: Bool = false,
                type: MessageType = .text) {
        self.id = id
        self.senderId = senderId
        self.receiverId = receiverId
        self.content = content
        self.timestamp = timestamp
        self.isRead = isRead
        self.type = type
    }
}

extension Message {
    var firestoreData: [String: Any] {
        return [
            "id": id,
            "senderId": senderId,
            "receiverId": receiverId,
            "content": content,
            "timestamp": Timestamp(date: timestamp),
            "isRead": isRead,
            "type": type.rawValue
        ]
    }
    
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let senderId = dictionary["senderId"] as? String,
              let receiverId = dictionary["receiverId"] as? String,
              let content = dictionary["content"] as? String,
              let timestamp = (dictionary["timestamp"] as? Timestamp)?.dateValue(),
              let isRead = dictionary["isRead"] as? Bool,
              let typeRaw = dictionary["type"] as? String,
              let type = MessageType(rawValue: typeRaw) else {
            return nil
        }
        
        self.id = id
        self.senderId = senderId
        self.receiverId = receiverId
        self.content = content
        self.timestamp = timestamp
        self.isRead = isRead
        self.type = type
    }
}

struct ChatConversation: Identifiable, Codable {
    let id: String
    let match: AppUser
    var messages: [ChatMessage]
    let lastUpdated: Date
} 
