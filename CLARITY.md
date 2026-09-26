# Clarity session replay

The iOS target uses Clarity 4.0.0 (pinned) with project `ykgoj50s9e`.
The Watch app and Live Activity extension do not initialize or link Clarity.
Replay is offered on iOS 16 and later.

## Consent and capture

- New installations and existing users have no replay consent by default.
- The prompt follows weight-unit onboarding. Declining or dismissing it keeps
  Clarity uninitialized. It can be enabled later in Settings → Privacy.
- Consent is stored locally under `ClaritySessionReplayConsentV1`.
- Capture begins only with opt-in and an active app scene. Settings allows the
  user to withdraw consent and stop future capture at any time.
- Withdrawal pauses capture and sends denied consent to an initialized SDK.
  Already uploaded sessions are not deleted by this action.
- SDK startup callbacks recheck the latest consent and foreground state.
- App and presentation roots remain visible so interface text is readable.
  Every current SwiftUI text input has explicit masking. New inputs and
  user-created names must use `sessionReplayMasked()`. Do not apply masking to
  a screen or other broad container: root masking overrides descendant unmask
  calls and obscures the entire interface.
- No account identifiers, workout values, or custom events are sent explicitly
  to Clarity. Its automatic interaction/device collection still applies.
- This control is specifically for Clarity replay. Existing Firebase analytics
  behavior is unchanged; this is not a global analytics preference.

## Validation

The isolated consent tests use a fake SDK and do not send data to Microsoft:

```sh
swiftc -module-cache-path /tmp/workitout-clarity-module-cache -parse-as-library \
  WorkoutTracking3/SessionReplayService.swift Tests/SessionReplayConsentTests.swift \
  -o /tmp/workitout-session-replay-tests
/tmp/workitout-session-replay-tests
```

Before release, use a test device with synthetic workout data to verify:

1. Decline the initial prompt, relaunch, and confirm replay stays off.
2. Enable in Settings, accept the explanation, and confirm capture starts in
   the Xcode diagnostics or Clarity dashboard.
3. Navigate through tabs, add a routine, open a workout cover, and edit fields.
   Check that modal layouts remain usable and fixed labels are readable.
4. Disable capture in Settings, navigate, and relaunch. Confirm it remains off.
5. Inspect the test replay in Clarity: personal text/input values, workout details, and images must be
   masked, including those in alerts and presented screens. Fixed labels such
   as Add Set, Log Set, and section headings should be readable. Check
   device performance as well. Dashboard replay/masking verification has not
   been performed by the automated consent tests.

Keep the project's dashboard masking set to Balanced, and explicitly mask
inputs and user-created names in code.
Review capture settings and disable WebView capture if it is not needed.

## Release disclosures

The app includes a Clarity-specific explanation and Microsoft's privacy link.
Update the app's published privacy policy and App Store privacy answers before
shipping. Describe Microsoft Clarity, interaction/device collection, replay and
heatmaps, masking, the improvement purpose, withdrawal, retention, and deletion
requests using the actual project settings and Microsoft terms. This repository
does not contain an existing published policy or App Store metadata to update.

References:
- https://learn.microsoft.com/en-us/clarity/mobile-sdk/ios-sdk
- https://learn.microsoft.com/en-us/clarity/mobile-sdk/sdk-apple-appstore-privacy-guidance
- https://developer.apple.com/app-store/review/guidelines/#software-requirements

## Firebase consent events

Explicit actions emit `session_replay_consent_changed` with `choice` (`allowed`
or `declined`) and `source` (`initial_prompt` or `settings`).
Swiping away either consent sheet emits `session_replay_prompt_dismissed` with
`source`, without a choice event. Startup and foreground changes emit neither.
These events use the existing Firebase analytics path even when replay is off.

## Missing recordings diagnostics

Debug builds enable Clarity verbose logs. Filter the Xcode console for Clarity
or SessionReplay. Settings → Privacy also reports whether a session-start
callback was received and the device OS. A started session does not prove upload.
Microsoft currently lists iOS 16–26 support. An iOS 27 runtime is outside that
published range even though this app can compile with the iOS 27 SDK. Test on
a supported device/runtime and an unmetered Wi-Fi network. These diagnostics
have not established the cause of any particular device's missing uploads.

Screen roots are left visible. Fixed labels and approved Home summaries should
therefore be readable, while text inputs and user-created names are explicitly
masked. Validate this combination with Balanced dashboard masking in a fresh
test replay; masking changes are not retroactive.

## Home summary visibility

Home explicitly unmasks the current weekday, Today/Quick Start weekday badges
and weekday/exercise-count subtitles, and the four Your Stats counts (routines,
exercises, sets logged, and sets this week). RoutineCard defaults to keeping its
summary masked outside Home. Custom routine names, entered text, and detailed
workout values remain masked. The consent explanation discloses these visible
summary counts. The previously unmasked Quick Start icons are unchanged.

The approved Home card summary text now uses dedicated UILabel instances with
ClaritySDK.unmaskView rather than relying on nested SwiftUI text modifiers.
Other uses of RoutineCard explicitly mask these labels. Public labels alone
have accessibility identifier `workitoutReplaySummary`, allowing a narrowly
scoped native element rule `#workitoutReplaySummary` if needed. Do not unmask
all UILabels or entire screens to work around replay problems. Native-label
changes compile, but visibility must still be checked in an actual new replay.
