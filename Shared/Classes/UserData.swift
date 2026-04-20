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
    private static let weightUnitKey = "UserDataWeightUnit"
    private static let legacyLocalKey = "UserDataFirstAttempt"
    private static let watchConnectivityRoutinesKey = "routinesData"
    private static let watchConnectivityUpdatedAtKey = "routinesUpdatedAt"
    private static let watchConnectivityWeightUnitKey = "weightUnit"
    private static let deletedRoutinesBackupKey = "DeletedUserDataRoutinesBackup"
    private static let deletedRoutinesBackupCreatedAtKey = "DeletedUserDataRoutinesBackupCreatedAt"
    private static let deletedRoutinesBackupRetention: TimeInterval = 30 * 24 * 60 * 60

    private var saveTask: DispatchWorkItem?
    private var isApplyingRemoteUpdate = false
    private var isApplyingRemoteSettingsUpdate = false
    private var lastUpdatedAt: TimeInterval = 0
    @Published private(set) var deletedDataBackupInfo: DeletedDataBackupInfo?
    @Published var weightUnit: WeightUnit {
        didSet {
            if oldValue != weightUnit && !isApplyingRemoteSettingsUpdate {
                saveWeightUnit()
            }
        }
    }

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
        self.deletedDataBackupInfo = nil
        self.weightUnit = Self.loadWeightUnit()
        super.init()

        print("UserData singleton init at \(Date())")

        configureWatchConnectivity()

        if let stored = Self.loadBestStoredRoutines() {
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

        refreshDeletedDataBackupInfo()
        observeCloudChanges()
        observeAppLifecycle()
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.routines = try container.decode([Routine].self, forKey: .routines)
        self.deletedDataBackupInfo = nil
        self.weightUnit = .pounds
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

    func deleteAllDataKeepingRestoreBackup() {
        refreshDeletedDataBackupInfo()

        if !routines.isEmpty {
            saveDeletedDataBackup(routines)
        }

        lastUpdatedAt = Date().timeIntervalSince1970
        routines = []
    }

    func restoreDeletedDataBackup() {
        refreshDeletedDataBackupInfo()

        guard let stored = Self.loadDeletedDataBackup() else {
            return
        }

        clearDeletedDataBackup()
        lastUpdatedAt = Date().timeIntervalSince1970
        routines = stored.routines
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
            self.loadWeightUnitFromCloud()
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
        refreshDeletedDataBackupInfo()
        loadFromCloud()
        loadWeightUnitFromCloud()
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

        let updatedAt = store.double(forKey: routinesUpdatedAtKey)
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

    private static func loadBestStoredRoutines() -> StoredRoutines? {
        let cloudStored = loadFromCloud()
        let localStored = loadFromLocalDefaults()

        switch (cloudStored, localStored) {
        case let (cloud?, local?):
            return local.updatedAt > cloud.updatedAt ? local : cloud
        case let (cloud?, nil):
            return cloud
        case let (nil, local?):
            return local
        case (nil, nil):
            return nil
        }
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

enum WeightUnit: String, CaseIterable, Codable, Identifiable {
    case pounds
    case kilograms

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pounds:
            return "Pounds"
        case .kilograms:
            return "Kilograms"
        }
    }

    var abbreviatedTitle: String {
        switch self {
        case .pounds:
            return "lb"
        case .kilograms:
            return "kg"
        }
    }

    var largeStep: Double {
        switch self {
        case .pounds:
            return 5
        case .kilograms:
            return 2.5
        }
    }

    var smallStep: Double {
        switch self {
        case .pounds:
            return 2.5
        case .kilograms:
            return 1
        }
    }

    func displayWeight(fromStoredPounds pounds: Double) -> Double {
        switch self {
        case .pounds:
            return pounds
        case .kilograms:
            return pounds * 0.45359237
        }
    }

    func storedPounds(fromDisplayWeight weight: Double) -> Double {
        switch self {
        case .pounds:
            return weight
        case .kilograms:
            return weight / 0.45359237
        }
    }

    func displayVolume(fromStoredPoundVolume volume: Double) -> Double {
        switch self {
        case .pounds:
            return volume
        case .kilograms:
            return volume * 0.45359237
        }
    }

    func formattedWeight(fromStoredPounds pounds: Double) -> String {
        "\(displayWeight(fromStoredPounds: pounds).formatted(.number.precision(.fractionLength(0...1)))) \(abbreviatedTitle)"
    }

    func formattedVolume(fromStoredPoundVolume volume: Double) -> String {
        displayVolume(fromStoredPoundVolume: volume).formatted(.number.precision(.fractionLength(0...1)))
    }
}

// MARK: - Weight Unit Preference

extension UserData {
    static func hasSavedWeightUnitPreference() -> Bool {
        let store = NSUbiquitousKeyValueStore.default
        store.synchronize()

        return store.string(forKey: weightUnitKey) != nil ||
            UserDefaults.standard.string(forKey: weightUnitKey) != nil
    }

    func setWeightUnitPreference(_ unit: WeightUnit) {
        weightUnit = unit
        saveWeightUnit()
    }

    private static func loadWeightUnit() -> WeightUnit {
        let store = NSUbiquitousKeyValueStore.default
        store.synchronize()

        if let rawValue = store.string(forKey: weightUnitKey),
           let unit = WeightUnit(rawValue: rawValue) {
            UserDefaults.standard.set(rawValue, forKey: weightUnitKey)
            return unit
        }

        if let rawValue = UserDefaults.standard.string(forKey: weightUnitKey),
           let unit = WeightUnit(rawValue: rawValue) {
            return unit
        }

        return .pounds
    }

    private func saveWeightUnit() {
        let rawValue = weightUnit.rawValue
        let store = NSUbiquitousKeyValueStore.default
        UserDefaults.standard.set(rawValue, forKey: Self.weightUnitKey)
        store.set(rawValue, forKey: Self.weightUnitKey)
        store.synchronize()
        sendToPairedDevice()
    }

    private func loadWeightUnitFromCloud() {
        let unit = Self.loadWeightUnit()
        guard unit != weightUnit else {
            return
        }

        isApplyingRemoteSettingsUpdate = true
        weightUnit = unit
        isApplyingRemoteSettingsUpdate = false
    }

    private func applyRemoteWeightUnit(_ rawValue: String?) {
        guard let rawValue,
              let unit = WeightUnit(rawValue: rawValue),
              unit != weightUnit else {
            return
        }

        isApplyingRemoteSettingsUpdate = true
        weightUnit = unit
        isApplyingRemoteSettingsUpdate = false
        saveWeightUnit()
    }
}

struct DeletedDataBackupInfo {
    let createdAt: Date
    let expiresAt: Date
    let routineCount: Int

    var daysRemaining: Int {
        max(0, Int(ceil(expiresAt.timeIntervalSinceNow / (24 * 60 * 60))))
    }
}

// MARK: - Deleted Data Restore Backup

extension UserData {
    private struct DeletedDataBackup {
        let routines: [Routine]
        let createdAt: Date

        var expiresAt: Date {
            createdAt.addingTimeInterval(UserData.deletedRoutinesBackupRetention)
        }

        var isExpired: Bool {
            Date() >= expiresAt
        }
    }

    private func saveDeletedDataBackup(_ routines: [Routine]) {
        do {
            let encoded = try JSONEncoder().encode(routines)
            let createdAt = Date().timeIntervalSince1970
            let store = NSUbiquitousKeyValueStore.default

            UserDefaults.standard.set(encoded, forKey: Self.deletedRoutinesBackupKey)
            UserDefaults.standard.set(createdAt, forKey: Self.deletedRoutinesBackupCreatedAtKey)
            store.set(encoded, forKey: Self.deletedRoutinesBackupKey)
            store.set(createdAt, forKey: Self.deletedRoutinesBackupCreatedAtKey)
            store.synchronize()

            refreshDeletedDataBackupInfo()
        } catch {
            print("Failed to encode deleted data backup: \(error.localizedDescription)")
        }
    }

    private func refreshDeletedDataBackupInfo() {
        if let stored = Self.loadDeletedDataBackup() {
            deletedDataBackupInfo = DeletedDataBackupInfo(
                createdAt: stored.createdAt,
                expiresAt: stored.expiresAt,
                routineCount: stored.routines.count
            )
        } else {
            deletedDataBackupInfo = nil
        }
    }

    private func clearDeletedDataBackup() {
        let store = NSUbiquitousKeyValueStore.default
        UserDefaults.standard.removeObject(forKey: Self.deletedRoutinesBackupKey)
        UserDefaults.standard.removeObject(forKey: Self.deletedRoutinesBackupCreatedAtKey)
        store.removeObject(forKey: Self.deletedRoutinesBackupKey)
        store.removeObject(forKey: Self.deletedRoutinesBackupCreatedAtKey)
        store.synchronize()
        deletedDataBackupInfo = nil
    }

    private static func loadDeletedDataBackup() -> DeletedDataBackup? {
        let cloudBackup = loadDeletedDataBackupFromCloud()
        let localBackup = loadDeletedDataBackupFromLocalDefaults()

        let backup: DeletedDataBackup?
        switch (cloudBackup, localBackup) {
        case let (cloud?, local?):
            backup = local.createdAt > cloud.createdAt ? local : cloud
        case let (cloud?, nil):
            backup = cloud
        case let (nil, local?):
            backup = local
        case (nil, nil):
            backup = nil
        }

        guard let backup else {
            return nil
        }

        if backup.isExpired {
            clearExpiredDeletedDataBackup()
            return nil
        }

        return backup
    }

    private static func loadDeletedDataBackupFromCloud() -> DeletedDataBackup? {
        let store = NSUbiquitousKeyValueStore.default
        store.synchronize()

        guard let data = store.data(forKey: deletedRoutinesBackupKey),
              let routines = try? JSONDecoder().decode([Routine].self, from: data) else {
            return nil
        }

        let createdAt = store.double(forKey: deletedRoutinesBackupCreatedAtKey)
        guard createdAt > 0 else {
            return nil
        }

        return DeletedDataBackup(routines: routines, createdAt: Date(timeIntervalSince1970: createdAt))
    }

    private static func loadDeletedDataBackupFromLocalDefaults() -> DeletedDataBackup? {
        guard let data = UserDefaults.standard.data(forKey: deletedRoutinesBackupKey),
              let routines = try? JSONDecoder().decode([Routine].self, from: data) else {
            return nil
        }

        let createdAt = UserDefaults.standard.double(forKey: deletedRoutinesBackupCreatedAtKey)
        guard createdAt > 0 else {
            return nil
        }

        return DeletedDataBackup(routines: routines, createdAt: Date(timeIntervalSince1970: createdAt))
    }

    private static func clearExpiredDeletedDataBackup() {
        let store = NSUbiquitousKeyValueStore.default
        UserDefaults.standard.removeObject(forKey: deletedRoutinesBackupKey)
        UserDefaults.standard.removeObject(forKey: deletedRoutinesBackupCreatedAtKey)
        store.removeObject(forKey: deletedRoutinesBackupKey)
        store.removeObject(forKey: deletedRoutinesBackupCreatedAtKey)
        store.synchronize()
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
                Self.watchConnectivityUpdatedAtKey: lastUpdatedAt,
                Self.watchConnectivityWeightUnitKey: weightUnit.rawValue
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

        applyRemoteWeightUnit(payload[Self.watchConnectivityWeightUnitKey] as? String)

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
                Self.watchConnectivityUpdatedAtKey: lastUpdatedAt,
                Self.watchConnectivityWeightUnitKey: weightUnit.rawValue
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
