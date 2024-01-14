//
//  ListSets.swift
//  Work It Out Apple Watch Watch App
//
//  Created by Chris Peloso on 1/12/24.
//

import SwiftUI

struct ListSets: View {
    
    @Binding var sets: [Workout.Set]
    
    var body: some View {
        if sets.count == 0 {
            Text("No sets found.")
        }
        else {
            List {
                ForEach(sets) { s in
                    Text("\(s.reps) reps @ \(s.weight.formatted()) lbs")
                }
                .onDelete(perform: deleteSet)
            }
        }
    }
    
    func deleteSet(at offsets: IndexSet){
        sets.remove(atOffsets: offsets)
    }
}

struct ListSets_Previews: PreviewProvider {
    
    @State static var sets: [Workout.Set] = []
    
    static var previews: some View {
        ListSets(sets: $sets)
    }
}
