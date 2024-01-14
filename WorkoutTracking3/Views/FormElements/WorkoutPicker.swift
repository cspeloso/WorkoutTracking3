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
//    let userCreatedExercises: [Exercise] = Bundle.main.decode("userCreatedExercises.json")
    let userCreatedExercises: [Exercise] = [];
    
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>

    var body: some View {
        Form{
            //  user created workout name
            Section {
                HStack{
                    TextField("Exercise Name", text: $workoutName)
                        .onChange(of: workoutName) { newValue in
                            if(newValue.count > 50){
                                workoutName = String(newValue.prefix(50))
                            }
                        }
                        .onSubmit {
                            self.mode.wrappedValue.dismiss()
                        }
                    Button("Save Exercise") {
                        self.mode.wrappedValue.dismiss();
                    }
                }
            } header: {
                Text("Enter An Exercise Name")
            }
            
            //  list of pre-created workouts
            Section{
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
            } header: {
                Text("Or Select A Pre-Created Exercise")
            }
        }
        .navigationBarTitle("Select a workout")

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
