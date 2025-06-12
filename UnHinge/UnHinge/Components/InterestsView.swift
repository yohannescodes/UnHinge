import SwiftUI

public struct InterestsView: View {
    public let interests: [String]
    
    public init(interests: [String]) {
        self.interests = interests
    }
    
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(interests, id: \.self) { interest in
                    Text(interest)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
        }
    }
} 