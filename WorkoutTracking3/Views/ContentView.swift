//
//  ContentView.swift
//  WorkoutTracking3
//
//  Created by Chris Peloso on 3/9/22.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var userData = UserData()
    
//    let exercises: [Exercise] = Bundle.main.decode("exercises.json")

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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
