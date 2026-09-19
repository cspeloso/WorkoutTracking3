# Clarity session replay

The iOS target uses Clarity 4.0.0 (pinned) with project `ykgoj50s9e`.
The Watch app and Live Activity extension do not initialize or link Clarity.
Replay is offered on iOS 16 and later.

## Consent and capture

- New installations and existing users have no replay consent by default.
- The prompt follows weight-unit onboarding. Declining or dismissing it keeps
  Clarity uninitialized. It can be enabled later in Settings → Privacy.
- Consent is stored locally under `ClaritySessionReplayConsentV1`.
- Capture begins only with opt-in and an active app scene. A visible “Session
  replay on” banner includes a Stop button. Settings also allows withdrawal.
- Withdrawal pauses capture and sends denied consent to an initialized SDK.
  Already uploaded sessions are not deleted by this action.
- SDK startup callbacks recheck the latest consent and foreground state.
- The main view, consent sheet, add-routine sheet, and workout cover are masked.
  Every current SwiftUI text input also has explicit masking. New sheets/covers
  must use `sessionReplayProtected()`; new inputs must use
  `sessionReplayMasked()`. Do not unmask personal or workout content.
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
2. Enable in Settings, accept the explanation, and confirm the banner appears.
3. Navigate through tabs, add a routine, open a workout cover, and edit fields.
   Check that modal screens have the indicator and the layout remains usable.
4. Stop capture, navigate, and relaunch. Confirm it remains off.
5. Inspect the test replay in Clarity: all text/input values and images must be
   masked, including navigation titles, alerts, and presented screens. Check
   device performance as well. Dashboard replay/masking verification has not
   been performed by the automated consent tests.

Set the project's dashboard masking to Strict as an additional safeguard.
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
or `declined`) and `source` (`initial_prompt`, `settings`, or `stop_button`).
Swiping away either consent sheet emits `session_replay_prompt_dismissed` with
`source`, without a choice event. Startup and foreground changes emit neither.
These events use the existing Firebase analytics path even when replay is off.

## Missing recordings diagnostics

Debug builds enable Clarity verbose logs. Filter the Xcode console for Clarity
or SessionReplay. Settings → Privacy also reports whether a session-start
callback was received and the device OS. “Session replay starting” means the
SDK has not yet confirmed a session; a started session does not prove upload.
Microsoft currently lists iOS 16–26 support. An iOS 27 runtime is outside that
published range even though this app can compile with the iOS 27 SDK. Test on
a supported device/runtime and an unmetered Wi-Fi network. These diagnostics
have not established the cause of any particular device's missing uploads.
