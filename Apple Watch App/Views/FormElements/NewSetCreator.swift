//
//  NewSetCreator.swift
//  Work It Out Apple Watch Watch App
//
//  Created by Chris Peloso on 1/12/24.
//

import SwiftUI

struct NewSetCreator: View {
    
    @Binding var sets: [Workout.Set]
    
    @State private var reps = 0
    @State private var weight = 0.0
    
    @FocusState var isWeightInputActive: Bool
    
    let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    
    var body: some View {
                    
        //  reps
        Picker("Reps", selection: $reps){
            ForEach(0..<51){
                Text("\($0) reps")
            }
        }
        .pickerStyle(.wheel)
        .frame(height: 90)
        
        //  weight
        HStack {
            Text("Weight")
                .font(.headline)
            
            Spacer()
            
            TextField("Weight", value: $weight, formatter: decimalFormatter)
                .focused($isWeightInputActive)
                .toolbar {
                    ToolbarItemGroup(placement: .bottomBar){
                        Spacer()
                        Button("Done"){
                            isWeightInputActive = false
                        }
                    }
                }
        }
        
        //  save
        Button("Add"){
            let newSet = Workout.Set(reps: reps, weight: weight)
            sets.append(newSet)
        }
    }
}

//struct NewSetCreator_Previews: PreviewProvider {
//    
//    @State static var sets: [Workout.Set] = [Workout.Set(reps: 10, weight: 55)]
//    
//    static var previews: some View {
//        NewSetCreator(sets: $sets)
//    }
//}
