//
//  MainTabView.swift
//  UnHinge
//
//  Created by Yohannes Haile on 6/11/25.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            MemeSwipeView()
                .tabItem {
                    Image(systemName: "globe")
                    Text("Explore")
                }
            
            TalkingStageView()
                .tabItem {
                    Image(systemName: "message")
                    Text("Talking Stage")
                }

            VStack {
                Text("Settings")
                    .font(.largeTitle)
                    .padding()
                Spacer()
            }
            .tabItem {
                Image(systemName: "gearshape")
                Text("Settings")
            }
        }
    }
}

#if DEBUG
#Preview {
    MainTabView()
}
#endif
