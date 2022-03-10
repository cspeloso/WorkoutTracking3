//
//  WorkoutPicker.swift
//  WorkoutTracking3
//
//  Created by Chris Peloso on 3/9/22.
//

import SwiftUI


struct WorkoutPickerListView: View {
    @Binding var workoutName: String
    
    let exercises: [Exercise] = Bundle.main.decode("exercises.json")
    
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>

    var body: some View {
        List {
            ForEach(exercises.sorted(by: {$0.name < $1.name})) { exercise in
                Button(exercise.name) {
                    workoutName = exercise.name
                    self.mode.wrappedValue.dismiss()
                }
                .foregroundColor(.primary)
            }
        }
    }
    
    
}

struct WorkoutPicker: View {
    
    @Binding var workoutName: String
    
    let exercises: [Exercise] = Bundle.main.decode("exercises.json")
    

    var body: some View {
        NavigationLink(destination: WorkoutPickerListView(workoutName: $workoutName)){
            if workoutName != "" {
                Text(workoutName)
            }
            else {
                Text("Choose a workout")
                    .italic()
                    .foregroundColor(.gray)
            }
        }
    }
}

struct WorkoutPicker_Previews: PreviewProvider {
    
    @State static var workoutName: String = ""
    
    static var previews: some View {
        WorkoutPicker(workoutName: $workoutName)
    }
}
