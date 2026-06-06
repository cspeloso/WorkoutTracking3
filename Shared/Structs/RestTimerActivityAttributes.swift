//
//  RestTimerActivityAttributes.swift
//  WorkoutTracking3
//

import Foundation

#if canImport(ActivityKit)
import ActivityKit

@available(iOS 16.1, *)
struct RestTimerActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var endsAt: Date
        var remainingSeconds: Int
        var isPaused: Bool
    }

    var workoutName: String
    var intervalSeconds: Int
}
#endif
