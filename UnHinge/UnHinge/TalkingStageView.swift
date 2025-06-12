//
//  TalkingStageView.swift
//  UnHinge
//
//  Created by Yohannes Haile on 6/11/25.
//

import SwiftUI

struct TalkingStageView: View {
    @State private var conversations: [Conversation] = [
        Conversation(match: Match(name: "Dagim", imageName: "person1", isNew: true),
                     messages: [
                        Message(text: "Hey, how are you?", isSentByUser: false),
                        Message(text: "I'm good, thanks!", isSentByUser: true)
                     ]),
        Conversation(match: Match(name: "Eleni", imageName: "person2", isNew: false),
                     messages: [
                        Message(text: "Are you coming tomorrow?", isSentByUser: true),
                        Message(text: "Yes, see you there!", isSentByUser: false)
                     ]),
        Conversation(match: Match(name: "Hana", imageName: "person3", isNew: true),
                     messages: [
                        Message(text: "What’s up?", isSentByUser: false)
                     ]),
        
        Conversation(match: Match(name: "Sara", imageName: "person4", isNew: true),
                     messages: [
                        Message(text: "You are funny 😆", isSentByUser: false)
                     ])
    ]
    
    private var matches: [Match] {
        conversations.map { $0.match }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(matches) { match in
                            ZStack(alignment: .topTrailing) {
                                if match.isNew {
                                    Image(match.imageName)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 70, height: 70)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle().stroke(match.isNew ? Color.red : Color.clear, lineWidth: 4)
                                        )
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                List {
                    ForEach(conversations) { conversation in
                        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
                            NavigationLink(destination: ConversationDetailView(conversation: $conversations[index])) {
                                HStack {
                                    Image(conversation.match.imageName)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                    
                                    VStack(alignment: .leading) {
                                        Text(conversation.match.name)
                                            .font(.headline)
                                        if let lastMessage = conversation.messages.last {
                                            Text(lastMessage.text)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                                .lineLimit(1)
                                        }
                                    }
                                    Spacer()
                                    if let lastMessage = conversation.messages.last, lastMessage.isSentByUser == false {
                                        Image(systemName: "circle.fill")
                                            .foregroundColor(.red)
                                            .font(.system(size: 16))
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                
            }
        }
    }
}

#Preview {
//    TalkingStageView(conversations: )
}


