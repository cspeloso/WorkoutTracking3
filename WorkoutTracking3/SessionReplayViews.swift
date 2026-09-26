import SwiftUI
import Clarity

/// A dedicated native text view gives Clarity an explicit UIView to unmask.
/// Use only for the Home summaries the user agreed to make visible, never
/// routine names, free text, or individual workout values.
struct ReplayVisibleSummaryText: UIViewRepresentable {
    let text: String
    var pointSize: CGFloat = 17
    var weight: UIFont.Weight = .regular
    var textStyle: UIFont.TextStyle = .body
    var rounded = false
    var color: UIColor = .label
    var centered = false
    var visibleInReplay = true

    func makeUIView(context: Context) -> ReplaySummaryLabel {
        let label = ReplaySummaryLabel()
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.adjustsFontForContentSizeCategory = true
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }

    func updateUIView(_ label: ReplaySummaryLabel, context: Context) {
        let base = UIFont.systemFont(ofSize: pointSize, weight: weight)
        let descriptor = rounded ? (base.fontDescriptor.withDesign(.rounded) ?? base.fontDescriptor) : base.fontDescriptor
        label.font = UIFontMetrics(forTextStyle: textStyle).scaledFont(for: UIFont(descriptor: descriptor, size: pointSize))
        label.text = text
        label.textColor = color
        label.textAlignment = centered ? .center : .left
        label.visibleInReplay = visibleInReplay
        label.accessibilityIdentifier = visibleInReplay ? "workitoutReplaySummary" : nil
        label.applyReplayVisibility()
    }
}

final class ReplaySummaryLabel: UILabel {
    var visibleInReplay = false

    override func didMoveToWindow() {
        super.didMoveToWindow()
        applyReplayVisibility()
    }

    func applyReplayVisibility() {
        if visibleInReplay { ClaritySDK.unmaskView(self) }
        else { ClaritySDK.maskView(self) }
    }
}

extension View {
    /// Also apply to separately presented sheets/covers, which have their own roots.
    func sessionReplayProtected() -> some View {
        modifier(SessionReplayProtection())
    }

    func sessionReplayConsentSheet(isPresented: Binding<Bool>, source: SessionReplayService.Source) -> some View {
        modifier(SessionReplayConsentSheet(isPresented: isPresented, source: source))
    }

    /// Only use on fixed interface labels, never containers or personal values.
    func sessionReplayPublicLabel() -> some View {
        clarityUnmask()
    }

    /// Explicitly approved Home-screen weekdays and aggregate counts only.
    @ViewBuilder
    func sessionReplayVisibleSummary(_ visible: Bool = true) -> some View {
        if visible { clarityUnmask() }
        else { self }
    }

    @ViewBuilder
    func sessionReplayMasked(_ masked: Bool = true) -> some View {
        if masked { clarityMask() }
        else { self }
    }
}

private struct SessionReplayProtection: ViewModifier {
    func body(content: Content) -> some View {
        // Clarity's project-level Balanced mode handles sensitive values. Do
        // not mask the root: a root mask wins over descendant unmask calls and
        // makes every interface label unreadable in replay. Sensitive inputs
        // and user-created names are masked explicitly at their own views.
        content
    }
}

private struct SessionReplayConsentSheet: ViewModifier {
    @Binding var isPresented: Bool
    let source: SessionReplayService.Source
    @State private var didRespond = false

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented, onDismiss: {
            if !didRespond { SessionReplayService.shared.dismissPrompt(source: source) }
            didRespond = false
        }) {
            SessionReplayConsentView(source: source) { didRespond = true }
        }
    }
}

struct SessionReplayConsentView: View {
    let source: SessionReplayService.Source
    let onResponse: () -> Void
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var replay = SessionReplayService.shared

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Image(systemName: "hand.raised.fill")
                        .font(.largeTitle)
                        .foregroundColor(AppColors.accent)
                    Text("Help improve Work It Out")
                        .font(.largeTitle.weight(.bold))
                    Text("Allow optional session replay?")
                        .font(.title3.weight(.bold))
                    SessionReplayExplanation()
                    VStack(alignment: .leading, spacing: 0) {
                        Button("Allow session replay") {
                            onResponse()
                            replay.choose(.allowed, source: source)
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .font(.headline)
                        .tint(AppColors.accent)
                        Button {
                            onResponse()
                            replay.choose(.declined, source: source)
                            dismiss()
                        } label: {
                            Text("Don't allow")
                                .font(.footnote)
                                .frame(minHeight: 44, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .sessionReplayProtected()
    }
}

struct SessionReplayExplanation: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Microsoft Clarity collects taps, scrolling, screen layout, and device information to help us understand how the app is used and improve it. These interactions are sent to Microsoft to create session replays and heatmaps.")
            Text("Custom names, text you enter, detailed workout values, and personal images are masked. Interface labels, app icons, and Home-screen weekdays and summary counts remain visible, including routine, exercise, and logged-set counts. We do not use these replays for advertising.")
                .bold()
            Text("This is optional. You can use every feature without it, and turn it off at any time in Settings. Turning it off stops future capture; it does not delete replays already sent.")
            Link("Microsoft Privacy Statement", destination: URL(string: "https://privacy.microsoft.com/privacystatement")!)
        }
        .font(.subheadline)
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct SessionReplaySettings: View {
    @ObservedObject private var replay = SessionReplayService.shared
    @State private var showConsent = false

    var body: some View {
        if replay.isSupported {
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle("Privacy")
                VStack(alignment: .leading, spacing: 14) {
                    Toggle("Share session replays", isOn: Binding(
                        get: { replay.consent == .allowed },
                        set: { enabled in
                            if enabled { showConsent = true }
                            else { replay.choose(.declined, source: .settings) }
                        }
                    ))
                    .font(.headline)
                    .tint(AppColors.accent)
                    SessionReplayExplanation()
                    #if DEBUG
                    Text("Clarity: \(replay.hasSessionStarted ? "session started" : "no session confirmed") • \(ProcessInfo.processInfo.operatingSystemVersionString)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Text("A started session does not confirm upload. Test on Wi-Fi; Clarity currently lists support for iOS 16–26. Check the Xcode console for Clarity and SessionReplay messages.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    #endif
                    if replay.initializationFailed {
                        Text("Session replay could not start. Turn it off and on to try again.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(18)
                .background(AppColors.card)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border))
                .cornerRadius(8)
            }
            .sessionReplayConsentSheet(isPresented: $showConsent, source: .settings)
        }
    }
}
