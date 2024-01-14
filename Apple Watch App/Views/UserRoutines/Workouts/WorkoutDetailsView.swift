//
//  WorkoutDetailsView.swift
//  Work It Out Apple Watch Watch App
//
//  Created by Chris Peloso on 1/12/24.
//

import SwiftUI

struct WorkoutDetailsView: View {
    
    @Binding var workout: Workout
    @State private var showAlert = false
    @State private var todaysDate = DateFormatter()
    
    
    
    let exercises: [Exercise] = Bundle.main.decode("exercises.json")
    


    var body: some View {
        VStack {
            Text("test")
            /*
            Form {
                


                //  Muscle Groups Image
                if(exercises.filter{$0.name == workout.name}.first?.formImage ?? "" != ""){
                    Section {
                        Image(exercises.filter{$0.name == workout.name}.first?.formImage ?? "")
                            .resizable()
                            .scaledToFit()
                    }
                }
                
                //  add a new set
                Section {
//                    NewSetCreator(sets: $workout.sets)
                    NewSetCreator2(sets: $workout.sets)
                } header: {
                    Text("Add new sets")
                }
                
                //  sets list
                Section {
                    NewListSets(sets: $workout.sets)
                } header: {
                    Text("Set started: \(workout.getStartDateStr())")
                }
                
                
                //  New Log
                Section{
                    ZStack {
                        NavigationLink(""){
                            //
                        }
                        .opacity(0)
                        .disabled(true)
                        
                        Button("aaa"){
                            logCurrentSet()
//                            let impactMed = UIImpactFeedbackGenerator(style: .heavy)
//                            impactMed.impactOccurred()
                            WKInterfaceDevice.current().play(.success)
                        }
                        .opacity(0)
                        
                        Text("**New Log**")
                            .padding(.vertical, 10)
                            .foregroundColor(.primary)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color(red: 255/255, green: 95/255, blue: 95/255), lineWidth: 3)
                )
                .listRowBackground(Color(UIColor.systemGroupedBackground))
                
                
//                  History
                Section {
                    ZStack{
                        NavigationLink(destination: LoggedSetsView(workout: $workout)){

                        }
                        .opacity(0)

                        Text("**History**")
                            .padding(.vertical, 10)
                            .foregroundColor(.primary)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color(red: 255/255, green: 95/255, blue: 95/255), lineWidth: 3)
                )
                .listRowBackground(Color(UIColor.systemGroupedBackground))
                
                
                //  Most recent log
                Section {
                    VStack {
                        if let mostRecentLoggedSet = workout.getMostRecentLoggedSet() {
                            MostRecentLoggedSetView(mostRecentLoggedSet: mostRecentLoggedSet)
                        }
                        else {
                            Text("No past logged sets available.")
                        }
                    }
                }
                
                
                
            }
            */
        }
        .navigationBarTitle(workout.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showAlert){
            Alert(
                title: Text("Error"),
                message: Text("Cannot log an empty set."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    
    func logCurrentSet() {
        if (!workout.sets.isEmpty){
            workout.startDate = Date()
            let newLoggedSet: Workout.LoggedSet = Workout.LoggedSet(sets: workout.sets, loggedOnDate: workout.startDate)
            workout.loggedSets.append(newLoggedSet)
            workout.sets = []
        }
        else {
            showAlert = true
        }
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
