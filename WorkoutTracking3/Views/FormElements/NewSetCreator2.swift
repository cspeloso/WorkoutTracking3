//
//  NewSetCreator2.swift
//  WorkoutTracking3
//
//  Created by Chris Peloso on 4/12/22.
//

import SwiftUI

private enum SetInputField {
    case weight
    case reps
}

struct NewSetCreator2: View {
    
    @Binding var sets: [Workout.Set]
    
    @State private var weight: Double
    @State private var reps: Int
    
    @FocusState private var focusedField: SetInputField?
    
    private let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    init(sets: Binding<[Workout.Set]>, initialReps: Int = 10, initialWeight: Double = 0.0) {
        self._sets = sets
        self._reps = State(initialValue: initialReps)
        self._weight = State(initialValue: initialWeight)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                SetInputCard(
                    title: "Weight",
                    value: $weight,
                    formatter: decimalFormatter,
                    unit: "lb",
                    keyboardType: .decimalPad,
                    focusedField: $focusedField,
                    field: .weight,
                    decrement: { weight = max(0, weight - 5) },
                    increment: { weight += 5 }
                )
                
                SetInputCard(
                    title: "Reps",
                    value: Binding(
                        get: { Double(reps) },
                        set: { reps = max(0, Int($0.rounded())) }
                    ),
                    formatter: decimalFormatter,
                    unit: "reps",
                    keyboardType: .numberPad,
                    focusedField: $focusedField,
                    field: .reps,
                    decrement: { reps = max(0, reps - 1) },
                    increment: { reps += 1 }
                )
            }
            
            Button {
                addSet()
            } label: {
                Text("Add Set")
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color(red: 221/255, green: 69/255, blue: 36/255))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func addSet() {
        sets.append(Workout.Set(reps: reps, weight: weight))
        focusedField = nil
        
        let haptic = UIImpactFeedbackGenerator(style: .heavy)
        haptic.impactOccurred()
    }
}

private struct SetInputCard: View {
    
    let title: String
    @Binding var value: Double
    let formatter: NumberFormatter
    let unit: String
    let keyboardType: UIKeyboardType
    let focusedField: FocusState<SetInputField?>.Binding
    let field: SetInputField
    let decrement: () -> Void
    let increment: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(unit)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            
            TextField(title, value: $value, formatter: formatter)
                .keyboardType(keyboardType)
                .focused(focusedField, equals: field)
                .multilineTextAlignment(.center)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .frame(height: 70)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(focusedField.wrappedValue == field ? Color(red: 221/255, green: 69/255, blue: 36/255) : Color.clear, lineWidth: 2)
                )
            
            HStack(spacing: 8) {
                StepButton(systemImage: "minus", action: decrement)
                StepButton(systemImage: "plus", action: increment)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

private struct StepButton: View {
    
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(Color(.tertiarySystemGroupedBackground))
                .foregroundColor(.primary)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
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
