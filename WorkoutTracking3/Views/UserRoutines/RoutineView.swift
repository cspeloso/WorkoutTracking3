//
//  RoutineView.swift
//  WorkoutTracking3
//
//  Created by Chris Peloso on 3/9/22.
//

import SwiftUI

struct RoutineView: View {
    
    @EnvironmentObject var userData: UserData
    
    var body: some View {
        NavigationView {
            Form {
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
                ToolbarItem(placement: ToolbarItemPlacement.navigationBarTrailing){
                    NavigationLink(destination: AddRoutine(routines: $userData.routines)){
                        Image(systemName: "plus")
                    }
                    
                }
            }
        }
        //  THIS FIXED THE NAVIGATION VIEW POP BACK ISSUE. ONE SINGLE LINE. FML
        .navigationViewStyle(.stack)
    }
    
    func deleteRoutine(at offsets: IndexSet){
        userData.routines.remove(atOffsets: offsets)
    }
}

struct RoutineView_Previews: PreviewProvider {
    static var previews: some View {
//        RoutineView()
        Text("ass")
    }
}
