//
//  AddWorkoutView.swift
//  WorkoutTracking3
//
//  Created by Chris Peloso on 3/9/22.
//

import SwiftUI

struct AddWorkoutView: View {
    
    @Binding var workouts: [Workout]
    @Binding var createdWorkoutIndex: Int?
    
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    @State private var searchText = ""
    @State private var customExerciseName = ""
    
    private let exercises: [Exercise] = Bundle.main.decode("exercises.json")
    
    private var filteredExercises: [Exercise] {
        guard !searchText.isEmpty else {
            return exercises.sorted { $0.name < $1.name }
        }
        
        return exercises
            .filter { $0.name.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.name < $1.name }
    }
    
    var body: some View {
        Form {
            Section {
                HStack {
                    TextField("Exercise name", text: $customExerciseName)
                        .onChange(of: customExerciseName) { newValue in
                            if newValue.count > 50 {
                                customExerciseName = String(newValue.prefix(50))
                            }
                        }
                        .onSubmit {
                            createWorkout(named: customExerciseName)
                        }
                    
                    Button("Add") {
                        createWorkout(named: customExerciseName)
                    }
                    .disabled(customExerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } header: {
                Text("Custom Exercise")
            } footer: {
                Text("After choosing an exercise, you will go straight to logging sets.")
            }
            
            Section {
                ForEach(filteredExercises) { exercise in
                    Button {
                        createWorkout(named: exercise.name)
                    } label: {
                        HStack {
                            Text(exercise.name)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Color(red: 221/255, green: 69/255, blue: 36/255))
                        }
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Exercises")
            }
        }
        .searchable(text: $searchText, prompt: "Search exercises")
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
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
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
