//
//  NewSetCreator2.swift
//  Work It Out Apple Watch Watch App
//
//  Created by Chris Peloso on 1/12/24.
//

import SwiftUI

struct NewSetCreator2: View {
    
    @Binding var sets: [Workout.Set]
    
    @State private var weight: Double = 0.0
    @State private var reps: Int = 0
    
    @FocusState var isWeightInputActive: Bool
    
    let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    var body: some View {
        VStack {
            
            //  top labels
            HStack {
                Text("Weight")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 15)
                Spacer()
                Text("Reps")
                    .frame(maxWidth:.infinity, alignment: .center)
                    .padding(.top, 15)
            }
            
            //  middle text entry
            HStack {
                TextField("Weight", value: $weight, formatter: decimalFormatter)
//                    .keyboardType(.decimalPad)
                    .focused($isWeightInputActive)
                    .frame(height:75)
                    .background(Color(red: 227/255, green: 227/255, blue: 227/255))
                    .cornerRadius(10)
                    .multilineTextAlignment(.center)
                    .font(
                            Font
                                .system(size: 30)
                                .bold()
                    )
                    .toolbar {
                        ToolbarItemGroup(placement: .bottomBar) {
                            Spacer()
                            Button("Done"){
                                isWeightInputActive = false
                            }
                        }
                    }
                
                Spacer()
                
                TextField("Reps", value: $reps, formatter: decimalFormatter)
//                    .keyboardType(.numberPad)
                    .focused($isWeightInputActive)
                    .frame(height: 75)
                    .background(Color(red: 227/255, green: 227/255, blue: 227/255))
                    .cornerRadius(10)
                    .multilineTextAlignment(.center)
                    .font(
                            Font
                                .system(size: 30)
                                .bold()
                    )
                
            }
        }
        
        //  bottom add set button
        Button("Add Set"){
            let newSet = Workout.Set(reps: reps, weight: weight)
            sets.append(newSet)
            
            let haptic = WKInterfaceDevice.current().play(.success)
        }
        .frame(maxWidth: .infinity)
        .font(
            Font
                .system(size: 16)
                .bold()
        )
        .background(Color(red: 221/255, green: 69/255, blue: 36/255))
        .foregroundColor(.white)
    }
}

//struct NewSetCreator2_Previews: PreviewProvider {
//
//    @State static var sets: [Workout.Set] = [Workout.Set(reps: 3, weight: 10)]
//
//    static var previews: some View {
//        NewSetCreator2(sets: $sets)
//    }
//}
