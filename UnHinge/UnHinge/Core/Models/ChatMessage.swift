import Foundation

struct ChatMessage: Identifiable, Codable {
    let id: String
    let text: String
    let senderId: String
    let timestamp: Date
    let isRead: Bool
    
    init(id: String = UUID().uuidString,
         text: String,
         senderId: String,
         timestamp: Date = Date(),
         isRead: Bool = false) {
        self.id = id
        self.text = text
        self.senderId = senderId
        self.timestamp = timestamp
        self.isRead = isRead
    }
}

extension ChatMessage {
    var firestoreData: [String: Any] {
        return [
            "id": id,
            "text": text,
            "senderId": senderId,
            "timestamp": timestamp,
            "isRead": isRead
        ]
    }
    
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let text = dictionary["text"] as? String,
              let senderId = dictionary["senderId"] as? String,
              let timestamp = (dictionary["timestamp"] as? Date),
              let isRead = dictionary["isRead"] as? Bool else {
            return nil
        }
        
        self.id = id
        self.text = text
        self.senderId = senderId
        self.timestamp = timestamp
        self.isRead = isRead
    }
} 