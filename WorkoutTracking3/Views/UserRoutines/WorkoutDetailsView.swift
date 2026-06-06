//
//  WorkoutDetailsView.swift
//  WorkoutTracking3
//
//  Created by Chris Peloso on 3/9/22.
//

import SwiftUI
import Combine

struct WorkoutDetailsView: View {

    @EnvironmentObject private var userData: UserData
    @Binding var workout: Workout
    @State private var showAlert = false
    @State private var navigateToHistory = false
    @State private var visibleSets: [Workout.Set] = []
    @State private var haptic = UIImpactFeedbackGenerator(style: .heavy)
    @State private var selectedProgressRange: ProgressRange = .oneMonth
    @State private var cachedMatchingLoggedSets: [Workout.LoggedSet] = []
    @State private var cachedProgressPoints: [ProgressPoint] = []
    @State private var didLogWorkoutStarted = false
    @State private var timerRemainingSeconds = 0
    @State private var isTimerRunning = false
    @State private var timerEndsAt: Date?

    private let restTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var suggestedSet: Workout.Set {
        if let currentSet = visibleSets.last {
            return currentSet
        }

        if let currentSet = workout.sets.last {
            return currentSet
        }
        
        if let recentSet = makeMatchingLoggedSets().first?.sets.first {
            return recentSet
        }
        
        return Workout.Set(reps: 10, weight: 0)
    }

    private var mostRecentMatchingLoggedSet: Workout.LoggedSet? {
        cachedMatchingLoggedSets.first
    }

    private var currentProgressPoint: ProgressPoint? {
        guard let maxWeight = visibleSets.map(\.weight).max(), maxWeight > 0 else {
            return nil
        }

        return ProgressPoint(date: Date(), value: maxWeight)
    }

    private var summarySets: [Workout.Set] {
        if !visibleSets.isEmpty {
            return visibleSets
        }

        return mostRecentMatchingLoggedSet?.sets ?? []
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
                    }
                    .padding(.top, 18)

                    NewSetCreator2(
                        sets: $workout.sets,
                        initialReps: suggestedSet.reps,
                        initialWeight: suggestedSet.weight,
                        onAddSet: addSet
                    )

                    RestTimerCard(
                        interval: Binding(
                            get: { Int(workout.restTimerInterval) },
                            set: { newValue in
                                let clampedValue = max(5, newValue)
                                workout.restTimerInterval = TimeInterval(clampedValue)
                                if !isTimerRunning {
                                    timerRemainingSeconds = clampedValue
                                }
                            }
                        ),
                        autoStartsOnAddSet: $workout.startsRestTimerOnAddSet,
                        remainingSeconds: timerRemainingSeconds,
                        isRunning: isTimerRunning,
                        onStart: { startRestTimer() },
                        onPause: pauseRestTimer,
                        onReset: resetRestTimer
                    )

                    VStack(alignment: .leading, spacing: 14) {
                        SectionTitle("\(visibleSets.count) Logged Set\(visibleSets.count == 1 ? "" : "s")")

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

                    Button {
                        logCurrentSet()
                        haptic.impactOccurred()
                        haptic.prepare()
                    } label: {
                        Label("Log Set", systemImage: "checkmark.circle.fill")
                            .font(.headline.weight(.black))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .foregroundColor(.white)
                            .background(AppColors.success)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .transaction(disableWorkoutLayoutAnimations)

                    Button {
                        AppAnalytics.log(
                            AppAnalytics.Event.historyViewed,
                            parameters: [
                                AppAnalytics.Param.source: "workout_detail",
                                AppAnalytics.Param.loggedSetCount: workout.loggedSets.count
                            ]
                        )
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

                    WorkoutSummaryBar(sets: summarySets, weightUnit: userData.weightUnit)

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

                    VStack(alignment: .leading, spacing: 14) {
                        SectionTitle("Weight Progress")
                        ProgressRangeControls(selectedRange: $selectedProgressRange)
                        ProgressLineChart(
                            points: cachedProgressPoints,
                            metric: .maxWeight,
                            weightUnit: userData.weightUnit,
                            emptyText: "Complete workout logs to see weight progress over time.",
                            selectedRange: selectedProgressRange,
                            currentPoint: currentProgressPoint
                        )
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 32)
                .transaction(disableWorkoutLayoutAnimations)
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
            timerRemainingSeconds = Int(workout.restTimerInterval)
            refreshCachedWorkoutData()
            haptic.prepare()
            logWorkoutStartedIfNeeded()
        }
        .onChange(of: workout.sets) { newSets in
            if visibleSets != newSets {
                visibleSets = newSets
            }
        }
        .onChange(of: workout.loggedSets) { _ in
            refreshCachedWorkoutData()
        }
        .onChange(of: selectedProgressRange) { _ in
            cachedProgressPoints = makeWorkoutProgressPoints()
        }
        .onReceive(restTimer) { _ in
            tickRestTimer()
        }
    }

    private func deleteSet(at offsets: IndexSet) {
        let updatedSets = visibleSets.enumerated()
            .filter { !offsets.contains($0.offset) }
            .map(\.element)
        updateCurrentSets(updatedSets)
    }

    // Ensure UI-driving mutations happen on the main actor
    @MainActor
    private func addSet(_ set: Workout.Set) {
        if visibleSets.isEmpty {
            workout.startDate = Date()
        }
        let updatedSets = visibleSets + [set]
        updateCurrentSets(updatedSets)

        if workout.startsRestTimerOnAddSet {
            startRestTimer(resetToInterval: true)
        }
    }

    @MainActor
    private func logCurrentSet() {
        guard !visibleSets.isEmpty else {
            showAlert = true
            return
        }

        let loggedOnDate = workout.startDate
        let newLoggedSet = Workout.LoggedSet(sets: visibleSets, loggedOnDate: loggedOnDate)
        let transaction = workoutLayoutTransaction

        withTransaction(transaction) {
            workout.loggedSets = workout.loggedSets + [newLoggedSet]
            workout.sets = []
            visibleSets = []
            workout.startDate = Date()
            resetRestTimer()
            refreshCachedWorkoutData()
        }
        AppAnalytics.log(
            AppAnalytics.Event.setLogged,
            parameters: [
                AppAnalytics.Param.setCount: newLoggedSet.sets.count,
                AppAnalytics.Param.loggedSetCount: workout.loggedSets.count
            ]
        )
        AppAnalytics.log(
            AppAnalytics.Event.workoutCompleted,
            parameters: [
                AppAnalytics.Param.setCount: newLoggedSet.sets.count,
                AppAnalytics.Param.loggedSetCount: workout.loggedSets.count
            ]
        )
        AppReviewRequester.recordCompletedWorkoutAndRequestIfAppropriate()
    }

    @MainActor
    private func updateCurrentSets(_ updatedSets: [Workout.Set]) {
        let transaction = workoutLayoutTransaction

        withTransaction(transaction) {
            visibleSets = updatedSets
            workout.sets = updatedSets
        }
    }

    private var workoutLayoutTransaction: Transaction {
        var transaction = Transaction()
        transaction.animation = nil
        transaction.disablesAnimations = true
        return transaction
    }

    private func disableWorkoutLayoutAnimations(_ transaction: inout Transaction) {
        transaction.animation = nil
        transaction.disablesAnimations = true
    }

    private func refreshCachedWorkoutData() {
        cachedMatchingLoggedSets = makeMatchingLoggedSets()
        cachedProgressPoints = makeWorkoutProgressPoints()
    }

    private func startRestTimer(resetToInterval: Bool = false) {
        let interval = max(5, Int(workout.restTimerInterval))
        if resetToInterval || timerRemainingSeconds <= 0 || timerRemainingSeconds > interval {
            timerRemainingSeconds = interval
        }
        timerEndsAt = Date().addingTimeInterval(TimeInterval(timerRemainingSeconds))
        isTimerRunning = true
        updateLiveActivity(isPaused: false)
    }

    private func pauseRestTimer() {
        updateRemainingSecondsFromEndDate()
        timerEndsAt = nil
        isTimerRunning = false
        updateLiveActivity(isPaused: true)
    }

    private func resetRestTimer() {
        isTimerRunning = false
        timerRemainingSeconds = max(5, Int(workout.restTimerInterval))
        timerEndsAt = nil
        endLiveActivity()
    }

    private func tickRestTimer() {
        guard isTimerRunning else {
            return
        }

        updateRemainingSecondsFromEndDate()

        if timerRemainingSeconds <= 0 {
            timerRemainingSeconds = 0
            isTimerRunning = false
            timerEndsAt = nil
            endLiveActivity()
            haptic.impactOccurred()
            haptic.prepare()
        }
    }

    private func updateRemainingSecondsFromEndDate() {
        guard let timerEndsAt else {
            return
        }

        timerRemainingSeconds = max(0, Int(ceil(timerEndsAt.timeIntervalSinceNow)))
    }

    private func updateLiveActivity(isPaused: Bool) {
        guard #available(iOS 16.1, *) else {
            return
        }

        let endsAt = timerEndsAt ?? Date().addingTimeInterval(TimeInterval(timerRemainingSeconds))
        RestTimerLiveActivityController.shared.startOrUpdate(
            workoutName: workout.name,
            intervalSeconds: max(5, Int(workout.restTimerInterval)),
            remainingSeconds: timerRemainingSeconds,
            endsAt: endsAt,
            isPaused: isPaused
        )
    }

    private func endLiveActivity() {
        guard #available(iOS 16.1, *) else {
            return
        }

        RestTimerLiveActivityController.shared.end(remainingSeconds: timerRemainingSeconds)
    }

    private func logWorkoutStartedIfNeeded() {
        guard !didLogWorkoutStarted else {
            return
        }

        didLogWorkoutStarted = true
        AppAnalytics.log(
            AppAnalytics.Event.workoutStarted,
            parameters: [
                AppAnalytics.Param.source: "workout_detail",
                AppAnalytics.Param.hasActiveSets: !workout.sets.isEmpty,
                AppAnalytics.Param.loggedSetCount: workout.loggedSets.count
            ]
        )
    }

    private func makeMatchingLoggedSets() -> [Workout.LoggedSet] {
        let normalizedWorkoutName = workout.name.normalizedExerciseName
        var loggedSets = userData.routines
            .flatMap(\.workouts)
            .filter { $0.id != workout.id && $0.name.normalizedExerciseName == normalizedWorkoutName }
            .flatMap(\.loggedSets)

        loggedSets.append(contentsOf: workout.loggedSets)
        return loggedSets.sorted { $0.loggedOnDate > $1.loggedOnDate }
    }

    private func makeWorkoutProgressPoints() -> [ProgressPoint] {
        ProgressDataBuilder.points(
            forWorkoutName: workout.name,
            in: userData.routines,
            metric: .maxWeight,
            range: selectedProgressRange,
            includeActiveSets: false,
            currentWorkout: workout
        )
    }
}

private struct RestTimerCard: View {
    @Binding var interval: Int
    @Binding var autoStartsOnAddSet: Bool
    let remainingSeconds: Int
    let isRunning: Bool
    let onStart: () -> Void
    let onPause: () -> Void
    let onReset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rest Timer")
                        .font(.title3.weight(.black))

                    Text(formatTime(interval))
                        .font(.caption.weight(.black))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(formatTime(remainingSeconds))
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Stepper(value: $interval, in: 5...600, step: 15) {
                Label("Duration", systemImage: "timer")
                    .font(.headline.weight(.bold))
            }

            Toggle(isOn: $autoStartsOnAddSet) {
                Label("Start after Add Set", systemImage: "play.circle.fill")
                    .font(.headline.weight(.bold))
            }
            .tint(AppColors.accent)

            HStack(spacing: 10) {
                Button(action: isRunning ? onPause : onStart) {
                    Label(isRunning ? "Pause" : "Start", systemImage: isRunning ? "pause.fill" : "play.fill")
                        .font(.headline.weight(.black))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .foregroundColor(.white)
                        .background(AppColors.accent)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Button(action: onReset) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.headline.weight(.black))
                        .frame(width: 52, height: 48)
                        .background(AppColors.elevated)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Reset timer")
            }
        }
        .padding(18)
        .background(AppColors.card)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border))
        .cornerRadius(8)
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = max(0, seconds) / 60
        let seconds = max(0, seconds) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

private struct LoggedSetRow: View {
    let index: Int
    let loggedSet: Workout.Set
    let weightUnit: WeightUnit
    let onDelete: () -> Void
    @State private var haptic = UIImpactFeedbackGenerator(style: .medium)

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

            Button(role: .destructive, action: deleteWithFeedback) {
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
        .onAppear {
            haptic.prepare()
        }
    }

    private func deleteWithFeedback() {
        haptic.impactOccurred()
        haptic.prepare()
        onDelete()
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
            WorkoutSummaryMetric(value: weightUnit.formattedWeight(fromStoredPounds: estimatedOneRepMax), label: "Est. 1RM")
            Rectangle()
                .fill(AppColors.border)
                .frame(width: 1)
            WorkoutSummaryMetric(value: weightUnit.formattedWeight(fromStoredPounds: maxWeight), label: "Max Weight")
            Rectangle()
                .fill(AppColors.border)
                .frame(width: 1)
            WorkoutSummaryMetric(value: "\(maxReps)", label: "Max Reps")
        }
        .frame(height: 92)
        .background(AppColors.card)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border))
        .cornerRadius(8)
    }
}

private struct WorkoutSummaryMetric: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 30, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(label)
                .font(.caption.weight(.black))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
    }
}
