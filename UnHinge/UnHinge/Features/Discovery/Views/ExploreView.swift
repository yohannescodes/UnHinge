//
//  ExploreView.swift
//  UnHinge
//
//  Created by Yohannes Haile on 6/11/25.
//

import SwiftUI

struct ExploreView: View {
    var body: some View {
        VStack {
            Spacer()
            Spacer()
            Spacer()
            ZStack {
                Image("meme1")
                    .resizable()
                    .renderingMode(.original)
                    .border(Color.red, width: 4)
                    .frame(width: 340, height: 400)
                    .cornerRadius(40)
                    
                Image("meme2")
                    .resizable()
                    .renderingMode(.original)
                    .border(Color.red, width: 4)
                    .frame(width: 340, height: 400)
                    .cornerRadius(40)
                Image("meme3")
                    .resizable()
                    .renderingMode(.original)
                    .border(Color.red, width: 4)
                    .frame(width: 340, height: 400)
                    .cornerRadius(40)
                Image("meme4")
                    .resizable()
                    .renderingMode(.original)
                    .border(Color.red, width: 4)
                    .frame(width: 340, height: 400)
                    .cornerRadius(40)
            }
        Spacer()
            HStack(spacing: 67) {
                
                Button {
                    
                } label: {
                    Image(systemName: "bolt.heart.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 42, height: 34)
                }
                
                Button {
                    
                } label: {
                    Image(systemName: "theatermasks.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 65)
                }
                
                Button {
                    
                } label: {
                    Image(systemName: "heart.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 42, height: 34)
                }
            }
            Spacer()
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    ExploreView()
}

