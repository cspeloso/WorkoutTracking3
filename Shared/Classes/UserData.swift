import Foundation
import Combine
import WatchConnectivity
#if canImport(UIKit)
import UIKit
#endif

#if canImport(WatchKit)
import WatchKit
#endif

final class UserData: NSObject, ObservableObject, Codable {
    static let shared = UserData()

    private static let routinesCloudKey = "UserDataRoutines"
    private static let routinesUpdatedAtKey = "UserDataRoutinesUpdatedAt"
    private static let legacyLocalKey = "UserDataFirstAttempt"
    private static let watchConnectivityRoutinesKey = "routinesData"
    private static let watchConnectivityUpdatedAtKey = "routinesUpdatedAt"

    private var saveTask: DispatchWorkItem?
    private var isApplyingRemoteUpdate = false
    private var lastUpdatedAt: TimeInterval = 0

    enum CodingKeys: CodingKey {
        case routines
    }

    @Published var routines: [Routine] {
        didSet {
            if oldValue != routines && !isApplyingRemoteUpdate {
                lastUpdatedAt = Date().timeIntervalSince1970
                save()
            }
        }
    }

    private override init() {
        self.routines = []
        super.init()

        print("UserData singleton init at \(Date())")

        configureWatchConnectivity()

        if let stored = Self.loadFromCloud() {
            self.lastUpdatedAt = stored.updatedAt
            self.isApplyingRemoteUpdate = true
            self.routines = stored.routines
            self.isApplyingRemoteUpdate = false
            print("Loaded user data from iCloud")
            if stored.shouldPromoteTimestamp {
                self.lastUpdatedAt = Date().timeIntervalSince1970
                saveToCloud()
            }
        } else if let stored = Self.loadFromLocalDefaults() {
            self.lastUpdatedAt = stored.updatedAt
            self.isApplyingRemoteUpdate = true
            self.routines = stored.routines
            self.isApplyingRemoteUpdate = false
            print("Migrated local user data to shared storage")
            if stored.shouldPromoteTimestamp {
                self.lastUpdatedAt = Date().timeIntervalSince1970
            }
            save()
            UserDefaults.standard.removeObject(forKey: Self.legacyLocalKey)
        } else {
            print("No user data found locally or in iCloud")
        }

        observeCloudChanges()
        observeAppLifecycle()
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.routines = try container.decode([Routine].self, forKey: .routines)
        super.init()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(routines, forKey: .routines)
    }

    func save() {
        saveToLocalDefaults()
        saveToCloud()
        sendToPairedDevice()
    }

    func saveToCloud() {
        saveTask?.cancel()

        let task = DispatchWorkItem {
            do {
                if self.lastUpdatedAt <= 0 {
                    self.lastUpdatedAt = Date().timeIntervalSince1970
                }

                let encoded = try JSONEncoder().encode(self.routines)
                let store = NSUbiquitousKeyValueStore.default
                store.set(encoded, forKey: Self.routinesCloudKey)
                store.set(self.lastUpdatedAt, forKey: Self.routinesUpdatedAtKey)
                store.synchronize()
                self.saveToLocalDefaults()

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    if let data = store.data(forKey: Self.routinesCloudKey) {
                        print("Saved user data to iCloud. Data size: \(data.count) bytes")
                    } else {
                        print("iCloud did not return saved user data")
                    }
                }
            } catch {
                print("Failed to encode routines: \(error.localizedDescription)")
            }
        }

        saveTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: task)
    }

    private func saveToLocalDefaults() {
        do {
            if lastUpdatedAt <= 0 {
                lastUpdatedAt = Date().timeIntervalSince1970
            }

            let encoded = try JSONEncoder().encode(routines)
            UserDefaults.standard.set(encoded, forKey: Self.legacyLocalKey)
            UserDefaults.standard.set(lastUpdatedAt, forKey: Self.routinesUpdatedAtKey)
        } catch {
            print("Failed to encode local routines backup: \(error.localizedDescription)")
        }
    }

    func observeCloudChanges() {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: nil,
            queue: .main
        ) { _ in
            print("iCloud user data changed")
            self.loadFromCloud()
        }
    }

    private func loadFromCloud() {
        if let stored = Self.loadFromCloud() {
            applyRemoteRoutines(
                stored.routines,
                updatedAt: stored.updatedAt,
                source: "iCloud",
                shouldPromoteTimestamp: stored.shouldPromoteTimestamp
            )
        } else {
            print("No data found in iCloud.")
        }
    }

    static func getUserDataJson(completion: @escaping (Data?) -> Void) {
        let store = NSUbiquitousKeyValueStore.default
        store.synchronize()

        if let data = store.data(forKey: routinesCloudKey) {
            completion(data)
        } else if let data = UserDefaults.standard.data(forKey: legacyLocalKey) {
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

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIScene.willEnterForegroundNotification,
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
        print("App became active. Fetching latest shared user data.")
        loadFromCloud()
        requestPairedDeviceSync()
    }

    private static func loadFromCloud() -> StoredRoutines? {
        let store = NSUbiquitousKeyValueStore.default
        store.synchronize()

        guard let data = store.data(forKey: routinesCloudKey) else {
            return nil
        }

        guard let routines = try? JSONDecoder().decode([Routine].self, from: data) else {
            return nil
        }

        let cloudUpdatedAt = store.double(forKey: routinesUpdatedAtKey)
        let localUpdatedAt = UserDefaults.standard.double(forKey: routinesUpdatedAtKey)
        let updatedAt = max(cloudUpdatedAt, localUpdatedAt)
        return StoredRoutines(
            routines: routines,
            updatedAt: updatedAt,
            shouldPromoteTimestamp: updatedAt <= 0 && !routines.isEmpty
        )
    }

    private static func loadFromLocalDefaults() -> StoredRoutines? {
        guard let data = UserDefaults.standard.data(forKey: legacyLocalKey) else {
            return nil
        }

        guard let routines = try? JSONDecoder().decode([Routine].self, from: data) else {
            return nil
        }

        let updatedAt = UserDefaults.standard.double(forKey: routinesUpdatedAtKey)
        return StoredRoutines(
            routines: routines,
            updatedAt: updatedAt,
            shouldPromoteTimestamp: updatedAt <= 0 && !routines.isEmpty
        )
    }

    private func applyRemoteRoutines(
        _ remoteRoutines: [Routine],
        updatedAt remoteUpdatedAt: TimeInterval,
        source: String,
        shouldPromoteTimestamp: Bool = false
    ) {
        DispatchQueue.main.async {
            if !self.shouldApplyRemoteRoutines(remoteRoutines, updatedAt: remoteUpdatedAt, source: source) {
                return
            }

            guard self.routines != remoteRoutines else {
                if remoteUpdatedAt > self.lastUpdatedAt {
                    self.lastUpdatedAt = remoteUpdatedAt
                    UserDefaults.standard.set(remoteUpdatedAt, forKey: Self.routinesUpdatedAtKey)
                }
                print("Shared user data from \(source) already matches local data")
                return
            }

            print("Updating routines from \(source)")
            self.lastUpdatedAt = shouldPromoteTimestamp || remoteUpdatedAt <= 0
                ? Date().timeIntervalSince1970
                : remoteUpdatedAt
            self.isApplyingRemoteUpdate = true
            self.routines = remoteRoutines
            self.isApplyingRemoteUpdate = false
            self.saveToCloud()
        }
    }

    private func shouldApplyRemoteRoutines(
        _ remoteRoutines: [Routine],
        updatedAt remoteUpdatedAt: TimeInterval,
        source: String
    ) -> Bool {
        if remoteUpdatedAt > 0 && lastUpdatedAt > 0 && remoteUpdatedAt < lastUpdatedAt {
            print("Ignoring stale shared user data from \(source)")
            return false
        }

        if remoteUpdatedAt <= 0 && !routines.isEmpty {
            print("Ignoring unstamped shared user data from \(source)")
            return false
        }

        return true
    }

    private struct StoredRoutines {
        let routines: [Routine]
        let updatedAt: TimeInterval
        let shouldPromoteTimestamp: Bool
    }
}

// MARK: - WatchConnectivity

extension UserData: WCSessionDelegate {
    private var session: WCSession? {
        WCSession.isSupported() ? WCSession.default : nil
    }

    private func configureWatchConnectivity() {
        guard let session else {
            return
        }

        session.delegate = self
        session.activate()
    }

    private func sendToPairedDevice() {
        guard let session else {
            return
        }

        do {
            let encoded = try JSONEncoder().encode(routines)
            let payload: [String: Any] = [
                Self.watchConnectivityRoutinesKey: encoded,
                Self.watchConnectivityUpdatedAtKey: lastUpdatedAt
            ]

            if session.activationState == .activated {
                try? session.updateApplicationContext(payload)

                if session.isReachable {
                    session.sendMessage(payload, replyHandler: nil) { error in
                        print("Could not send live user data update: \(error.localizedDescription)")
                    }
                } else {
                    session.transferUserInfo(payload)
                }
            }
        } catch {
            print("Failed to encode routines for WatchConnectivity: \(error.localizedDescription)")
        }
    }

    private func requestPairedDeviceSync() {
        guard let session, session.activationState == .activated, session.isReachable else {
            return
        }

        session.sendMessage(["requestUserDataSync": true]) { [weak self] response in
            self?.handleWatchConnectivityPayload(response, source: "paired device response")
        } errorHandler: { error in
            print("Could not request paired device sync: \(error.localizedDescription)")
        }
    }

    private func handleWatchConnectivityPayload(_ payload: [String: Any], source: String) {
        if payload["requestUserDataSync"] as? Bool == true {
            sendToPairedDevice()
            return
        }

        guard let data = payload[Self.watchConnectivityRoutinesKey] as? Data,
              let decoded = try? JSONDecoder().decode([Routine].self, from: data) else {
            return
        }

        let updatedAt = payload[Self.watchConnectivityUpdatedAtKey] as? TimeInterval ?? 0
        applyRemoteRoutines(decoded, updatedAt: updatedAt, source: source)
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error {
            print("WatchConnectivity activation failed: \(error.localizedDescription)")
            return
        }

        print("WatchConnectivity activated: \(activationState.rawValue)")
        sendToPairedDevice()
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handleWatchConnectivityPayload(applicationContext, source: "paired device application context")
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleWatchConnectivityPayload(message, source: "paired device message")
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        if message["requestUserDataSync"] as? Bool == true,
           let encoded = try? JSONEncoder().encode(routines) {
            replyHandler([
                Self.watchConnectivityRoutinesKey: encoded,
                Self.watchConnectivityUpdatedAtKey: lastUpdatedAt
            ])
            return
        }

        handleWatchConnectivityPayload(message, source: "paired device message")
        replyHandler([:])
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        handleWatchConnectivityPayload(userInfo, source: "paired device background transfer")
    }
}

#if os(iOS)
extension UserData {
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WatchConnectivity session became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
#endif
