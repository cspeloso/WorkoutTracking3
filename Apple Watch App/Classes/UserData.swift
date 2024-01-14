//
//  UserData.swift
//  Work It Out Apple Watch Watch App
//
//  Created by Chris Peloso on 1/12/24.
//

import Foundation

class UserData3: ObservableObject, Codable {
    
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
    
    
    //  gets user data json
    static func getUserDataJson(completion: @escaping (Data?) -> Void) {
        if let data = UserDefaults.standard.data(forKey: "UserDataFirstAttempt"){
            completion(data)
        }
        else{
            completion(nil)
        }
    }
    
}
