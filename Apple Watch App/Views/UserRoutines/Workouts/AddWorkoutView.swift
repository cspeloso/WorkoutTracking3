//
//  AddWorkoutView.swift
//  Work It Out Apple Watch Watch App
//
//  Created by Chris Peloso on 1/12/24.
//

import SwiftUI
import WatchKit

struct AddWorkoutView: View {
    
    @Binding var workouts: [Workout]
    @Binding var createdWorkoutIndex: Int?
    
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    @State private var customExerciseName = ""
    
    private let exercises: [Exercise] = Bundle.main.decode("exercises.json")

    
    var body: some View {
        Form {
            Section {
                TextField("Exercise name", text: $customExerciseName)
                    .onChange(of: customExerciseName) { _, newValue in
                        if newValue.count > 50 {
                            customExerciseName = String(newValue.prefix(50))
                        }
                    }
                    .onSubmit {
                        createWorkout(named: customExerciseName)
                    }
                
                Button {
                    createWorkout(named: customExerciseName)
                } label: {
                    Label("Add Custom", systemImage: "plus.circle.fill")
                }
                .disabled(customExerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } header: {
                Text("Custom Exercise")
            } footer: {
                Text("Pick an exercise, then log sets on the next screen.")
            }
            
            Section {
                ForEach(exercises.sorted(by: { $0.name < $1.name })) { exercise in
                    Button {
                        createWorkout(named: exercise.name)
                    } label: {
                        HStack {
                            Text(exercise.name)
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Color(red: 221/255, green: 69/255, blue: 36/255))
                        }
                    }
                    .foregroundColor(.primary)
                }
            } header: {
                Text("Exercises")
            }
        }
        .navigationBarTitle("Add workout")
    }
    
    private func createWorkout(named rawName: String) {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            return
        }
        
        let newIndex = workouts.count
        workouts.append(Workout(name: name, sets: [], loggedSets: []))
        createdWorkoutIndex = newIndex
        
        WKInterfaceDevice.current().play(.click)
        mode.wrappedValue.dismiss()
    }
}

struct AddWorkoutView_Previews: PreviewProvider {
    
    @State static var workouts: [Workout] = []
    @State static var createdWorkoutIndex: Int?
    
    static var previews: some View {
        AddWorkoutView(workouts: $workouts, createdWorkoutIndex: $createdWorkoutIndex)
    }
}
