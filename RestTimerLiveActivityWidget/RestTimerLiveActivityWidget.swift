//
//  RestTimerLiveActivityWidget.swift
//  RestTimerLiveActivityWidget
//

import ActivityKit
import SwiftUI
import WidgetKit

private enum LiveActivityColors {
    static let accent = Color(red: 221/255, green: 69/255, blue: 36/255)
    static let iconBackground = accent.opacity(0.18)
}

@main
struct RestTimerLiveActivityWidgetBundle: WidgetBundle {
    var body: some Widget {
        RestTimerLiveActivityWidget()
    }
}

struct RestTimerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestTimerActivityAttributes.self) { context in
            RestTimerLiveActivityLockScreenView(context: context)
                .activityBackgroundTint(Color(.secondarySystemGroupedBackground))
                .activitySystemActionForegroundColor(.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 3) {
                        Label("Rest", systemImage: "timer")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)

                        Text(context.attributes.workoutName)
                            .font(.headline.weight(.bold))
                            .lineLimit(1)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    RestTimerLiveActivityTimeView(context: context, size: 28)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(
                        value: progressValue(for: context),
                        total: Double(max(1, context.attributes.intervalSeconds))
                    )
                    .tint(LiveActivityColors.accent)
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(LiveActivityColors.accent)
            } compactTrailing: {
                RestTimerLiveActivityTimeView(context: context, size: 15)
                    .frame(width: 44, alignment: .trailing)
            } minimal: {
                Image(systemName: "timer")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(LiveActivityColors.accent)
            }
        }
    }

    private func progressValue(for context: ActivityViewContext<RestTimerActivityAttributes>) -> Double {
        if context.state.isPaused {
            return Double(max(0, context.attributes.intervalSeconds - context.state.remainingSeconds))
        }

        let remaining = max(0, context.state.endsAt.timeIntervalSinceNow)
        return Double(context.attributes.intervalSeconds) - remaining
    }
}

private struct RestTimerLiveActivityLockScreenView: View {
    let context: ActivityViewContext<RestTimerActivityAttributes>

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 12) {
                Image(systemName: "timer")
                    .font(.system(size: 23, weight: .black, design: .rounded))
                    .foregroundStyle(LiveActivityColors.accent)
                    .frame(width: 44, height: 44)
                    .background(LiveActivityColors.iconBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 1) {
                    Text("Rest Timer")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text(context.attributes.workoutName)
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 12)

                RestTimerLiveActivityTimeView(context: context, size: 33)
                    .frame(width: 112, alignment: .trailing)
            }
            .padding(.leading, 12)
            .padding(.trailing, -12)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
        }
        .frame(height: 54)
    }
}

private struct RestTimerLiveActivityTimeView: View {
    let context: ActivityViewContext<RestTimerActivityAttributes>
    let size: CGFloat

    var body: some View {
        Group {
            if context.state.isPaused {
                Text(formatTime(context.state.remainingSeconds))
            } else {
                Text(timerInterval: Date()...context.state.endsAt, countsDown: true)
            }
        }
        .font(.system(size: size, weight: .black, design: .rounded))
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = max(0, seconds) / 60
        let seconds = max(0, seconds) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}
