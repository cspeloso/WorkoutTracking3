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
                Button(action: {
                    workoutName = exercise.name
                    self.mode.wrappedValue.dismiss()
                }){
                    HStack{
                        Text(exercise.name)
                        Spacer()
                        Image(exercise.formImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width:75, height:30)
                            .cornerRadius(5)
                    }
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
