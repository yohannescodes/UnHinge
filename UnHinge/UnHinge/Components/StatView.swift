import SwiftUI

public struct StatView: View {
    public let title: String
    public let value: String
    public var color: Color = .primary
    
    public init(title: String, value: String, color: Color = .primary) {
        self.title = title
        self.value = value
        self.color = color
    }
    
    public var body: some View {
        VStack {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 60)
    }
} 