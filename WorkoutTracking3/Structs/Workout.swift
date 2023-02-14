//
//  Workout.swift
//  WorkoutTracking3
//
//  Created by Chris Peloso on 3/9/22.
//

import Foundation

struct Workout: Identifiable, Codable {
    var id = UUID()
    
    var name: String
    var sets: [Workout.Set]
    
    var loggedSets: [LoggedSet]
    
    enum CodingKeys: CodingKey {
        case name, sets, loggedSets
    }
    
    init(name: String, sets: [Workout.Set], loggedSets: [LoggedSet]){
        self.name = name
        self.sets = sets
        self.loggedSets = loggedSets
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        sets = try container.decode([Set].self, forKey: .sets)
        loggedSets = try container.decode([LoggedSet].self, forKey: .loggedSets)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(sets, forKey: .sets)
        try container.encode(loggedSets, forKey: .loggedSets)
    }
    
    
    
    struct Set: Identifiable, Codable {
        
        var id = UUID()
        
        var reps: Int
        var weight: Double
        
        enum CodingKeys: CodingKey {
            case reps, weight
        }
        
        
        init(reps: Int, weight: Double){
            self.reps = reps
            self.weight = weight
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            reps = try container.decode(Int.self, forKey: .reps)
            weight = try container.decode(Double.self, forKey: .weight)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(reps, forKey: .reps)
            try container.encode(weight, forKey: .weight)
        }
        
    }
    
    struct LoggedSet: Identifiable, Codable {
        
        var id = UUID()
        
        var sets: [Workout.Set]
        
        var loggedOnDate: Date
        
        enum CodingKeys: CodingKey {
            case sets, loggedOnDate
        }
        
        init(sets: [Workout.Set], loggedOnDate: Date){
            self.sets = sets
            self.loggedOnDate = loggedOnDate
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            sets = try container.decode([Workout.Set].self, forKey: .sets)
            loggedOnDate = try container.decode(Date.self, forKey: .loggedOnDate)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(sets, forKey: .sets)
            try container.encode(loggedOnDate, forKey: .loggedOnDate)
        }
        
    }
}
