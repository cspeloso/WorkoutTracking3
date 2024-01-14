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
        NavigationView {
            List {
                NavigationLink(destination: RoutineView()) {
                    Label("Routines", systemImage: "list.bullet.circle.fill")
                }
                NavigationLink(destination: ExerciseView()) {
                    Label("Exercises", systemImage: "figure.walk.circle.fill")
                }
                NavigationLink(destination: SettingsView()) {
                    Label("Info", systemImage: "info.circle.fill")
                }
            }
        }
        .environmentObject(userData)
    }
}

#Preview {
    ContentView()
}
