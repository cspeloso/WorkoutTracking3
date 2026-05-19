//
//  AnalyticsService.swift
//  WorkoutTracking3
//

import Foundation

#if os(iOS) && canImport(FirebaseCore)
import FirebaseCore
#endif

#if os(iOS) && canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

enum AppAnalytics {
    enum Event {
        static let appOpened = "app_opened"
        static let onboardingCompleted = "onboarding_completed"
        static let workoutCreated = "workout_created"
        static let workoutStarted = "workout_started"
        static let exerciseAdded = "exercise_added"
        static let setLogged = "set_logged"
        static let workoutCompleted = "workout_completed"
        static let historyViewed = "history_viewed"
        static let templateCreated = "template_created"
        static let appleWatchOpened = "apple_watch_opened"
    }

    enum Param {
        static let source = "source"
        static let platform = "platform"
        static let routineCount = "routine_count"
        static let workoutCount = "workout_count"
        static let exerciseCount = "exercise_count"
        static let setCount = "set_count"
        static let loggedSetCount = "logged_set_count"
        static let hasActiveSets = "has_active_sets"
        static let hasRoutineDay = "has_routine_day"
        static let templateTitle = "template_title"
        static let weightUnit = "weight_unit"
    }

    private static var didConfigure = false
    private static var didLogAppOpened = false
    private static let watchAnalyticsEventNameKey = "analyticsEventName"
    private static let watchAnalyticsParametersKey = "analyticsParameters"

    static func configureIfNeeded() {
        guard !didConfigure else {
            return
        }

        #if os(iOS) && canImport(FirebaseCore)
        FirebaseApp.configure()
        #endif

        didConfigure = true
    }

    static func logAppOpened(platform: String, routineCount: Int? = nil) {
        guard !didLogAppOpened else {
            return
        }

        didLogAppOpened = true

        var parameters: [String: Any] = [
            Param.platform: platform
        ]

        if let routineCount {
            parameters[Param.routineCount] = routineCount
        }

        log(Event.appOpened, parameters: parameters)
    }

    static func log(_ event: String, parameters: [String: Any] = [:]) {
        #if os(iOS) && canImport(FirebaseAnalytics)
        Analytics.logEvent(event, parameters: parameters)
        #endif
    }

    static func logAppleWatchOpened() {
        let parameters: [String: Any] = [
            Param.platform: "watch"
        ]

        log(Event.appleWatchOpened, parameters: parameters)
        sendWatchAnalyticsEvent(Event.appleWatchOpened, parameters: parameters)
    }

    static func handleWatchConnectivityPayload(_ payload: [String: Any]) -> Bool {
        guard let event = payload[watchAnalyticsEventNameKey] as? String else {
            return false
        }

        let parameters = payload[watchAnalyticsParametersKey] as? [String: Any] ?? [:]
        log(event, parameters: parameters)
        return true
    }

    private static func sendWatchAnalyticsEvent(_ event: String, parameters: [String: Any]) {
        #if os(watchOS) && canImport(WatchConnectivity)
        guard WCSession.isSupported() else {
            return
        }

        let session = WCSession.default
        guard session.activationState == .activated else {
            return
        }

        let payload: [String: Any] = [
            watchAnalyticsEventNameKey: event,
            watchAnalyticsParametersKey: parameters
        ]

        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        } else {
            session.transferUserInfo(payload)
        }
        #endif
    }
}
