//
//  LoggedSetsView.swift
//  WorkoutTracking3
//
//  Created by Chris Peloso on 3/17/22.
//

import SwiftUI

struct LoggedSetsView: View {
    
    @Binding var workout: Workout
    
    var body: some View {
        
        Form {
            
            //  Current Sets Section
            Section {
                
                //  if user has no sets recorded
                if workout.sets.count == 0 {
                    Text("No current sets.")
                        .italic()
                }
                
                //  if user has sets recorded...
                else {
                    List {
                        ForEach(workout.sets) { s in
                            Text("\(s.reps) reps @ \(s.weight.formatted()) lbs")
                        }
                    }
                }
            } header: {
                Text("Current Sets")
                    .font(.subheadline)
            }
            
            
            
            //  Logged Sets Section
            Section {
                if workout.loggedSets.count == 0 {
                    Text("No logged sets")
                }
            } header: {
                HStack {
                    Text("Logged sets")
                        .font(.subheadline)
//                    Spacer()
//                    Button("Log Current Sets") {
//                        logCurrentSet()
//                    }
                }
            }
            
            List {
                
                ForEach($workout.loggedSets.sorted(by: {$0.loggedOnDate.wrappedValue < $1.loggedOnDate.wrappedValue})) { $ls in
                    Section {
                        VStack(alignment: .leading){
                            NavigationLink(destination: LoggedSetEditView(loggedSet: $ls)){
                                Text("**Logged on \(formatDate(date: ls.loggedOnDate))**")
                            }
                            ForEach(ls.sets) { s in
                                Text("\(s.reps) reps @ \(s.weight.formatted()) lbs")
                            }
                        }
                    }
                }
//                .onDelete(perform: deleteLoggedSet)
                .onDelete{ indexSet in
                    
                    // Sort and store the loggedSets in a temporary variable
                    let sortedLoggedSets = workout.loggedSets.sorted(by: { $0.loggedOnDate < $1.loggedOnDate })
                    
                    // Map the indexSet to the indices in the original array
                    let originalIndices = indexSet.compactMap { index -> Int? in
                        let element = sortedLoggedSets[index]
                        return workout.loggedSets.firstIndex(where: { $0.id == element.id })
                    }
                    
                    // Call the delete function with the correct indices
                    deleteLoggedSet(at: originalIndices)
                    
                }
                
            }
            
        }
    }
    
//    func deleteLoggedSet(at offsets: IndexSet) {
//        workout.loggedSets.remove(atOffsets: offsets)
//    }
    // In your deleteLoggedSet function, ensure you're deleting from the original data array
    func deleteLoggedSet(at indices: [IndexSet.Element]) {
        for index in indices {
            // Find the item in the original array and delete it
            // This is just a placeholder logic; implement based on your actual data structure
            if let originalIndex = workout.loggedSets.firstIndex(where: { $0.id == workout.loggedSets.sorted(by: { $0.loggedOnDate < $1.loggedOnDate })[index].id }) {
                workout.loggedSets.remove(at: originalIndex)
            }
        }
    }
    
    func formatDate(date: Date) -> String{
        let df = DateFormatter()
        df.dateStyle = .short
        return df.string(from: date)
    }
    
    func logCurrentSet() {
        let newLoggedSet: Workout.LoggedSet = Workout.LoggedSet(sets: workout.sets, loggedOnDate: Date())
        workout.loggedSets.append(newLoggedSet)
        workout.sets = []
    }
}

struct LoggedSetsView_Previews: PreviewProvider {
    
//    @State static var loggedSets: [Workout.LoggedSet] = [Workout.LoggedSet(sets: [Workout.Set(reps: 10, weight: 55)], loggedOnDate: Date())]
    @State static var workout: Workout = Workout(name: "Calf Raises", sets: [Workout.Set(reps: 10, weight: 55), Workout.Set(reps: 10, weight: 55)], loggedSets: [Workout.LoggedSet(sets: [Workout.Set(reps: 10, weight: 55)], loggedOnDate: Date())])
    
    static var previews: some View {
        LoggedSetsView(workout: $workout)
    }
}
