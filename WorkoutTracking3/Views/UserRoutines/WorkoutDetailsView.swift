//
//  WorkoutDetailsView.swift
//  WorkoutTracking3
//
//  Created by Chris Peloso on 3/9/22.
//

import SwiftUI

struct WorkoutDetailsView: View {

    @Binding var workout: Workout
    @State private var showAlert = false
    @State private var navigateToHistory = false

    // Load exercise metadata once
    private let exercises: [Exercise] = Bundle.main.decode("exercises.json")
    
    private var suggestedSet: Workout.Set {
        if let currentSet = workout.sets.last {
            return currentSet
        }
        
        if let recentSet = workout.getMostRecentLoggedSet()?.sets.last {
            return recentSet
        }
        
        return Workout.Set(reps: 10, weight: 0)
    }

    var body: some View {
        VStack {
            Form {

                // Muscle Groups Image (only if available)
                if let imageName = exercises.first(where: { $0.name == workout.name })?.formImage,
                   !imageName.isEmpty {
                    Section {
                        Image(imageName)
                            .resizable()
                            .scaledToFit()
                    }
                }

                // Add new set
                Section {
                    NewSetCreator2(
                        sets: $workout.sets,
                        initialReps: suggestedSet.reps,
                        initialWeight: suggestedSet.weight
                    )
                } header: {
                    Text("Add new sets")
                }

                // Sets list
                Section {
                    NewListSets(sets: $workout.sets)
                } header: {
                    Text("Set started: \(workout.getStartDateStr())")
                }

                // New Log action (real button)
                Section {
                    Button {
                        logCurrentSet()
                        let impact = UIImpactFeedbackGenerator(style: .heavy)
                        impact.impactOccurred()
                    } label: {
                        Text("New Log")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 10)
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color(red: 255/255, green: 95/255, blue: 95/255), lineWidth: 3)
                )
                .listRowBackground(Color(UIColor.systemGroupedBackground))

                // History action (styled like New Log, no chevron)
                Section {
                    Button {
                        navigateToHistory = true
                    } label: {
                        Text("History")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 10)
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                    // Hidden NavigationLink to perform the navigation without the disclosure indicator
                    .background(
                        NavigationLink(
                            destination: LoggedSetsView(workout: $workout),
                            isActive: $navigateToHistory
                        ) { EmptyView() }
                        .hidden()
                    )
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color(red: 255/255, green: 95/255, blue: 95/255), lineWidth: 3)
                )
                .listRowBackground(Color(UIColor.systemGroupedBackground))

                // Most recent log
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
        }
        .navigationBarTitle(workout.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Error"),
                message: Text("Cannot log an empty set."),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // Ensure UI-driving mutations happen on the main actor
    @MainActor
    private func logCurrentSet() {
        guard !workout.sets.isEmpty else {
            showAlert = true
            return
        }

        workout.startDate = Date()
        let newLoggedSet = Workout.LoggedSet(sets: workout.sets, loggedOnDate: workout.startDate)
        workout.loggedSets.append(newLoggedSet)
        workout.sets.removeAll()
    }
}
