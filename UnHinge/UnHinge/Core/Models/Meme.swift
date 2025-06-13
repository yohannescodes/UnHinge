import Foundation
import FirebaseFirestore

public struct Meme: Codable, Identifiable {
    public var id: String
    public var imageName: String
    public var tags: [String]
    public var uploadedBy: String
    public var uploadedAt: Date
    public var likes: Int
    public var views: Int
    
    public init(id: String = UUID().uuidString,
         imageName: String,
         tags: [String] = [],
         uploadedBy: String,
         uploadedAt: Date = Date(),
         likes: Int = 0,
         views: Int = 0) {
        self.id = id
        self.imageName = imageName
        self.tags = tags
        self.uploadedBy = uploadedBy
        self.uploadedAt = uploadedAt
        self.likes = likes
        self.views = views
    }
    
    public init(dictionary: [String: Any]) {
        self.id = dictionary["id"] as? String ?? UUID().uuidString
        self.imageName = dictionary["imageName"] as? String ?? ""
        self.tags = dictionary["tags"] as? [String] ?? []
        self.uploadedBy = dictionary["uploadedBy"] as? String ?? ""
        self.uploadedAt = (dictionary["uploadedAt"] as? Timestamp)?.dateValue() ?? Date()
        self.likes = dictionary["likes"] as? Int ?? 0
        self.views = dictionary["views"] as? Int ?? 0
    }
    
    public enum CodingKeys: String, CodingKey {
        case id
        case imageName
        case tags
        case uploadedBy
        case uploadedAt
        case likes
        case views
    }
    
    public var dictionary: [String: Any] {
        return [
            "id": id,
            "imageName": imageName,
            "tags": tags,
            "uploadedBy": uploadedBy,
            "uploadedAt": Timestamp(date: uploadedAt),
            "likes": likes,
            "views": views
        ]
    }
} 
