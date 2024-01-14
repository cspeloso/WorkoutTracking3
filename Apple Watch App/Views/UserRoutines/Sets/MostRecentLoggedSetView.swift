//
//  MostRecentLoggedSetView.swift
//  Work It Out Apple Watch Watch App
//
//  Created by Chris Peloso on 1/12/24.
//

import SwiftUI

struct MostRecentLoggedSetView: View {
    
    var mostRecentLoggedSet: Workout.LoggedSet
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Last Logged Set, " + mostRecentLoggedSet.getLoggedDateStr())
                .font(.headline)
            
            ForEach(mostRecentLoggedSet.sets) { set in
                Text("Reps: \(set.reps.formatted()), Weight: \(set.weight.formatted())")
            }
        }
        .padding()
        .cornerRadius(10)
        .multilineTextAlignment(.leading)
    }
}

//struct WorkoutDetailsView_Previews: PreviewProvider {
//
//    @State static var loggedSet = Workout.LoggedSet(sets: [Workout.Set(reps: 5, weight: 10)], loggedOnDate: Date())
//
//    static var previews: some View {
//        MostRecentLoggedSetView(mostRecentLoggedSet: loggedSet)
//    }
//}
