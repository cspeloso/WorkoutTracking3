import Foundation
import Combine

#if os(iOS)
import Clarity
#endif

/// Keeps consent separate from the SDK so no SDK calls occur before opt-in.
@MainActor
protocol SessionReplayDriver: AnyObject {
    func initialize(onStarted: @escaping () -> Void) -> Bool
    func setConsent(_ allowed: Bool)
    func pause()
    func resume()
}

@MainActor
final class SessionReplayService: ObservableObject {
    enum Consent: String { case undecided, allowed, declined }
    enum Source: String {
        case initialPrompt = "initial_prompt"
        case settings
    }
    static let consentKey = "ClaritySessionReplayConsentV1"

    #if os(iOS)
    static let shared = SessionReplayService(driver: ClarityReplayDriver()) { choice, source in
        var parameters: [String: Any] = [AppAnalytics.Param.source: source.rawValue]
        if let choice { parameters[AppAnalytics.Param.choice] = choice.rawValue }
        AppAnalytics.log(
            choice == nil ? AppAnalytics.Event.sessionReplayPromptDismissed : AppAnalytics.Event.sessionReplayConsentChanged,
            parameters: parameters
        )
    }
    #endif

    @Published private(set) var consent: Consent
    @Published private(set) var isCaptureEnabled = false
    @Published private(set) var initializationFailed = false
    @Published private(set) var hasSessionStarted = false

    private let defaults: UserDefaults
    private let driver: SessionReplayDriver
    private let logChoice: (Consent?, Source) -> Void
    private var hasInitialized = false
    private var isActive = false

    init(defaults: UserDefaults = .standard, driver: SessionReplayDriver, logChoice: @escaping (Consent?, Source) -> Void = { _, _ in }) {
        self.defaults = defaults
        self.driver = driver
        self.logChoice = logChoice
        consent = defaults.string(forKey: Self.consentKey).flatMap(Consent.init(rawValue:)) ?? .undecided
    }

    var isSupported: Bool {
        if #available(iOS 16, *) { return true }
        return false
    }

    func choose(_ consent: Consent, source: Source? = nil) {
        self.consent = consent
        defaults.set(consent.rawValue, forKey: Self.consentKey)
        updateCapture()
        if let source, consent != .undecided { logChoice(consent, source) }
    }

    func dismissPrompt(source: Source) {
        // Dismissal is not an explicit deny and must not emit a choice event.
        if consent == .undecided { choose(.declined) }
        logChoice(nil, source)
    }

    /// Called from the visible root to keep capture aligned with app activity.
    func setActive(_ active: Bool) {
        isActive = active
        updateCapture()
    }

    private func updateCapture() {
        let shouldCapture = consent == .allowed && isActive && isSupported
        guard shouldCapture else {
            if hasInitialized {
                driver.pause()
                if consent != .allowed { driver.setConsent(false) }
            }
            isCaptureEnabled = false
            return
        }

        isCaptureEnabled = true
        initializationFailed = false
        if !hasInitialized {
            hasInitialized = driver.initialize { [weak self] in
                // Initialization is asynchronous: recheck consent in case it
                // was withdrawn while the SDK was starting.
                guard let self else { return }
                self.hasSessionStarted = true
                self.applyCurrentChoice()
            }
            if !hasInitialized {
                isCaptureEnabled = false
                initializationFailed = true
                return
            }
        }
        applyCurrentChoice()
    }

    private func applyCurrentChoice() {
        driver.setConsent(consent == .allowed)
        if consent == .allowed && isActive && isSupported {
            driver.resume()
        } else {
            driver.pause()
        }
    }
}

#if os(iOS)
@MainActor
private final class ClarityReplayDriver: SessionReplayDriver {
    func initialize(onStarted: @escaping () -> Void) -> Bool {
        #if DEBUG
        let config = ClarityConfig(projectId: "ykgoj50s9e", logLevel: .verbose)
        print("[SessionReplay] Initializing Clarity 4.0.0; OS: \(ProcessInfo.processInfo.operatingSystemVersionString)")
        #else
        let config = ClarityConfig(projectId: "ykgoj50s9e")
        #endif
        let accepted = ClaritySDK.initialize(config: config)
        #if DEBUG
        print("[SessionReplay] Initialization accepted: \(accepted). This does not confirm upload.")
        #endif
        if accepted {
            ClaritySDK.setOnSessionStartedCallback { _ in
                #if DEBUG
                print("[SessionReplay] Clarity confirmed a session started.")
                #endif
                onStarted()
            }
        }
        return accepted
    }

    func setConsent(_ allowed: Bool) {
        let accepted = ClaritySDK.consent(analyticsStorage: allowed)
        #if DEBUG
        print("[SessionReplay] Consent \(allowed) accepted: \(accepted)")
        #endif
    }
    func pause() { ClaritySDK.pause() }
    func resume() { ClaritySDK.resume() }
}
#endif
