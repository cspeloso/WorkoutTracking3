//
//  AddRoutine.swift
//  WorkoutTracking3
//
//  Created by Chris Peloso on 3/9/22.
//

import SwiftUI

struct AddRoutine: View {
    
    @Binding var routines: [Routine]
    
    
    @State private var routineName: String = ""
    
    @State private var selectedWeekday: String = ""
    
    let weekdays = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday", ""]
    
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            Form {
                Section {
                    TextField("Routine Name", text: $routineName)
                } header: {
                    Text("Routine name")
                } footer: {
                    Text("Give this routine a name like Push Day, Legs, or Full Body.")
                }
                
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
                    Button {
                        createRoutine()
                    } label: {
                        Text("Create Routine")
                            .font(.headline.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .disabled(routineName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedWeekday.isEmpty)
                }
            }
            .hideScrollContentBackgroundIfAvailable()
        }
        .navigationBarTitle("New Routine")
    }

    private func createRoutine() {
        let trimmedName = routineName.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackName = selectedWeekday.isEmpty ? "New Routine" : "\(selectedWeekday) Routine"
        let newRoutine = Routine(name: trimmedName.isEmpty ? fallbackName : trimmedName, weekday: selectedWeekday, workouts: [])
        routines.append(newRoutine)
        mode.wrappedValue.dismiss()
    }
}

struct AddRoutine_Previews: PreviewProvider {
    
    @State static var routines: [Routine] = []
    
    static var previews: some View {
        AddRoutine(routines: $routines)
    }
}
