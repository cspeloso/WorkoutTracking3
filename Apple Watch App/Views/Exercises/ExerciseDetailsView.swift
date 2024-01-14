//
//  ExerciseDetailsView.swift
//  Work It Out Apple Watch Watch App
//
//  Created by Chris Peloso on 1/12/24.
//

import SwiftUI

struct ExerciseDetailsView: View {
    
    var exercise: Exercise
    
    var body: some View {
        
        //  Image viewer
        TabView {
            VStack {
                Text("Form")
                Image(exercise.formImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 400, height: 200)
            }
            .tag("Form")
            
            VStack {
                Text("Muscles")
                Image(exercise.musclesImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 400, height: 200)
            }
            .tag("Muscles")
        }
        .tabViewStyle(PageTabViewStyle())
        .previewLayout(.fixed(width:400, height: 300))
        
        ScrollView {
            VStack {
                Text(exercise.name)
                    .font(.headline)
                
                Divider()
                
                if exercise.description.trimmingCharacters(in: ["\n","\t"]) != "" {
                    VStack (alignment: .leading) {
                        ForEach(0..<exercise.description.components(separatedBy: "\n").count) { i in
                            let str = exercise.description.components(separatedBy: "\n")[i].trimmingCharacters(in: ["\n", "\t"])
                            
                            Text("**\(i+1).** \(str)")
                                .padding(.bottom,15)
                        }
                    }
                }
                else {
                    Text("No exercise instructions found.")
                }
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ExerciseDetailsView_Previews: PreviewProvider {
    
    static var exercise: Exercise = Exercise(name: "Bench Press", description: "test", formImage: "bench-press-form", musclesImage: "bench-press-muscles", muscleGroups: ["Biceps", "Chest"])
    
    static var previews: some View {
        ExerciseDetailsView(exercise: exercise)
    }
}
