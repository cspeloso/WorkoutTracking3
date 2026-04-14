//
//  WorkoutDetailsView.swift
//  Work It Out Apple Watch Watch App
//
//  Created by Chris Peloso on 1/12/24.
//

import SwiftUI
import WatchKit

struct WorkoutDetailsView: View {
    
    @Binding var workout: Workout
    @State private var showAlert = false
    @State private var navigateToHistory = false
    
    private let exercises: [Exercise] = Bundle.main.decode("exercises.json")

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
                NewSetCreator2(sets: $workout.sets)
            } header: {
                Text("Add new sets")
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
    }
    
    @MainActor
    private func logCurrentSet() {
        guard !workout.sets.isEmpty else {
            showAlert = true
            WKInterfaceDevice.current().play(.failure)
            return
        }
        
        workout.startDate = Date()
        let newLoggedSet = Workout.LoggedSet(sets: workout.sets, loggedOnDate: workout.startDate)
        workout.loggedSets.append(newLoggedSet)
        workout.sets.removeAll()
        WKInterfaceDevice.current().play(.success)
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
