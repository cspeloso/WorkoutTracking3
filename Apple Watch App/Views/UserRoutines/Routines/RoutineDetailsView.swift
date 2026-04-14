//
//  RoutineDetailsView.swift
//  Work It Out Apple Watch Watch App
//
//  Created by Chris Peloso on 1/12/24.
//

import SwiftUI

struct RoutineDetailsView: View {
    
    @Binding var routine: Routine
    @State private var createdWorkoutIndex: Int?
    @State private var selectedWorkoutIndex: Int?
    @State private var shouldShowAddWorkout = false
    @State private var shouldOpenCreatedWorkout = false
    
    var body: some View {
        Form {
            
            //  Routine name
            Section {
                TextField("Routine Name", text: $routine.name)
            } header: {
                Text("Routine Name")
            }
            
            //  Workouts List
            Section {
                if routine.workouts.count == 0 {
                    Button {
                        shouldShowAddWorkout = true
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Add your first workout", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Choose an exercise, then start logging sets.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                } else {
                    ForEach($routine.workouts) { $workout in
                        NavigationLink(destination: WorkoutDetailsView(workout: $workout)) {
                            Text(workout.name)
                        }
                    }
                    .onDelete(perform: deleteWorkout)
                }
            } header: {
                Text("Workouts")
            }
        }
        .navigationTitle(routine.name != "" ? routine.name : routine.weekday)
        .toolbar {
            Button {
                shouldShowAddWorkout = true
            } label: {
                Text("Add Workout")
            }
        }
        .navigationDestination(isPresented: $shouldShowAddWorkout) {
            AddWorkoutView(
                workouts: $routine.workouts,
                createdWorkoutIndex: $createdWorkoutIndex
            )
        }
        .navigationDestination(isPresented: $shouldOpenCreatedWorkout) {
            selectedWorkoutDestination()
        }
        .onChange(of: createdWorkoutIndex) { _, newIndex in
            guard let newIndex else {
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                selectedWorkoutIndex = newIndex
                shouldOpenCreatedWorkout = true
                createdWorkoutIndex = nil
            }
        }
    }
    
    func deleteWorkout(at offsets: IndexSet) {
        routine.workouts.remove(atOffsets: offsets)
    }
    
    @ViewBuilder
    private func selectedWorkoutDestination() -> some View {
        if let selectedWorkoutIndex,
           routine.workouts.indices.contains(selectedWorkoutIndex) {
            WorkoutDetailsView(workout: $routine.workouts[selectedWorkoutIndex])
        } else {
            EmptyView()
        }
    }
}

struct RoutineDetailsView_Previews: PreviewProvider {
    
    @State static var routine = Routine(name: "", weekday: "asjdfk", workouts: [Workout(name: "asdf", sets: [Workout.Set(reps: 10, weight: 55)], loggedSets: [])])
    
    static var previews: some View {
        RoutineDetailsView(routine: $routine)
    }
}
