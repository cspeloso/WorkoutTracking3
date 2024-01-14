//
//  Routine.swift
//  Work It Out Apple Watch Watch App
//
//  Created by Chris Peloso on 1/12/24.
//

import Foundation

struct Routine: Identifiable, Codable {
    
    var id = UUID()
    
    var name: String
    var weekday: String
    var workouts: [Workout]
    
    
    enum CodingKeys: CodingKey {
        case name, weekday, workouts
    }
    
    init(name: String, weekday: String, workouts: [Workout]){
        self.name = name
        self.weekday = weekday
        self.workouts = workouts
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.name = try container.decode(String.self, forKey: .name)
        self.weekday = try container.decode(String.self, forKey: .weekday)
        self.workouts = try container.decode([Workout].self, forKey: .workouts)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(weekday, forKey: .weekday)
        try container.encode(workouts, forKey: .workouts)
    }
    
}
