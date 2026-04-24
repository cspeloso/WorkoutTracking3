//
//  LoggedSetsView.swift
//  WorkoutTracking3
//
//  Created by Chris Peloso on 3/17/22.
//

import SwiftUI

struct LoggedSetsView: View {
    @EnvironmentObject private var userData: UserData
    @Binding var workout: Workout

    private var normalizedWorkoutName: String {
        workout.name.normalizedExerciseName
    }

    private var currentRoutineMetadata: (name: String, isArchived: Bool) {
        guard let routine = userData.routines.first(where: { routine in
            routine.workouts.contains(where: { $0.id == workout.id })
        }) else {
            return ("Current workout", false)
        }

        return (routine.name.isEmpty ? routine.weekday : routine.name, routine.isArchived)
    }

    private var historyEntries: [LoggedSetHistoryEntry] {
        var entries = userData.routines.flatMap { routine in
            routine.workouts
                .filter { $0.id != workout.id && $0.name.normalizedExerciseName == normalizedWorkoutName }
                .flatMap { matchingWorkout in
                    matchingWorkout.loggedSets.map { loggedSet in
                        LoggedSetHistoryEntry(
                            source: .routine(workoutID: matchingWorkout.id, loggedSetID: loggedSet.id),
                            loggedSet: loggedSet,
                            routineName: routine.name.isEmpty ? routine.weekday : routine.name,
                            isArchived: routine.isArchived
                        )
                    }
                }
        }

        entries.append(contentsOf: workout.loggedSets.map { loggedSet in
            LoggedSetHistoryEntry(
                source: .current(loggedSetID: loggedSet.id),
                loggedSet: loggedSet,
                routineName: currentRoutineMetadata.name,
                isArchived: currentRoutineMetadata.isArchived
            )
        })

        return entries.sorted { $0.loggedSet.loggedOnDate > $1.loggedSet.loggedOnDate }
    }

    var body: some View {
        Form {
            Section {
                if workout.sets.isEmpty {
                    Text("No current sets.")
                        .italic()
                } else {
                    ForEach(workout.sets) { set in
                        Text("\(set.reps) reps @ \(userData.weightUnit.formattedWeight(fromStoredPounds: set.weight))")
                    }
                }
            } header: {
                Text("Current Sets")
                    .font(.subheadline)
            }

            Section {
                if historyEntries.isEmpty {
                    Text("No logged sets")
                } else {
                    ForEach(historyEntries) { entry in
                        Section {
                            VStack(alignment: .leading, spacing: 8) {
                                if let loggedSetBinding = binding(for: entry.source) {
                                    NavigationLink(destination: LoggedSetEditView(loggedSet: loggedSetBinding)) {
                                        Text("**Logged on \(formatDate(date: entry.loggedSet.loggedOnDate))**")
                                    }
                                } else {
                                    Text("**Logged on \(formatDate(date: entry.loggedSet.loggedOnDate))**")
                                }

                                ForEach(entry.loggedSet.sets) { set in
                                    Text("\(set.reps) reps @ \(userData.weightUnit.formattedWeight(fromStoredPounds: set.weight))")
                                }
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteLoggedSet(entry.source)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            } header: {
                Text("Logged sets")
                    .font(.subheadline)
            } footer: {
                Text("History is shared by exercise name, including archived routines.")
            }
        }
        .navigationTitle("\(workout.name) History")
    }

    private func binding(for source: LoggedSetHistoryEntry.Source) -> Binding<Workout.LoggedSet>? {
        switch source {
        case .current(let loggedSetID):
            guard let loggedSetIndex = workout.loggedSets.firstIndex(where: { $0.id == loggedSetID }) else {
                return nil
            }

            return $workout.loggedSets[loggedSetIndex]
        case .routine(let workoutID, let loggedSetID):
            guard let routineIndex = userData.routines.firstIndex(where: { routine in
                routine.workouts.contains(where: { $0.id == workoutID })
            }),
                  let workoutIndex = userData.routines[routineIndex].workouts.firstIndex(where: { $0.id == workoutID }),
                  let loggedSetIndex = userData.routines[routineIndex].workouts[workoutIndex].loggedSets.firstIndex(where: { $0.id == loggedSetID }) else {
                return nil
            }

            return Binding(
                get: {
                    userData.routines[routineIndex].workouts[workoutIndex].loggedSets[loggedSetIndex]
                },
                set: { updatedLoggedSet in
                    userData.routines[routineIndex].workouts[workoutIndex].loggedSets[loggedSetIndex] = updatedLoggedSet
                }
            )
        }
    }

    private func deleteLoggedSet(_ source: LoggedSetHistoryEntry.Source) {
        switch source {
        case .current(let loggedSetID):
            workout.loggedSets.removeAll { $0.id == loggedSetID }
        case .routine(let workoutID, let loggedSetID):
            guard let routineIndex = userData.routines.firstIndex(where: { routine in
                routine.workouts.contains(where: { $0.id == workoutID })
            }),
                  let workoutIndex = userData.routines[routineIndex].workouts.firstIndex(where: { $0.id == workoutID }) else {
                return
            }

            userData.routines[routineIndex].workouts[workoutIndex].loggedSets.removeAll { $0.id == loggedSetID }
        }
    }

    private func formatDate(date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .short
        return df.string(from: date)
    }
}

private struct LoggedSetHistoryEntry: Identifiable {
    enum Source: Equatable {
        case current(loggedSetID: Workout.LoggedSet.ID)
        case routine(workoutID: Workout.ID, loggedSetID: Workout.LoggedSet.ID)
    }

    let source: Source
    let loggedSet: Workout.LoggedSet
    let routineName: String
    let isArchived: Bool

    var id: String {
        switch source {
        case .current(let loggedSetID):
            return "current-\(loggedSetID)"
        case .routine(let workoutID, let loggedSetID):
            return "\(workoutID)-\(loggedSetID)"
        }
    }
}

struct LoggedSetsView_Previews: PreviewProvider {
    @State static var workout: Workout = Workout(
        name: "Calf Raises",
        sets: [Workout.Set(reps: 10, weight: 55), Workout.Set(reps: 10, weight: 55)],
        loggedSets: [Workout.LoggedSet(sets: [Workout.Set(reps: 10, weight: 55)], loggedOnDate: Date())]
    )

    static var previews: some View {
        LoggedSetsView(workout: $workout)
            .environmentObject(UserData.shared)
    }
}
