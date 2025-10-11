import Foundation
#if canImport(UIKit)
import UIKit
#endif

#if canImport(WatchKit)
import WatchKit
#endif

class UserData: ObservableObject, Codable {
    // ✅ Singleton instance
    static let shared = UserData()

    private var saveTask: DispatchWorkItem?

    enum CodingKeys: CodingKey {
        case routines
    }

    @Published var routines: [Routine] {
        didSet {
            if oldValue != routines { // ✅ Only save if there's an actual change
                saveToCloud()
            }
        }
    }

    // ✅ Private initializer (prevents multiple instances)
    private init() {
        print("🔄 UserData SINGLETON INIT at \(Date())")

        self.routines = []

        let store = NSUbiquitousKeyValueStore.default
        store.synchronize()

        if let data = store.data(forKey: "UserDataRoutines"),
           let decoded = try? JSONDecoder().decode([Routine].self, from: data) {
            print("📡 iCloud USER DATA LOCATED \(data)")
            self.routines = decoded
        } else if let localData = UserDefaults.standard.data(forKey: "UserDataFirstAttempt"),
                  let decoded = try? JSONDecoder().decode([Routine].self, from: localData) {
            print("💾 LOCAL USER DATA LOCATED")
            self.routines = decoded
            saveToCloud()
            UserDefaults.standard.removeObject(forKey: "UserDataFirstAttempt")
        } else {
            print("❌ No user data found locally or in the cloud.")
        }

        observeCloudChanges()
        observeAppLifecycle() // ✅ Added foreground detection
    }

    // ✅ Ensure decoding still works with singleton
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.routines = try container.decode([Routine].self, forKey: .routines)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(routines, forKey: .routines)
    }

    // ✅ Optimized `saveToCloud()` with iCloud sync
    func saveToCloud() {
        saveTask?.cancel() // Cancel any previous save attempt

        let task = DispatchWorkItem {
            do {
                let encoded = try JSONEncoder().encode(self.routines)
                let store = NSUbiquitousKeyValueStore.default
                store.set(encoded, forKey: "UserDataRoutines")
                
                // ✅ Force immediate sync to iCloud
                store.synchronize()

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    if let data = store.data(forKey: "UserDataRoutines") {
                        if let jsonObject = try? JSONSerialization.jsonObject(with: data),
                           let jsonString = String(data: try! JSONSerialization.data(withJSONObject: jsonObject), encoding: .utf8) {
                            print("📡 SAVED TO ICLOUD:\n\(jsonString)")
                        } else {
                            print("📡 SAVED TO ICLOUD, but could not decode JSON. Data size: \(data.count) bytes")
                        }
                    } else {
                        print("⚠️ iCloud did not save data.")
                    }
                }
            } catch {
                print("❌ Failed to encode routines: \(error.localizedDescription)")
            }
        }

        saveTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: task) // ✅ Debounced iCloud saving
    }

    func isWatchApp() -> Bool {
        #if os(watchOS)
        return true
        #else
        return false
        #endif
    }

    // ✅ Ensure Apple Watch & iOS listen for updates
    func observeCloudChanges() {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: nil,
            queue: .main
        ) { _ in
            print("🌩️ iCloud data changed, updating routines")
            self.loadFromCloud()
        }
    }

    // ✅ Prevents unnecessary iCloud reloads
    private func loadFromCloud() {

        let store = NSUbiquitousKeyValueStore.default
        store.synchronize()

        if let data = store.data(forKey: "UserDataRoutines"),
           let decoded = try? JSONDecoder().decode([Routine].self, from: data) {
            
            DispatchQueue.main.async {
                print("🔄 Updating routines from iCloud")
                self.routines = decoded
//                if self.routines != decoded { // ✅ Prevents unnecessary UI updates
//                    print("🔄 Updating routines from iCloud")
//                    self.routines = decoded
//                } else {
//                    print("✅ No changes in iCloud data, skipping update")
//                }
            }
        } else {
            print("No data found in iCloud.")
        }
    }

    // ✅ Gets user data JSON
    static func getUserDataJson(completion: @escaping (Data?) -> Void) {
        let store = NSUbiquitousKeyValueStore.default
        if let data = store.data(forKey: "UserDataRoutines") {
            completion(data)
        } else {
            completion(nil)
        }
    }

    // ✅ Observes app lifecycle to refresh data when app regains focus
    func observeAppLifecycle() {
        #if os(iOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification, // ✅ Detects foregrounding on iOS
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIScene.willEnterForegroundNotification, // ✅ Detects foregrounding in iOS 13+
            object: nil
        )
        #elseif os(watchOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: WKApplication.didBecomeActiveNotification, // ✅ Detects foregrounding on Apple Watch
            object: nil
        )
        #endif
    }

    @objc private func handleAppDidBecomeActive() {
        print("🔄 App regained focus. Fetching latest data from iCloud.")
        loadFromCloud() // ✅ Reload data when the app comes back into focus
    }
}
