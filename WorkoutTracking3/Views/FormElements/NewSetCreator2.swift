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
    
    @EnvironmentObject private var userData: UserData
    @Binding var sets: [Workout.Set]
    var onAddSet: (@MainActor (Workout.Set) -> Void)?
    
    @State private var displayWeight: Double
    @State private var reps: Int
    @State private var haptic = UIImpactFeedbackGenerator(style: .heavy)
    @State private var activeWeightUnit = UserData.shared.weightUnit
    @State private var hasInitializedWeightUnit = false
    private let initialStoredWeight: Double
    
    @FocusState private var focusedField: SetInputField?
    
    private let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    init(
        sets: Binding<[Workout.Set]>,
        initialReps: Int = 10,
        initialWeight: Double = 0.0,
        onAddSet: (@MainActor (Workout.Set) -> Void)? = nil
    ) {
        self._sets = sets
        self._reps = State(initialValue: initialReps)
        self._displayWeight = State(initialValue: initialWeight)
        self.initialStoredWeight = initialWeight
        self.onAddSet = onAddSet
    }
    
    var body: some View {
        VStack(spacing: 26) {
            SetAdjuster(
                title: "Weight (\(userData.weightUnit.abbreviatedTitle))",
                valueText: displayWeight.formatted(),
                focused: focusedField == .weight,
                smallMinus: { displayWeight = max(0, displayWeight - userData.weightUnit.smallStep) },
                largeMinus: { displayWeight = max(0, displayWeight - userData.weightUnit.largeStep) },
                smallPlus: { displayWeight += userData.weightUnit.smallStep },
                largePlus: { displayWeight += userData.weightUnit.largeStep },
                smallMinusTitle: "-\(userData.weightUnit.smallStep.formatted(.number.precision(.fractionLength(0...1))))",
                largeMinusTitle: "-\(userData.weightUnit.largeStep.formatted(.number.precision(.fractionLength(0...1))))",
                smallPlusTitle: "+\(userData.weightUnit.smallStep.formatted(.number.precision(.fractionLength(0...1))))",
                largePlusTitle: "+\(userData.weightUnit.largeStep.formatted(.number.precision(.fractionLength(0...1))))",
                valueField: {
                    TextField("Weight", value: $displayWeight, formatter: decimalFormatter)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .weight)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 34, weight: .black, design: .rounded))
                }
            )

            SetAdjuster(
                title: "Reps",
                valueText: "\(reps)",
                focused: focusedField == .reps,
                smallMinus: { reps = max(0, reps - 1) },
                largeMinus: { reps = max(0, reps - 5) },
                smallPlus: { reps += 1 },
                largePlus: { reps += 5 },
                smallMinusTitle: "-1",
                largeMinusTitle: "-5",
                smallPlusTitle: "+1",
                largePlusTitle: "+5",
                valueField: {
                    TextField(
                        "Reps",
                        value: Binding(
                            get: { Double(reps) },
                            set: { reps = max(0, Int($0.rounded())) }
                        ),
                        formatter: decimalFormatter
                    )
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .reps)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                }
            )
            
            Button {
                addSet()
            } label: {
                Label("Add Set", systemImage: "checkmark.circle.fill")
                    .font(.headline.weight(.black))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(AppColors.success)
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
        .padding(22)
        .background(AppColors.card)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border))
        .cornerRadius(8)
        .onAppear {
            if !hasInitializedWeightUnit {
                activeWeightUnit = userData.weightUnit
                displayWeight = userData.weightUnit.displayWeight(fromStoredPounds: initialStoredWeight)
                hasInitializedWeightUnit = true
            }
            haptic.prepare()
        }
        .onChange(of: userData.weightUnit) { newUnit in
            let storedWeight = activeWeightUnit.storedPounds(fromDisplayWeight: displayWeight)
            displayWeight = newUnit.displayWeight(fromStoredPounds: storedWeight)
            activeWeightUnit = newUnit
        }
    }
    
    @MainActor
    private func addSet() {
        let newSet = Workout.Set(reps: reps, weight: userData.weightUnit.storedPounds(fromDisplayWeight: displayWeight))
        if let onAddSet {
            onAddSet(newSet)
        } else {
            sets = sets + [newSet]
        }
        focusedField = nil
        
        haptic.impactOccurred()
        haptic.prepare()
    }
}

private struct SetAdjuster<ValueField: View>: View {
    let title: String
    let valueText: String
    let focused: Bool
    let smallMinus: () -> Void
    let largeMinus: () -> Void
    let smallPlus: () -> Void
    let largePlus: () -> Void
    let smallMinusTitle: String
    let largeMinusTitle: String
    let smallPlusTitle: String
    let largePlusTitle: String
    let valueField: () -> ValueField
    
    var body: some View {
        VStack(spacing: 12) {
            Text(title.uppercased())
                .font(.caption.weight(.black))
                .tracking(4)
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                AdjustButton(title: largeMinusTitle, isEmphasized: true, action: largeMinus)
                AdjustButton(title: smallMinusTitle, isEmphasized: false, action: smallMinus)

                valueField()
                    .frame(width: 88, height: 62)
                    .background(AppColors.elevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(focused ? AppColors.accent : AppColors.border, lineWidth: 2)
                    )
                    .cornerRadius(8)

                AdjustButton(title: smallPlusTitle, isEmphasized: false, action: smallPlus)
                AdjustButton(title: largePlusTitle, isEmphasized: true, action: largePlus)
            }
        }
    }
}

private struct AdjustButton: View {
    let title: String
    let isEmphasized: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.black))
                .foregroundColor(isEmphasized ? .white : .primary)
                .frame(maxWidth: .infinity)
                .frame(height: isEmphasized ? 58 : 48)
                .background(isEmphasized ? AppColors.accent : AppColors.elevated)
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
