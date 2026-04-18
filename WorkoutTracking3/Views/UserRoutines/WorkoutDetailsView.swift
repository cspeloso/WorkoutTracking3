//
//  WorkoutDetailsView.swift
//  WorkoutTracking3
//
//  Created by Chris Peloso on 3/9/22.
//

import SwiftUI

struct WorkoutDetailsView: View {

    @EnvironmentObject private var userData: UserData
    @Binding var workout: Workout
    @State private var showAlert = false
    @State private var navigateToHistory = false
    @State private var visibleSets: [Workout.Set] = []
    @State private var haptic = UIImpactFeedbackGenerator(style: .heavy)
    @State private var selectedProgressRange: ProgressRange = .all

    private var suggestedSet: Workout.Set {
        if let currentSet = visibleSets.last {
            return currentSet
        }

        if let currentSet = workout.sets.last {
            return currentSet
        }
        
        if let recentSet = mostRecentMatchingLoggedSet?.sets.last {
            return recentSet
        }
        
        return Workout.Set(reps: 10, weight: 0)
    }

    private var matchingLoggedSets: [Workout.LoggedSet] {
        let normalizedWorkoutName = workout.name.normalizedExerciseName
        var loggedSets = userData.routines
            .flatMap(\.workouts)
            .filter { $0.id != workout.id && $0.name.normalizedExerciseName == normalizedWorkoutName }
            .flatMap(\.loggedSets)

        loggedSets.append(contentsOf: workout.loggedSets)
        return loggedSets.sorted { $0.loggedOnDate > $1.loggedOnDate }
    }

    private var mostRecentMatchingLoggedSet: Workout.LoggedSet? {
        matchingLoggedSets.first
    }

    private var workoutProgressPoints: [ProgressPoint] {
        ProgressDataBuilder.points(
            forWorkoutName: workout.name,
            in: userData.routines,
            metric: .maxWeight,
            range: selectedProgressRange,
            includeActiveSets: false,
            currentWorkout: workout
        )
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.name)
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text("\(visibleSets.count) set\(visibleSets.count == 1 ? "" : "s") logged")
                            .font(.title3.weight(.black))
                            .foregroundColor(AppColors.success)
                    }
                    .padding(.top, 18)

                    NewSetCreator2(
                        sets: $workout.sets,
                        initialReps: suggestedSet.reps,
                        initialWeight: suggestedSet.weight,
                        onAddSet: addSet
                    )

                    VStack(alignment: .leading, spacing: 14) {
                        SectionTitle("Logged Sets")

                        if visibleSets.isEmpty {
                            Text("No sets logged yet.")
                                .font(.headline.weight(.bold))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(18)
                                .background(AppColors.card)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border))
                                .cornerRadius(8)
                        } else {
                            ForEach(Array(visibleSets.enumerated()), id: \.element.id) { index, set in
                                LoggedSetRow(index: index + 1, loggedSet: set, weightUnit: userData.weightUnit) {
                                    deleteSet(at: IndexSet(integer: index))
                                }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            deleteSet(at: IndexSet(integer: index))
                                        } label: {
                                            Label("Delete Set", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }

                    WorkoutSummaryBar(sets: visibleSets, weightUnit: userData.weightUnit)

                    VStack(alignment: .leading, spacing: 14) {
                        SectionTitle("Weight Progress")
                        ProgressRangeControls(selectedRange: $selectedProgressRange)
                        ProgressLineChart(
                            points: workoutProgressPoints,
                            metric: .maxWeight,
                            emptyText: "Complete workout logs to see weight progress over time."
                        )
                    }

                    Button {
                        logCurrentSet()
                        haptic.impactOccurred()
                        haptic.prepare()
                    } label: {
                        Label("Complete Log", systemImage: "checkmark.circle.fill")
                            .font(.headline.weight(.black))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .foregroundColor(.white)
                            .background(AppColors.success)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    Button {
                        navigateToHistory = true
                    } label: {
                        Label("History", systemImage: "clock.fill")
                            .font(.headline.weight(.black))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.card)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .background(
                        NavigationLink(
                            destination: LoggedSetsView(workout: $workout),
                            isActive: $navigateToHistory
                        ) { EmptyView() }
                        .hidden()
                    )

                    if let mostRecentLoggedSet = mostRecentMatchingLoggedSet {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionTitle("Most Recent")
                            MostRecentLoggedSetView(mostRecentLoggedSet: mostRecentLoggedSet)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(18)
                                .background(AppColors.card)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Error"),
                message: Text("Cannot log an empty set."),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            visibleSets = workout.sets
            haptic.prepare()
        }
        .onChange(of: workout.sets) { newSets in
            if visibleSets != newSets {
                visibleSets = newSets
            }
        }
    }

    private func deleteSet(at offsets: IndexSet) {
        let updatedSets = visibleSets.enumerated()
            .filter { !offsets.contains($0.offset) }
            .map(\.element)
        visibleSets = updatedSets
        workout.sets = updatedSets
    }

    // Ensure UI-driving mutations happen on the main actor
    @MainActor
    private func addSet(_ set: Workout.Set) {
        let updatedSets = visibleSets + [set]
        visibleSets = updatedSets
        workout.sets = updatedSets
    }

    @MainActor
    private func logCurrentSet() {
        guard !visibleSets.isEmpty else {
            showAlert = true
            return
        }

        workout.startDate = Date()
        let newLoggedSet = Workout.LoggedSet(sets: visibleSets, loggedOnDate: workout.startDate)
        workout.loggedSets = workout.loggedSets + [newLoggedSet]
        workout.sets = []
        visibleSets = []
    }
}

private struct LoggedSetRow: View {
    let index: Int
    let loggedSet: Workout.Set
    let weightUnit: WeightUnit
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text("\(index)")
                .font(.headline.weight(.black))
                .foregroundColor(.secondary)
                .frame(width: 42, height: 42)
                .background(AppColors.elevated)
                .cornerRadius(8)

            Text(weightUnit.formattedWeight(fromStoredPounds: loggedSet.weight))
                .font(.title3.weight(.black))

            Text("× \(loggedSet.reps) reps")
                .font(.headline.weight(.bold))
                .foregroundColor(.secondary)

            Spacer()

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash.fill")
                    .font(.headline.weight(.bold))
                    .foregroundColor(AppColors.accent)
                    .frame(width: 36, height: 36)
                    .background(AppColors.elevated)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete set \(index)")
        }
        .padding(16)
        .background(AppColors.card)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border))
        .cornerRadius(8)
    }
}

private struct WorkoutSummaryBar: View {
    let sets: [Workout.Set]
    let weightUnit: WeightUnit

    private var estimatedOneRepMax: Double {
        sets.map { $0.weight * (1 + Double($0.reps) / 30) }.max() ?? 0
    }

    private var maxWeight: Double {
        sets.map(\.weight).max() ?? 0
    }

    private var maxReps: Int {
        sets.map(\.reps).max() ?? 0
    }

    var body: some View {
        HStack(spacing: 0) {
            SummaryMetric(value: weightUnit.formattedWeight(fromStoredPounds: estimatedOneRepMax), label: "Est. 1RM")
            Divider().background(AppColors.border)
            SummaryMetric(value: weightUnit.formattedWeight(fromStoredPounds: maxWeight), label: "Max Weight")
            Divider().background(AppColors.border)
            SummaryMetric(value: "\(maxReps)", label: "Max Reps")
        }
        .frame(height: 92)
        .background(AppColors.card)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border))
        .cornerRadius(8)
    }
}
