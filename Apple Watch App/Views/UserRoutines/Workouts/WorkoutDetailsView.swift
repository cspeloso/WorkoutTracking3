//
//  WorkoutDetailsView.swift
//  Work It Out Apple Watch Watch App
//
//  Created by Chris Peloso on 1/12/24.
//

import SwiftUI
import WatchKit
import Combine

struct WorkoutDetailsView: View {
    
    @EnvironmentObject private var userData: UserData
    @Binding var workout: Workout
    @State private var showAlert = false
    @State private var showTimerSettingsInfo = false
    @State private var navigateToHistory = false
    @State private var timerRemainingSeconds = 0
    @State private var isTimerRunning = false
    
    private let exercises: [Exercise] = Bundle.main.decode("exercises.json")
    private static let timerSettingsInfoShownKey = "WorkoutDetailsTimerSettingsInfoShown"
    private let restTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Form {
            if let imageName = exercises.first(where: { $0.name == workout.name })?.formImage,
               !imageName.isEmpty {
                Section {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                }
            }
            
            Section {
                NewSetCreator2(
                    sets: $workout.sets,
                    onAddSet: handleSetAdded
                )
            } header: {
                Text("Add new sets")
            }

            Section {
                VStack(spacing: 10) {
                    Text(formatTimer(timerRemainingSeconds))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .frame(maxWidth: .infinity)

                    Stepper(value: restTimerIntervalBinding, in: 15...600, step: 15) {
                        Text("Rest \(formatTimer(restTimerIntervalBinding.wrappedValue))")
                    }

                    Toggle("Auto-start", isOn: $workout.startsRestTimerOnAddSet)
                        .onChange(of: workout.startsRestTimerOnAddSet) { _ in
                            playTimerControlHaptic()
                        }

                    HStack {
                        Button(isTimerRunning ? "Pause" : "Start") {
                            playTimerControlHaptic()
                            isTimerRunning ? pauseRestTimer() : startRestTimer()
                        }

                        Button {
                            playTimerControlHaptic()
                            resetRestTimer()
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                        }
                        .accessibilityLabel("Reset timer")
                    }
                }
            } header: {
                Text("Rest Timer")
            }
            
            Section {
                NewListSets(sets: $workout.sets)
            } header: {
                Text("Set started: \(workout.getStartDateStr())")
            }
            
            Section {
                Button {
                    logCurrentSet()
                } label: {
                    Text("New Log")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color(red: 255/255, green: 95/255, blue: 95/255), lineWidth: 3)
            )
            
            Section {
                Button {
                    navigateToHistory = true
                } label: {
                    Text("History")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color(red: 255/255, green: 95/255, blue: 95/255), lineWidth: 3)
            )
            
            Section {
                VStack {
                    if let mostRecentLoggedSet = workout.getMostRecentLoggedSet() {
                        MostRecentLoggedSetView(mostRecentLoggedSet: mostRecentLoggedSet)
                    } else {
                        Text("No past logged sets available.")
                    }
                }
            }
        }
        .navigationBarTitle(workout.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToHistory) {
            LoggedSetsView(workout: $workout)
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Error"),
                message: Text("Cannot log an empty set."),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert("Rest timer settings", isPresented: $showTimerSettingsInfo) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Set a default rest timer in Settings, and choose whether workouts use individual timers or the default.")
        }
        .onAppear {
            normalizeStoredRestTimerIntervals()
            timerRemainingSeconds = effectiveRestTimerInterval
            showTimerSettingsInfoIfNeeded()
        }
        .onReceive(restTimer) { _ in
            tickRestTimer()
        }
    }
    
    @MainActor
    private func logCurrentSet() {
        guard !workout.sets.isEmpty else {
            showAlert = true
            WKInterfaceDevice.current().play(.failure)
            return
        }
        
        let loggedOnDate = workout.startDate
        let newLoggedSet = Workout.LoggedSet(sets: workout.sets, loggedOnDate: loggedOnDate)
        workout.loggedSets.append(newLoggedSet)
        workout.sets.removeAll()
        workout.startDate = Date()
        resetRestTimer()
        WKInterfaceDevice.current().play(.success)
    }

    @MainActor
    private func handleSetAdded() {
        if workout.sets.count == 1 {
            workout.startDate = Date()
        }

        if workout.startsRestTimerOnAddSet {
            startRestTimer()
        }
    }

    private var restTimerIntervalBinding: Binding<Int> {
        Binding(
            get: { effectiveRestTimerInterval },
            set: { newValue in
                setEffectiveRestTimerInterval(newValue)
                if !isTimerRunning {
                    timerRemainingSeconds = effectiveRestTimerInterval
                }
                playTimerControlHaptic()
            }
        )
    }

    private func startRestTimer() {
        let interval = effectiveRestTimerInterval
        if timerRemainingSeconds <= 0 || timerRemainingSeconds > interval {
            timerRemainingSeconds = interval
        }
        isTimerRunning = true
    }

    private func pauseRestTimer() {
        isTimerRunning = false
    }

    private func resetRestTimer() {
        isTimerRunning = false
        timerRemainingSeconds = effectiveRestTimerInterval
    }

    private func normalizedRestTimerInterval(_ seconds: Int) -> Int {
        UserData.normalizedRestTimerInterval(seconds)
    }

    private var effectiveRestTimerInterval: Int {
        if userData.usesIndividualRestTimers {
            return normalizedRestTimerInterval(Int(workout.restTimerInterval))
        }

        return normalizedRestTimerInterval(Int(userData.defaultRestTimerInterval))
    }

    private func setEffectiveRestTimerInterval(_ seconds: Int) {
        let interval = TimeInterval(normalizedRestTimerInterval(seconds))
        if userData.usesIndividualRestTimers {
            workout.restTimerInterval = interval
        } else {
            userData.defaultRestTimerInterval = interval
        }
    }

    private func normalizeStoredRestTimerIntervals() {
        workout.restTimerInterval = TimeInterval(normalizedRestTimerInterval(Int(workout.restTimerInterval)))
        userData.defaultRestTimerInterval = TimeInterval(normalizedRestTimerInterval(Int(userData.defaultRestTimerInterval)))
    }

    private func showTimerSettingsInfoIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: Self.timerSettingsInfoShownKey) else {
            return
        }

        UserDefaults.standard.set(true, forKey: Self.timerSettingsInfoShownKey)
        showTimerSettingsInfo = true
    }

    private func playTimerControlHaptic() {
        WKInterfaceDevice.current().play(.click)
    }

    private func tickRestTimer() {
        guard isTimerRunning else {
            return
        }

        if timerRemainingSeconds > 1 {
            timerRemainingSeconds -= 1
        } else {
            timerRemainingSeconds = 0
            isTimerRunning = false
            if userData.restTimerAlertEnabled {
                WKInterfaceDevice.current().play(.notification)
            }
        }
    }

    private func formatTimer(_ seconds: Int) -> String {
        let minutes = max(0, seconds) / 60
        let seconds = max(0, seconds) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

//struct WorkoutDetailsView_Previews: PreviewProvider {
//
//    @State static var workout: Workout = Workout(name: "test", sets: [], loggedSets: [])
//
//    static var previews: some View {
//        WorkoutDetailsView(workout: $workout)
//    }
//}
