//
//  WorkoutDetailsView.swift
//  WorkoutTracking3
//
//  Created by Chris Peloso on 3/9/22.
//

import SwiftUI

struct WorkoutDetailsView: View {
    
    @Binding var workout: Workout
    
    let exercises: [Exercise] = Bundle.main.decode("exercises.json")


    var body: some View {
        VStack {
            Form {
                
//                //  Workout name
//                Section {
// //                    WorkoutPicker(workoutName: $workout.name)
//                    Text(workout.name)
//
//                } header: {
//                    Text("Workout")
//                }
//
                //  Muscle Groups Image
                Section {
                    Image(exercises.filter{$0.name == workout.name}.first?.formImage ?? "")
                        .resizable()
                        .scaledToFit()
                }
                
                //  add a new set
                Section {
//                    NewSetCreator(sets: $workout.sets)
                    NewSetCreator2(sets: $workout.sets)
                } header: {
                    Text("Add new sets")
                }
                
                //  sets list
                Section {
                    NewListSets(sets: $workout.sets)
                } header: {
                    Text("Today's Log")
                }
                
                
                //  New Log
                Section{
                    ZStack {
                        NavigationLink(""){
                            //
                        }
                        .opacity(0)
                        .disabled(true)
                        
                        Button("aaa"){
                            logCurrentSet()
                        }
                        .opacity(0)
                        
                        Text("**New Log**")
                            .padding(.vertical, 10)
                            .foregroundColor(.primary)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color(red: 255/255, green: 95/255, blue: 95/255), lineWidth: 3)
                )
                .listRowBackground(Color(UIColor.systemGroupedBackground))
                
                
//                  History
                Section {
                    ZStack{
                        NavigationLink(destination: LoggedSetsView(workout: $workout)){

                        }
                        .opacity(0)

                        Text("**History**")
                            .padding(.vertical, 10)
                            .foregroundColor(.primary)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color(red: 255/255, green: 95/255, blue: 95/255), lineWidth: 3)
                )
                .listRowBackground(Color(UIColor.systemGroupedBackground))
                
                
                
            }
        }
        .navigationBarTitle(workout.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    
    func logCurrentSet() {
        let newLoggedSet: Workout.LoggedSet = Workout.LoggedSet(sets: workout.sets, loggedOnDate: Date())
        workout.loggedSets.append(newLoggedSet)
        workout.sets = []
    }
}

struct WorkoutDetailsView_Previews: PreviewProvider {
    
    @State static var workout: Workout = Workout(name: "test", sets: [], loggedSets: [])
    
    static var previews: some View {
        WorkoutDetailsView(workout: $workout)
    }
}
