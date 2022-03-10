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
        RoutineView()
            .environmentObject(userData)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
