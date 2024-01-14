//
//  AddWorkoutView.swift
//  Work It Out Apple Watch Watch App
//
//  Created by Chris Peloso on 1/12/24.
//

import SwiftUI

struct AddWorkoutView: View {
    
    @Binding var workouts: [Workout]
    
    
    @State private var newWorkout: Workout = Workout(name: "", sets: [], loggedSets: [])
    
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>

    
    var body: some View {
        Form {
            
            //  Workout name
            //  Choose a Workout
            Section {
                WorkoutPicker(workoutName: $newWorkout.name)
            } header: {
                Text("Workout")
            }
            
            //  Add new set
            Section {
                NewSetCreator(sets: $newWorkout.sets)
            } header: {
                Text("New set")
            }
            
            //  current sets
            Section {
                ListSets(sets: $newWorkout.sets)
            } header: {
                Text("Sets")
            }
                
        }
        .navigationBarTitle("New workout")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing){
                Button("Save"){
                    workouts.append(newWorkout)
                    self.mode.wrappedValue.dismiss()
                }
                .foregroundColor(newWorkout.name != "" ? .blue : .gray)
                .disabled(newWorkout.name == "")
            }
        }
    }
}

struct AddWorkoutView_Previews: PreviewProvider {
    
    @State static var workouts: [Workout] = []
    
    static var previews: some View {
        AddWorkoutView(workouts: $workouts)
    }
}
