//
//  WorkoutDetailsView.swift
//  WorkoutTracking3
//
//  Created by Chris Peloso on 3/9/22.
//

import SwiftUI

struct WorkoutDetailsView: View {
    
    @Binding var workout: Workout
    
    var body: some View {
        Form {
            
            //  Workout name
            Section {
                WorkoutPicker(workoutName: $workout.name)
            } header: {
                Text("Workout")
            }
            
            //  add a new set
            Section {
                NewSetCreator(sets: $workout.sets)
            } header: {
                Text("Add new sets")
            }
            
            //  sets list
            Section {
                ListSets(sets: $workout.sets)
            } header: {
                Text("Sets")
            }
        }
        .navigationBarTitle(workout.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WorkoutDetailsView_Previews: PreviewProvider {
    
    @State static var workout: Workout = Workout(name: "test", sets: [])
    
    static var previews: some View {
        WorkoutDetailsView(workout: $workout)
    }
}
