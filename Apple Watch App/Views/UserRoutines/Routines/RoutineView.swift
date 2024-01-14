//
//  RoutineView.swift
//  Work It Out Apple Watch Watch App
//
//  Created by Chris Peloso on 1/12/24.
//

import SwiftUI

let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]


struct RoutineView: View {
    
    //  set variables
    @EnvironmentObject var userData: UserData
    
    var dateFormatter: DateFormatter?
    
    init(){
        dateFormatter = DateFormatter()
        dateFormatter?.dateFormat = "EEEE"
    }
    
//    let dateFormatter: DateFormatter = {
//        let df = DateFormatter()
//        df.dateFormat = "EEEE"
//        return df
//    }()
    var currentDayOfWeek: String {
        return dateFormatter?.string(from: Date()) ?? ""
    }
    
    //  create body view
    var body: some View {
        
        NavigationView {
            
            VStack {
            
                Image("WorkItOutBanner")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 150)
                
                Form {
                    List {
                        ForEach(userData.routines.indices.sorted { indexA, indexB in
                                    let routineA = userData.routines[indexA]
                                    let routineB = userData.routines[indexB]
                                    if let indexA = weekdays.firstIndex(of: routineA.weekday), let indexB = weekdays.firstIndex(of: routineB.weekday) {
                                        if routineA.weekday == currentDayOfWeek {
                                            return true // Prioritize routineA if it's the current day of the week
                                        } else if routineB.weekday == currentDayOfWeek {
                                            return false // Prioritize routineB if it's the current day of the week
                                        } else {
                                            return indexA < indexB // If neither is the current day, sort by weekday index
                                        }                                    }
                                    return false
                        }, id: \.self) { index in
                                    
                            let routine = userData.routines[index]
                            
                            Section {
                                VStack(alignment: .leading) {
                                    
                                    NavigationLink(destination: RoutineDetailsView(routine: $userData.routines[index])){
                                        Text(routine.name != "" ? routine.name : routine.weekday)
                                                .padding(.vertical, 10)
                                                .font(.headline)
                                                .foregroundColor(routine.name != "" ? .primary : routine.weekday != currentDayOfWeek ? Color(red: 255/255, green: 95/255, blue: 95/255) : Color(red: 0/255, green: 255/255, blue:0/255))
                                    }
                                    
                                    if routine.name != "" {
                                        Text("**\(routine.weekday)**")
                                                .padding(.bottom,10)
                                                .font(.subheadline)
                                                .foregroundColor(routine.weekday != currentDayOfWeek ? Color(red: 255/255, green: 95/255, blue: 95/255) : Color(red: 0/255, green: 255/255, blue:0/255))
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteRoutine)

                    }
                }
                .navigationTitle("Routines")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing){
                        NavigationLink(destination: AddRoutine(routines: $userData.routines)){
                            Text("Add routine")
                        }
                    }
                }
            }
            
            
        }
        .navigationViewStyle(.stack)
        
        
        
    /*
        NavigationView {
//                Image("WorkItOutBanner")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 400, height: 150)
                    
            Form {
                VStack {
                    if userData.routines.count == 0 {
                        Text("No routines created yet.")
                    }
                    else {
                        ForEach($userData.routines) { $routine in
                            Section {
                                VStack (alignment: .leading){
                                    NavigationLink(destination: RoutineDetailsView(routine: $routine)){
                                        Text(routine.name)
                                            .padding(.vertical,10)
                                            .font(.headline)
                                    }
                                    Text("**\(routine.weekday)**")
                                        .padding(.bottom, 10)
                                        .font(.subheadline)
                                        .foregroundColor(Color(red: 255/255, green: 95/255, blue: 95/255))
                                }
                            }
                        }
                        .onDelete(perform: deleteRoutine)
                    }
                }
                .navigationTitle("Routines")
                .toolbar {
                    
                    ToolbarItem(placement: .principal) {
                        Image("WorkItOutBanner")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200)
                    }
                    
                    ToolbarItem(placement: ToolbarItemPlacement.navigationBarTrailing){
                        NavigationLink(destination: AddRoutine(routines: $userData.routines)){
                            Image(systemName: "plus")
                        }
                    }
                }
        }
    }
        //  THIS FIXED THE NAVIGATION VIEW POP BACK ISSUE. ONE SINGLE LINE. FML
        .navigationViewStyle(.stack)
        */
    }
    
    func deleteRoutine(at offsets: IndexSet){
        let sortedIndexes = userData.routines.indices.sorted {indexA, indexB in
            let routineA = userData.routines[indexA]
            let routineB = userData.routines[indexB]
            if let indexA = weekdays.firstIndex(of: routineA.weekday), let indexB = weekdays.firstIndex(of: routineB.weekday) {
                return indexA < indexB
            }
            return false
        }
        
        let originalIndexes = offsets.map { sortedIndexes[$0] }
        
        userData.routines.remove(atOffsets: IndexSet(originalIndexes))
        

    }
}

struct RoutineView_Previews: PreviewProvider {
    static var previews: some View {
//        RoutineView()
        Text("Preview not available")
    }
}
