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
            
            VStack {
            
                Image("WorkItOutBanner")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 150)
                
                Form {
                    List {
                        ForEach ($userData.routines) { $routine in
                            Section {
                                VStack(alignment: .leading) {
                                    
                                    NavigationLink(destination: RoutineDetailsView(routine: $routine)){
                                        Text(routine.name != "" ? routine.name : routine.weekday)
                                                .padding(.vertical, 10)
                                                .font(.headline)
                                                .foregroundColor(routine.name != "" ? .primary : Color(red: 255/255, green: 95/255, blue: 95/255))
                                    }
                                    
                                    if routine.name != "" {
                                        Text("**\(routine.weekday)**")
                                                .padding(.bottom,10)
                                                .font(.subheadline)
                                                .foregroundColor(Color(red: 255/255, green: 95/255, blue: 95/255))
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteRoutine)

                    }
                }
                .navigationTitle("Routines")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing){
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
        userData.routines.remove(atOffsets: offsets)
    }
}

struct RoutineView_Previews: PreviewProvider {
    static var previews: some View {
//        RoutineView()
        Text("Preview not available")
    }
}
