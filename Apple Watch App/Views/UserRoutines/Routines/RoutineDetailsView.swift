//
//  RoutineDetailsView.swift
//  Work It Out Apple Watch Watch App
//
//  Created by Chris Peloso on 1/12/24.
//

import SwiftUI

struct RoutineDetailsView: View {
    
    @Binding var routine: Routine
    
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
                    Text("No workouts found.")
                }
                else {
                    ForEach($routine.workouts) { $workout in
                        NavigationLink(destination: WorkoutDetailsView(workout: $workout)){
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
            NavigationLink(destination: AddWorkoutView(workouts: $routine.workouts)){
                Text("Add Workout")
            }
        }
    }
    
    func deleteWorkout(at offsets: IndexSet){
        routine.workouts.remove(atOffsets: offsets)
    }
}

struct RoutineDetailsView_Previews: PreviewProvider {
    
    @State static var routine = Routine(name: "", weekday: "asjdfk", workouts: [Workout(name: "asdf", sets: [Workout.Set(reps: 10, weight: 55)], loggedSets: [])])
    
    static var previews: some View {
        RoutineDetailsView(routine: $routine)
    }
}
