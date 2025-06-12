//
//  TalkingStageView.swift
//  UnHinge
//
//  Created by Yohannes Haile on 6/11/25.
//

import SwiftUI
import Combine

struct TalkingStageView: View {
    @StateObject private var viewModel = TalkingStageViewModel()
    @State private var showingNewMatch = false
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.conversations.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No conversations yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                        Text("When you match with someone, you'll be able to chat here")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    List {
                        ForEach(viewModel.conversations) { conversation in
                            NavigationLink(destination: ConversationDetailView(conversation: conversation)) {
                                ConversationRow(conversation: conversation)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Talking Stage")
            .sheet(isPresented: $showingNewMatch) {
                if let match = viewModel.newMatch {
                    NewMatchView(match: match) {
                        showingNewMatch = false
                    }
                }
            }
            .onChange(of: viewModel.newMatch) { match in
                showingNewMatch = match != nil
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: ChatConversation
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            if let imageURL = conversation.match.profileImageURL {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
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
            
            if conversation.messages.contains(where: { !$0.isRead && $0.senderId != FirebaseService.shared.currentUser?.uid }) {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
            }
        }
        .padding(.vertical, 8)
    }
}

struct NewMatchView: View {
    let match: AppUser
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("New Match!")
                .font(.title)
                .bold()
            
            if let imageURL = match.profileImageURL {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 120, height: 120)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.gray)
            }
            
            Text("You matched with \(match.name)!")
                .font(.title2)
            
            Text("Start a conversation to get to know each other better")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: onDismiss) {
                Text("Start Chatting")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    TalkingStageView()
}


