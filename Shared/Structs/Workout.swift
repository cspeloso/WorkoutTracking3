//
//  Workout.swift
//  Work It Out Apple Watch Watch App
//
//  Created by Chris Peloso on 1/12/24.
//

import Foundation

struct Workout: Identifiable, Codable, Equatable {
    var id = UUID()
    
    var name: String
    var sets: [Workout.Set]
    
    var startDate: Date
    
    
    var loggedSets: [LoggedSet]
    
    enum CodingKeys: CodingKey {
        case id, name, sets, loggedSets, startDate
    }
    
    init(name: String, sets: [Workout.Set], loggedSets: [LoggedSet], startDate: Date = Date()){
        self.name = name
        self.sets = sets
        self.loggedSets = loggedSets
        self.startDate = startDate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        sets = try container.decode([Set].self, forKey: .sets)
        loggedSets = try container.decode([LoggedSet].self, forKey: .loggedSets)
        
        //  Try to decode startdate. If it isn't found, then use today's date.
        if let startDateValue = try? container.decode(Date.self, forKey: .startDate){
            startDate = startDateValue
        }
        else {
            startDate = Date()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(sets, forKey: .sets)
        try container.encode(loggedSets, forKey: .loggedSets)
        try container.encode(startDate, forKey: .startDate)
    }
    
    func getStartDateStr() -> String {
        //  create date formatter
        let df = DateFormatter();
        
        //  set date format
        df.dateStyle = .short
        
        //  return formatted date string
        return df.string(from: startDate)
    }
    
    func getMostRecentLoggedSet() -> LoggedSet? {
        
        guard !loggedSets.isEmpty else {
            return nil
        }
        
        //  sort logged sets by loggedondate
        let sortedLoggedSets = loggedSets.sorted { $0.loggedOnDate > $1.loggedOnDate }
        
        return sortedLoggedSets.first
    }
    
    static func == (lhs: Workout, rhs: Workout) -> Bool {
        return lhs.name == rhs.name &&
            lhs.sets == rhs.sets &&
            lhs.loggedSets == rhs.loggedSets &&
            lhs.startDate == rhs.startDate
    }
    
    
    
    struct Set: Identifiable, Codable, Equatable {
        
        var id = UUID()
        
        var reps: Int
        var weight: Double
        
        
        enum CodingKeys: CodingKey {
            case id, reps, weight, startedDate
        }
        
        
        init(reps: Int, weight: Double){
            self.reps = reps
            self.weight = weight
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
            reps = try container.decode(Int.self, forKey: .reps)
            weight = try container.decode(Double.self, forKey: .weight)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(id, forKey: .id)
            try container.encode(reps, forKey: .reps)
            try container.encode(weight, forKey: .weight)
        }
        
    }
    
    struct LoggedSet: Identifiable, Codable, Equatable {
        
        var id = UUID()
        
        var sets: [Workout.Set]
        
        var loggedOnDate: Date
        
        enum CodingKeys: CodingKey {
            case id, sets, loggedOnDate
        }
        
        init(sets: [Workout.Set], loggedOnDate: Date){
            self.sets = sets
            self.loggedOnDate = loggedOnDate
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
            sets = try container.decode([Workout.Set].self, forKey: .sets)
            loggedOnDate = try container.decode(Date.self, forKey: .loggedOnDate)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(id, forKey: .id)
            try container.encode(sets, forKey: .sets)
            try container.encode(loggedOnDate, forKey: .loggedOnDate)
        }
        
        
        
        
        func getLoggedDateStr() -> String {
            //  create date formatter
            let df = DateFormatter();
            
            //  set date format
            df.dateStyle = .short
            
            //  return formatted date string
            return df.string(from: loggedOnDate)
        }
        
    }
}
