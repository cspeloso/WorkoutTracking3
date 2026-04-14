//
//  NewSetCreator2.swift
//  Work It Out Apple Watch Watch App
//
//  Created by Chris Peloso on 1/12/24.
//

import SwiftUI
import WatchKit

struct NewSetCreator2: View {
    
    @Binding var sets: [Workout.Set]
    
    @State private var weight: Double = 0.0
    @State private var reps: Int = 0
    
    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 8) {
                SetStepperRow(
                    title: "Weight",
                    valueText: "\(weight.formatted()) lb",
                    decrement: { weight = max(0, weight - 5) },
                    increment: { weight += 5 }
                )
                
                SetStepperRow(
                    title: "Reps",
                    valueText: "\(reps)",
                    decrement: { reps = max(0, reps - 1) },
                    increment: { reps += 1 }
                )
            }
            .padding(10)
            .background(Color.white.opacity(0.08))
            .cornerRadius(8)
            
            HStack(spacing: 8) {
                Button {
                    sets = sets + [Workout.Set(reps: reps, weight: weight)]
                    WKInterfaceDevice.current().play(.success)
                } label: {
                    Text("Add Set")
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                }
                .buttonStyle(.plain)
                .background(Color(red: 221/255, green: 69/255, blue: 36/255))
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Button {
                    weight = 0
                    reps = 0
                    WKInterfaceDevice.current().play(.click)
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.headline)
                        .frame(width: 34, height: 36)
                }
                .buttonStyle(.plain)
                .background(Color.white.opacity(0.12))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct SetStepperRow: View {
    
    let title: String
    let valueText: String
    let decrement: () -> Void
    let increment: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(valueText)
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 6) {
                Button {
                    decrement()
                    WKInterfaceDevice.current().play(.click)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 13, weight: .bold))
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .background(Color.white.opacity(0.13))
                .cornerRadius(8)
                
                Button {
                    increment()
                    WKInterfaceDevice.current().play(.click)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .background(Color.white.opacity(0.13))
                .cornerRadius(8)
            }
        }
        .padding(.vertical, 2)
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
