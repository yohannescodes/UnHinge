//
//  ConversationDetailView.swift
//  UnHinge
//
//  Created by Yohannes Haile on 6/11/25.
//

import SwiftUI

struct ConversationDetailView: View {
    @Binding var conversation: Conversation
    @State private var newMessageText: String = ""
    
    var body: some View {
        VStack {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(conversation.messages) { message in
                            HStack {
                                if message.isSentByUser {
                                    Spacer()
                                    Text(message.text)
                                        .padding(10)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                } else {
                                    Text(message.text)
                                        .padding(10)
                                        .background(Color.gray.opacity(0.3))
                                        .foregroundColor(.black)
                                        .cornerRadius(10)
                                    Spacer()
                                }
                            }
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: conversation.messages.count) { _ in
                    if let last = conversation.messages.last {
                        scrollProxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            
            HStack {
                TextField("Type a message", text: $newMessageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    let trimmed = newMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    let message = Message(text: trimmed, isSentByUser: true)
                    conversation.messages.append(message)
                    newMessageText = ""
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        let reply = Message(text: "This is an auto-reply from \(conversation.match.name)!", isSentByUser: false)
                        conversation.messages.append(reply)
                    }
                }) {
                    Text("Send")
                        .bold()
                }
            }
            .padding()
        }
        .navigationTitle(conversation.match.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
