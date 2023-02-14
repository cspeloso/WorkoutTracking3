//
//  NewListSets.swift
//  WorkoutTracking3
//
//  Created by Chris Peloso on 4/3/22.
//

import SwiftUI

struct NewListSets: View {
    
    @Binding var sets: [Workout.Set]
    
    var body: some View {
        if sets.count == 0 {
            Text("No sets recorded.")
        }
        else {
            List {
                ForEach(sets) { s in
                    HStack {
                        Text("\(s.reps) reps")
                            .padding(.horizontal, 10)
                        Spacer()
                        Text("\(s.weight.formatted()) lbs")
                    }
                }
                .onDelete(perform: deleteSet)
            }
        }
    }
    
    
    func deleteSet(at offsets: IndexSet){
        sets.remove(atOffsets: offsets)
    }
}

struct NewListSets_Previews: PreviewProvider {
    
    @State static var sets: [Workout.Set] = [Workout.Set(reps: 10, weight: 10)]
    
    static var previews: some View {
        NewListSets(sets: $sets)
    }
}
