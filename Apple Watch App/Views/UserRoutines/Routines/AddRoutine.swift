//
//  AddRoutine.swift
//  WorkoutTracking3
//
//  Created by Chris Peloso on 1/12/24.
//

import SwiftUI

struct AddRoutine: View {
    
    @Binding var routines: [Routine]
    
    
    @State private var routineName: String = ""
    
    @State private var selectedWeekday: String = ""
    
    let weekdays = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday", ""]
    
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    
    var body: some View {
        Form {
            
            //  Name
            Section {
                TextField("Routine Name", text: $routineName)
            } header: {
                Text("Routine name")
            }
            
            //  Weekday
            Section {
                Picker("Weekday", selection: $selectedWeekday){
                    ForEach(weekdays, id: \.self){
                        if $0 == ""{
                            Text("No day")
                        }
                        else {
                            Text($0)
                        }
                    }
                }
                .pickerStyle(.wheel)
            } header: {
                Text("Weekday")
            }
            
            Section {
                Button("Create new routine"){
                    let newRoutine = Routine(name: routineName, weekday: selectedWeekday, workouts: [])
                    
                    routines.append(newRoutine)
                    
                    self.mode.wrappedValue.dismiss()
                }
            }
        }
        .navigationBarTitle("New Routine")
    }
}

struct AddRoutine_Previews: PreviewProvider {
    
    @State static var routines: [Routine] = []
    
    static var previews: some View {
        AddRoutine(routines: $routines)
    }
}
