//
//  ContentView.swift
//  Work It Out Apple Watch Watch App
//
//  Created by Chris Peloso on 1/12/24.
//

import SwiftUI

struct ContentView: View {

    @ObservedObject var userData = UserData()
    
    var body: some View {
        TabView {
            RoutineView()
                .tabItem {
                    Image(systemName: "list.bullet.circle.fill")
                    Text("Routines")
                }
            ExerciseView()
                .tabItem {
                    Image(systemName: "figure.walk.circle.fill")
                    Text("Exercises")
                }
            
//            TestView()
                SettingsView()
                .tabItem {
                    Image(systemName: "info.circle.fill")
                    Text("Info")
//                    Image(systemName: "gear")
//                    Text("Settings")
                }
        }
        .environmentObject(userData)
    }
}

#Preview {
    ContentView()
}
