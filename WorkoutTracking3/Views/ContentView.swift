//
//  ContentView.swift
//  WorkoutTracking3
//
//  Created by Chris Peloso on 3/9/22.
//

import SwiftUI

struct ContentView: View {
//    @EnvironmentObject var userData: UserData  // No @StateObject here

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
            SettingsView()
                .tabItem {
                    Image(systemName: "info.circle.fill")
                    Text("Info")
                }
                .environmentObject(UserData.shared)
        }
    }
}
