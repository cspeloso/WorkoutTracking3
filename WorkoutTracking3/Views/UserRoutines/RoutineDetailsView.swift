//
//  RoutineDetailsView.swift
//  WorkoutTracking3
//
//  Created by Chris Peloso on 3/9/22.
//

import SwiftUI

struct RoutineDetailsView: View {
    
    @Binding var routine: Routine
    @State private var createdWorkoutIndex: Int?
    @State private var selectedWorkoutIndex: Int?
    @State private var shouldShowAddWorkout = false
    @State private var shouldOpenCreatedWorkout = false
    
    private let routineWeekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday", ""]
    
    var body: some View {
        ZStack {
            Form {
                
                //  Routine name
                Section {
                    TextField("Routine Name", text: $routine.name)
                } header: {
                    Text("Routine Name")
                }
                
                Section {
                    Picker("Weekday", selection: $routine.weekday) {
                        ForEach(routineWeekdays, id: \.self) { weekday in
                            if weekday.isEmpty {
                                Text("No day").tag(weekday)
                            } else {
                                Text(weekday).tag(weekday)
                            }
                        }
                    }
                } header: {
                    Text("Weekday")
                } footer: {
                    Text("This controls where the routine appears in your weekly list.")
                }
                
                //  Workouts List
                Section {
                    if routine.workouts.count == 0 {
                        Button {
                            shouldShowAddWorkout = true
                        } label: {
                            EmptyWorkoutsCTA()
                        }
                        .buttonStyle(.plain)
                    }
                    else {
                        ForEach($routine.workouts) { $workout in
                            NavigationLink(destination: WorkoutDetailsView(workout: $workout)){
                                Text(workout.name)
                            }
                        }
                        .onDelete(perform: deleteWorkout)
                        .onMove(perform: moveWorkout)
                    }
                } header: {
                    Text("Workouts")
                }
            }
            
            NavigationLink(
                destination: AddWorkoutView(
                    workouts: $routine.workouts,
                    createdWorkoutIndex: $createdWorkoutIndex
                ),
                isActive: $shouldShowAddWorkout
            ) {
                EmptyView()
            }
            .hidden()
            
            NavigationLink(
                destination: selectedWorkoutDestination(),
                isActive: $shouldOpenCreatedWorkout
            ) {
                EmptyView()
            }
            .hidden()
        }
        .navigationTitle(routine.name != "" ? routine.name : routine.weekday)
        .toolbar {
            Button {
                shouldShowAddWorkout = true
            } label: {
                Text("Add Workout")
            }
        }
        .onChange(of: createdWorkoutIndex) { newIndex in
            guard let newIndex else {
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                guard routine.workouts.indices.contains(newIndex) else {
                    createdWorkoutIndex = nil
                    return
                }
                
                selectedWorkoutIndex = newIndex
                shouldOpenCreatedWorkout = true
                createdWorkoutIndex = nil
            }
        }
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
    
    func deleteWorkout(at offsets: IndexSet){
        routine.workouts.remove(atOffsets: offsets)
    }
    func moveWorkout(from source: IndexSet, to destination: Int){
        routine.workouts.move(fromOffsets: source, toOffset: destination)
    }
}

private struct EmptyWorkoutsCTA: View {
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Add your first workout")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Choose an exercise, then start logging sets right away.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Label("Add Workout", systemImage: "plus.circle.fill")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundColor(.white)
                .background(Color(red: 221/255, green: 69/255, blue: 36/255))
                .cornerRadius(8)
        }
        .padding(.vertical, 8)
    }
}

struct RoutineDetailsView_Previews: PreviewProvider {
    
    @State static var routine = Routine(name: "", weekday: "asjdfk", workouts: [Workout(name: "asdf", sets: [Workout.Set(reps: 10, weight: 55)], loggedSets: [])])
    
    static var previews: some View {
        RoutineDetailsView(routine: $routine)
    }
}
