//
//  UserData.swift
//  WorkoutTracking3
//
//  Created by Chris Peloso on 3/9/22.
//

import Foundation


class UserData: ObservableObject, Codable {
    
    enum CodingKeys: CodingKey {
        case routines
    }
    
    @Published var routines: [Routine] {
        didSet {
//            print("DIDSET FIRED!!")
            if let encoded = try? JSONEncoder().encode(routines) {
                UserDefaults.standard.set(encoded, forKey: "UserDataFirstAttempt")
            }
            else {
                print("There was an issue encoding values.")
            }
        }
    }
    
    init() {
        if let data = UserDefaults.standard.data(forKey: "UserDataFirstAttempt") {
            if let decoded = try? JSONDecoder().decode([Routine].self, from: data) {
                self.routines = decoded
                return
            }
        }
        
        routines = []
    }
    
    init(routines: [Routine]) {
        self.routines = routines
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        routines = try container.decode([Routine].self, forKey: .routines)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(routines, forKey: .routines)
    }
    
}
