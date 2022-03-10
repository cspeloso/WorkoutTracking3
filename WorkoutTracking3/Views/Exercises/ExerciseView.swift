//
//  ExerciseView.swift
//  WorkoutTracking3
//
//  Created by Chris Peloso on 3/10/22.
//

import SwiftUI

struct ExerciseView: View {
    
    let exercises: [Exercise] = Bundle.main.decode("exercises.json")

    var body: some View {
        NavigationView {
            List {
                ForEach(exercises.sorted(by: {$0.name < $1.name})) { exercise in
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
}

struct ExerciseView_Previews: PreviewProvider {
    static var previews: some View {
        ExerciseView()
    }
}
