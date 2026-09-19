// Run on macOS, without initializing or contacting Clarity:
// swiftc -parse-as-library WorkoutTracking3/SessionReplayService.swift \
//   Tests/SessionReplayConsentTests.swift -o /tmp/session-replay-tests
import Foundation

@MainActor
private final class ReplaySpy: SessionReplayDriver {
    var calls: [String] = []
    var onStarted: (() -> Void)?
    var canInitialize = true
    func initialize(onStarted: @escaping () -> Void) -> Bool {
        calls.append("initialize")
        self.onStarted = onStarted
        return canInitialize
    }
    func setConsent(_ allowed: Bool) { calls.append("consent:\(allowed)") }
    func pause() { calls.append("pause") }
    func resume() { calls.append("resume") }
}

@main
struct SessionReplayConsentTests {
    @MainActor
    static func main() {
        let suite = "SessionReplayTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let driver = ReplaySpy()
        let service = SessionReplayService(defaults: defaults, driver: driver)

        service.setActive(true)
        assert(driver.calls.isEmpty, "A new install must not touch the SDK")
        service.choose(.declined)
        service.setActive(false)
        service.setActive(true)
        assert(driver.calls.isEmpty, "Declining must leave the SDK uninitialized")
        assert(SessionReplayService(defaults: defaults, driver: ReplaySpy()).consent == .declined)

        service.choose(.allowed)
        assert(driver.calls == ["initialize", "consent:true", "resume"])
        assert(service.isCaptureEnabled)
        assert(!service.hasSessionStarted, "Accepted initialization is not session confirmation")
        service.choose(.declined)
        assert(driver.calls.suffix(2) == ["pause", "consent:false"])
        assert(!service.isCaptureEnabled)
        driver.onStarted?()
        assert(service.hasSessionStarted)
        assert(driver.calls.suffix(2) == ["consent:false", "pause"], "Late startup must respect withdrawal")

        service.choose(.allowed)
        assert(driver.calls.filter { $0 == "initialize" }.count == 1)
        service.setActive(false)
        assert(driver.calls.last == "pause" && !service.isCaptureEnabled)
        driver.onStarted?()
        assert(driver.calls.last == "pause", "A late callback must not restart background capture")
        service.setActive(true)
        assert(driver.calls.last == "resume" && service.isCaptureEnabled)

        let restoredDriver = ReplaySpy()
        let restored = SessionReplayService(defaults: defaults, driver: restoredDriver)
        assert(restored.consent == .allowed && restoredDriver.calls.isEmpty)
        restored.setActive(true)
        assert(restoredDriver.calls.first == "initialize")

        defaults.set("invalid", forKey: SessionReplayService.consentKey)
        let failedDriver = ReplaySpy()
        let failed = SessionReplayService(defaults: defaults, driver: failedDriver)
        failed.setActive(true)
        assert(failed.consent == .undecided && failedDriver.calls.isEmpty)
        failedDriver.canInitialize = false
        failed.choose(.allowed)
        assert(failed.initializationFailed && !failed.isCaptureEnabled)
        assert(failedDriver.calls == ["initialize"], "Failure must not grant SDK consent or resume")
        failedDriver.canInitialize = true
        failed.setActive(true)
        assert(!failed.initializationFailed && failed.isCaptureEnabled)
        defaults.removeObject(forKey: SessionReplayService.consentKey)
        var events: [(SessionReplayService.Consent?, SessionReplayService.Source)] = []
        let analyticsDriver = ReplaySpy()
        let analytics = SessionReplayService(defaults: defaults, driver: analyticsDriver) {
            events.append(($0, $1))
        }
        analytics.setActive(true)
        assert(events.isEmpty)
        analytics.dismissPrompt(source: .initialPrompt)
        assert(events.count == 1 && events[0].0 == nil && events[0].1 == .initialPrompt)
        assert(analyticsDriver.calls.isEmpty)
        analytics.choose(.declined, source: .initialPrompt)
        analytics.choose(.allowed, source: .settings)
        analytics.choose(.declined, source: .stopButton)
        analytics.choose(.declined, source: .settings)
        assert(events.count == 5)
        assert(events[1].0 == .declined && events[1].1 == .initialPrompt)
        assert(events[2].0 == .allowed && events[2].1 == .settings)
        assert(events[3].0 == .declined && events[3].1 == .stopButton)
        assert(events[4].0 == .declined && events[4].1 == .settings)
        analytics.setActive(false)
        analytics.setActive(true)
        analyticsDriver.onStarted?()
        assert(events.count == 5, "Lifecycle and SDK callbacks must not emit choices")
        print("Passed: consent analytics sources, separate dismissal, no lifecycle duplicates.")
        print("Passed: default off, decline, persisted consent, opt-in, withdrawal, late callbacks, background pause, relaunch, invalid preference, and initialization retry.")
    }
}
