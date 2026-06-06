//
//  RestTimerLiveActivityController.swift
//  WorkoutTracking3
//

import Foundation

#if canImport(ActivityKit)
import ActivityKit

@available(iOS 16.1, *)
final class RestTimerLiveActivityController {
    static let shared = RestTimerLiveActivityController()

    private var activity: Activity<RestTimerActivityAttributes>?

    private init() {}

    func startOrUpdate(
        workoutName: String,
        intervalSeconds: Int,
        remainingSeconds: Int,
        isPaused: Bool
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }

        let state = RestTimerActivityAttributes.ContentState(
            endsAt: Date().addingTimeInterval(TimeInterval(max(0, remainingSeconds))),
            remainingSeconds: max(0, remainingSeconds),
            isPaused: isPaused
        )

        if let activity {
            Task {
                await update(activity, with: state)
            }
            return
        }

        let attributes = RestTimerActivityAttributes(
            workoutName: workoutName,
            intervalSeconds: max(5, intervalSeconds)
        )

        do {
            if #available(iOS 16.2, *) {
                activity = try Activity.request(
                    attributes: attributes,
                    content: ActivityContent(state: state, staleDate: state.endsAt),
                    pushType: nil
                )
            } else {
                activity = try Activity.request(
                    attributes: attributes,
                    contentState: state,
                    pushType: nil
                )
            }
        } catch {
            print("Failed to start rest timer Live Activity: \(error.localizedDescription)")
        }
    }

    func pause(remainingSeconds: Int) {
        guard let activity else {
            return
        }

        let state = RestTimerActivityAttributes.ContentState(
            endsAt: Date().addingTimeInterval(TimeInterval(max(0, remainingSeconds))),
            remainingSeconds: max(0, remainingSeconds),
            isPaused: true
        )

        Task {
            await update(activity, with: state)
        }
    }

    func end(remainingSeconds: Int = 0) {
        guard let activity else {
            return
        }

        self.activity = nil
        let state = RestTimerActivityAttributes.ContentState(
            endsAt: Date().addingTimeInterval(TimeInterval(max(0, remainingSeconds))),
            remainingSeconds: max(0, remainingSeconds),
            isPaused: true
        )

        Task {
            if #available(iOS 16.2, *) {
                await activity.end(
                    ActivityContent(state: state, staleDate: nil),
                    dismissalPolicy: .immediate
                )
            } else {
                await activity.end(using: state, dismissalPolicy: .immediate)
            }
        }
    }

    private func update(
        _ activity: Activity<RestTimerActivityAttributes>,
        with state: RestTimerActivityAttributes.ContentState
    ) async {
        if #available(iOS 16.2, *) {
            await activity.update(ActivityContent(state: state, staleDate: state.isPaused ? nil : state.endsAt))
        } else {
            await activity.update(using: state)
        }
    }
}
#endif
