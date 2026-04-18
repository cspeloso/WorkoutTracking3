//
//  Routine.swift
//  Work It Out Apple Watch Watch App
//
//  Created by Chris Peloso on 1/12/24.
//

import Foundation

struct Routine: Identifiable, Codable, Equatable {
    
    var id = UUID()
    
    var name: String
    var weekday: String
    var workouts: [Workout]
    var isArchived: Bool
    
    
    enum CodingKeys: CodingKey {
        case id, name, weekday, workouts, isArchived
    }
    
    init(name: String, weekday: String, workouts: [Workout], isArchived: Bool = false){
        self.name = name
        self.weekday = weekday
        self.workouts = workouts
        self.isArchived = isArchived
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.weekday = try container.decode(String.self, forKey: .weekday)
        self.workouts = try container.decode([Workout].self, forKey: .workouts)
        self.isArchived = (try? container.decode(Bool.self, forKey: .isArchived)) ?? false
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(weekday, forKey: .weekday)
        try container.encode(workouts, forKey: .workouts)
        try container.encode(isArchived, forKey: .isArchived)
    }
    
    static func == (lhs: Routine, rhs: Routine) -> Bool {
        return lhs.name == rhs.name &&
        lhs.weekday == rhs.weekday &&
        lhs.workouts == rhs.workouts &&
        lhs.isArchived == rhs.isArchived
    }
}
