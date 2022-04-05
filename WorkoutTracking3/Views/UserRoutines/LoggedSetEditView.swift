//
//  LoggedSetEditView.swift
//  WorkoutTracking3
//
//  Created by Chris Peloso on 3/18/22.
//

import SwiftUI

struct LoggedSetEditView: View {
    
    @Binding var loggedSet: Workout.LoggedSet
    
//    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section {
                Text("Change Logged Set Date")
                    .font(.headline)
                
                DatePicker("Logged Set Date", selection: $loggedSet.loggedOnDate, displayedComponents: [.date])
                    .datePickerStyle(.graphical)
//                    .onChange(of: loggedSet.loggedOnDate) {_ in
//                        dismiss()
//                    }
            }
            
            Section {
                ForEach(loggedSet.sets) { s in
                    Text("\(s.reps) reps @ \(s.weight.formatted()) lbs")
                }
            }
        }
    }
}

struct LoggedSetEditView_Previews: PreviewProvider {
    
    @State static var loggedSet: Workout.LoggedSet = Workout.LoggedSet(sets: [], loggedOnDate: Date())
    
    static var previews: some View {
        LoggedSetEditView(loggedSet: $loggedSet)
    }
}
