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
    
    @Binding var workout: Workout
    @State private var showAlert = false
    @State private var navigateToHistory = false
    @State private var timerRemainingSeconds = 0
    @State private var isTimerRunning = false
    
    private let exercises: [Exercise] = Bundle.main.decode("exercises.json")
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

                    Stepper(value: restTimerIntervalBinding, in: 5...600, step: 15) {
                        Text("Rest \(formatTimer(Int(workout.restTimerInterval)))")
                    }

                    Toggle("Auto-start", isOn: $workout.startsRestTimerOnAddSet)

                    HStack {
                        Button(isTimerRunning ? "Pause" : "Start") {
                            isTimerRunning ? pauseRestTimer() : startRestTimer()
                        }

                        Button {
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
        .onAppear {
            timerRemainingSeconds = Int(workout.restTimerInterval)
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
            get: { Int(workout.restTimerInterval) },
            set: { newValue in
                workout.restTimerInterval = TimeInterval(max(5, newValue))
                if !isTimerRunning {
                    timerRemainingSeconds = Int(workout.restTimerInterval)
                }
            }
        )
    }

    private func startRestTimer() {
        let interval = max(5, Int(workout.restTimerInterval))
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
        timerRemainingSeconds = max(5, Int(workout.restTimerInterval))
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
            WKInterfaceDevice.current().play(.notification)
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
