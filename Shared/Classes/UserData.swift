//
//  UserData.swift
//  Work It Out Apple Watch Watch App
//
//  Created by Chris Peloso on 1/12/24.
//

import Foundation

class UserData: ObservableObject, Codable {
    
    enum CodingKeys: CodingKey {
        case routines
    }
    
    @Published var routines: [Routine] {
        didSet {
            saveToCloud()
//            print("DIDSET FIRED!!")
//            if let encoded = try? JSONEncoder().encode(routines) {
//                UserDefaults.standard.set(encoded, forKey: "UserDataFirstAttempt")
//            }
//            else {
//                print("There was an issue encoding values.")
//            }
        }
    }
    
    init() {
        let store = NSUbiquitousKeyValueStore.default

        if let data = store.data(forKey: "UserDataRoutines") {
            print("Data exists in iCloud: \(String(data: data, encoding: .utf8) ?? "Invalid JSON")")
        } else {
            print("No data found in iCloud.")
        }
        

        if let data = NSUbiquitousKeyValueStore.default.data(forKey: "UserDataRoutines") {
            if let decoded = try? JSONDecoder().decode([Routine].self, from: data){
                self.routines = decoded
                return
            }
        }else if let localData = UserDefaults.standard.data(forKey: "UserDataFirstAttempt") {
            if let decoded = try? JSONDecoder().decode([Routine].self, from: localData){
                self.routines = decoded
                saveToCloud()
                UserDefaults.standard.removeObject(forKey: "UserDataFirstAttempt")
                return
            }
        }
        
//        if let data = UserDefaults.standard.data(forKey: "UserDataFirstAttempt") {
//            if let decoded = try? JSONDecoder().decode([Routine].self, from: data) {
//                self.routines = decoded
//                return
//            }
//        }
//
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
    
    private func saveToCloud() {
        if let encoded = try? JSONEncoder().encode(routines) {
            let store = NSUbiquitousKeyValueStore.default
            store.set(encoded, forKey: "UserDataRoutines")
            store.synchronize()
        } else{
            print("There was an issue encoding values.")
        }
        
        let store = NSUbiquitousKeyValueStore.default

        if let data = store.data(forKey: "UserDataRoutines") {
            print("Data exists in iCloud: \(String(data: data, encoding: .utf8) ?? "Invalid JSON")")
        } else {
            print("No data found in iCloud.")
        }
    }
    
    //  Handles data updates from iCloud
    func observeCloudChanges() {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: nil, queue: .main) { _ in
                self.loadFromCloud()
            }
    }
    
    private func loadFromCloud()
    {
        if let data = NSUbiquitousKeyValueStore.default.data(forKey: "UserDataRoutines") {
            if let decoded = try? JSONDecoder().decode([Routine].self, from: data){
                DispatchQueue.main.async {
                    self.routines = decoded
                }
            }
        }
    }
    
    // Gets user data JSON
    static func getUserDataJson(completion: @escaping (Data?) -> Void) {
        let store = NSUbiquitousKeyValueStore.default
        if let data = store.data(forKey: "UserDataRoutines") {
            completion(data)
        } else {
            completion(nil)
        }
    }
    
//    //  gets user data json
//    static func getUserDataJson(completion: @escaping (Data?) -> Void) {
//        if let data = UserDefaults.standard.data(forKey: "UserDataFirstAttempt"){
//            completion(data)
//        }
//        else{
//            completion(nil)
//        }
//    }
    
}
