//
//  UserData.swift
//  Work It Out Apple Watch Watch App
//
//  Created by Chris Peloso on 1/12/24.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

#if canImport(WatchKit)
import WatchKit
#endif

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
        store.synchronize()

        if let data = store.data(forKey: "UserDataRoutines") {
            print("Data exists in iCloud: \(String(data: data, encoding: .utf8) ?? "Invalid JSON")")
        } else {
            print("No data found in iCloud.")
        }

        if let data = NSUbiquitousKeyValueStore.default.data(forKey: "UserDataRoutines") {
            print("iCloud USER DATA LOCATED")
            if let decoded = try? JSONDecoder().decode([Routine].self, from: data){
                self.routines = decoded
                return
            }
        }else if let localData = UserDefaults.standard.data(forKey: "UserDataFirstAttempt") {
            print("LOCAL USER DATA LOCATED")
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
        defer {
            observeCloudChanges()
            observeAppLifecycle()  // ✅ Start listening for app resume events
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
    
    private func saveToCloud() {
        print("attempting to save")
        if let encoded = try? JSONEncoder().encode(routines) {
            let store = NSUbiquitousKeyValueStore.default
            store.set(encoded, forKey: "UserDataRoutines")
            store.synchronize()

            let appType = isWatchApp() ? "⌚ WATCH APP" : "📱 IOS APP"

            if let storedData = store.data(forKey: "UserDataRoutines") {
                print("\(appType) - 📡 SAVED TO ICLOUD: \(String(data: storedData, encoding: .utf8) ?? "Invalid JSON")")
            } else {
                print("\(appType) - ⚠️ iCloud did not save data.")
            }
        } else {
            print("❌ Failed to encode routines.")
        }
    }
    func isWatchApp() -> Bool {
        #if os(watchOS)
        return true
        #else
        return false
        #endif
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
        print("LOADFROMCLOUD FUNCTION CALLED")
        let store = NSUbiquitousKeyValueStore.default
        store.synchronize()
        
        if let data = NSUbiquitousKeyValueStore.default.data(forKey: "UserDataRoutines") {
            if let decoded = try? JSONDecoder().decode([Routine].self, from: data){
                DispatchQueue.main.async {
                    self.routines = decoded
                }
            }
        }
        else {
            print("No data found in iCloud.")
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

    func observeAppLifecycle() {
        #if os(iOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        #elseif os(watchOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: WKApplication.didBecomeActiveNotification,
            object: nil
        )
        #endif
    }
    
    @objc private func handleAppDidBecomeActive() {
        print("🔄 App became active. Fetching latest data from iCloud.")
        loadFromCloud()
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
