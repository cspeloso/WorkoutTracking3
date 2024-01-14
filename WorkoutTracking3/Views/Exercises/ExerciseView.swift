//
//  ExerciseView.swift
//  WorkoutTracking3
//
//  Created by Chris Peloso on 3/10/22.
//

import SwiftUI

struct ExerciseView: View {
    
    let exercises: [Exercise] = Bundle.main.decode("exercises.json")
    
    @State var searchText: String = ""

    var filteredExercises: [Exercise] {
        if searchText.isEmpty{
            return exercises
        }
        else {
            return exercises.filter { exercise in
                return exercise.name.localizedCaseInsensitiveContains(searchText) || exercise.muscleGroups.contains { muscleGroup in
                    return muscleGroup.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
    }
    
    

    var body: some View {
        
        NavigationView {
            VStack {
                
                TextField("Search", text: $searchText)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal, 15)
                
                List {
                    ForEach(filteredExercises.sorted(by: {$0.name < $1.name})) { exercise in
                        NavigationLink(destination: ExerciseDetailsView(exercise: exercise)){
                            HStack {
                                Text(exercise.name)
                                Spacer()
                                Image(exercise.formImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width:75,height: 30)
                                    .cornerRadius(5)
                            }
                        }
                    }
                }
                .navigationTitle("Exercises")
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct ExerciseView_Previews: PreviewProvider {
    static var previews: some View {
        @State var searchText = "Bench"
        ExerciseView()
    }
}
