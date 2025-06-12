//
//  ConversationDetailView.swift
//  UnHinge
//
//  Created by Yohannes Haile on 6/11/25.
//

import SwiftUI
import Combine

struct ConversationDetailView: View {
    let conversation: ChatConversation
    @StateObject private var viewModel: TalkingStageViewModel
    @State private var messageText = ""
    @FocusState private var isFocused: Bool
    
    init(conversation: ChatConversation) {
        self.conversation = conversation
        _viewModel = StateObject(wrappedValue: TalkingStageViewModel())
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(conversation.messages) { message in
                            MessageBubble(message: message, isFromCurrentUser: message.senderId == FirebaseService.shared.currentUser?.id)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: conversation.messages.count) { _ in
                    if let lastMessage = conversation.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Message Input
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 12) {
                    TextField("Type a message...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isFocused)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(messageText.isEmpty ? .gray : .blue)
                    }
                    .disabled(messageText.isEmpty)
                }
                .padding()
            }
            .background(Color(.systemBackground))
        }
        .navigationTitle(conversation.match.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Mark messages as read when conversation is opened
            conversation.messages
                .filter { !$0.isRead && $0.senderId != FirebaseService.shared.currentUser?.id }
                .forEach { message in
                    viewModel.markAsRead(message, in: conversation)
                }
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        viewModel.sendMessage(messageText, in: conversation)
        messageText = ""
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer()
            }
            
            Text(message.text)
                .padding(12)
                .background(isFromCurrentUser ? Color.blue : Color(.systemGray5))
                .foregroundColor(isFromCurrentUser ? .white : .primary)
                .cornerRadius(16)
            
            if !isFromCurrentUser {
                Spacer()
            }
        }
    }
}

#Preview {
    NavigationView {
        ConversationDetailView(
            conversation: ChatConversation(
                id: "preview",
                match: AppUser(id: "preview", email: "preview@example.com", name: "Preview User"),
                messages: [
                    ChatMessage(
                        id: "1",
                        text: "Hey, how are you?",
                        senderId: "other",
                        timestamp: Date(),
                        isRead: true
                    ),
                    ChatMessage(
                        id: "2",
                        text: "I'm good, thanks! How about you?",
                        senderId: "current",
                        timestamp: Date(),
                        isRead: true
                    )
                ],
                lastUpdated: Date()
            )
        )
    }
}
