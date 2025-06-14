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
                    Image(systemName: "sparkles")
                    Text("Explore")
                }
            
            TalkingStageView()
                .tabItem {
                    Image(systemName: "message")
                    Text("Talking Stage")
                }
            SettingsView()
                .tabItem {
                    Image(systemName: "slider.horizontal.3")
                    Text("Preferences")
                }
        }
    }
}

#if DEBUG
#Preview {
    MainTabView()
}
#endif
