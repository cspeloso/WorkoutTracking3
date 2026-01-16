//
//  ContentView.swift
//  WorkoutTracking3
//
//  Created by Chris Peloso on 3/9/22.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationView { RoutineView() }
                .tabItem { Label("Routines", systemImage: "list.bullet.circle.fill") }

            NavigationView { ExerciseView() }
                .tabItem { Label("Exercises", systemImage: "figure.walk.circle.fill") }

            NavigationView { SettingsView() }
                .tabItem { Label("Info", systemImage: "info.circle.fill") }
        }
        .environmentObject(UserData.shared)
    }
}
