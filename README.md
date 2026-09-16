# Green Clouds

A single-screen iOS app that looks like a WhatsApp conversation and plays a scripted
sequence of voice messages. The sequence starts when the phone is picked up
(accelerometer/gyro) and resets when it's put back down. See
`/home/arran/.claude/plans/i-want-to-build-velvety-crown.md` for the full design
plan.

This repo is a single XcodeGen project (`project.yml`) that can hold multiple
apps for the Green Clouds project as separate targets, sharing most of their code:

- **GC Installation** (`GCInstallation/`) — the app documented below, built first.
- **GC Performance** (`GCPerformance/`) — a planned second app for a separate task,
  mostly the same features. Not built yet; see the comment in `project.yml` and
  "Project layout" below for how it slots in once it exists.

Code used by both apps lives in `Shared/` — Views, Services, and the `ScriptStep`
model. Each app has its own folder for what's actually specific to it: the app
entry point, `Info.plist`, `Assets.xcassets`, `Resources/Audio`, and its own
`Models/Script.swift` (the actual message content/sequence for that
app/performance).

## Media files are not tracked in git

All audio (`.m4a`, `.mp3`, `.wav`, `.caf`, `.aiff`) and image (`.png`, `.jpg`,
`.jpeg`, `.heic`, `.gif`) files are excluded via `.gitignore`, wherever they live
in the project — `Resources/Audio/`, every imageset under `Assets.xcassets/`,
anywhere. Only the asset catalogs' `Contents.json` metadata is tracked, so the
folder structure and Xcode configuration survive a clone, but the actual voice
recordings and photos do not.

This means a fresh clone builds but is missing all real media — you'll need to
supply it locally on each machine, per app:

- **Voice messages**: drop `.m4a` files into `GCInstallation/Resources/Audio/`
  (see "Replacing the placeholder audio" below).
- **Notification/UI sounds**: `alert.mp3`, `message_received.wav`,
  `message_sent.wav` also go in `GCInstallation/Resources/Audio/`.
- **Images**: the app icon (`GCInstallation/Assets.xcassets/AppIcon.appiconset/`),
  lock-screen background (`LockScreenBackground.imageset/`), avatar
  (`Avatar.imageset/`), and any photo message assets (`photo_01.imageset/`,
  etc.) each need their image file placed alongside the existing
  `Contents.json` in that imageset folder.

Run `xcodegen generate` after adding files so Xcode picks them up.

## First-time setup (on your Mac)

This project was scaffolded on a non-Mac machine, so you'll first need to get this
project folder onto your Mac (AirDrop it, `git clone` it from a remote if you've
pushed it somewhere, copy via USB drive — whatever's easiest).

### 1. Install Xcode

- Open the **App Store** app, search for **Xcode**, click **Get/Install**.
  It's a large download (10+ GB), so this can take a while.
- Once installed, open Xcode at least once from Launchpad/Applications. It will
  ask to install some additional components and your Mac password — say yes.
  Accept the license agreement if prompted.

### 2. Install the Command Line Tools (usually automatic, but verify)

Open the **Terminal** app (Cmd+Space, type "Terminal") and run:

```
xcode-select --install
```

If they're already installed it'll just tell you so — that's fine.

### 3. Install Homebrew (if you don't already have it)

In Terminal:

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Follow any instructions it prints at the end about adding `brew` to your PATH
(it usually tells you to run one or two more commands — copy/paste those).

### 4. Install XcodeGen

XcodeGen turns this project's `project.yml` into a real `.xcodeproj` — that way
the fragile Xcode project file itself never has to be hand-edited or committed.

```
brew install xcodegen
```

### 5. Generate and open the Xcode project

In Terminal, `cd` into the folder that contains `project.yml`, then:

```
cd path/to/project
xcodegen generate
open GreenClouds.xcodeproj
```

Xcode should launch with the project open, showing the file tree on the left.

### 6. Sign in with your Apple ID

- In Xcode's menu bar: **Xcode > Settings…** (older versions: **Preferences…**)
- Go to the **Accounts** tab, click the **+** in the bottom-left, choose **Apple ID**,
  and sign in with your regular Apple ID (a free account is fine — no paid
  membership needed yet).

### 7. Set the signing team on the app target

- In the left sidebar (**Project Navigator**), click the blue project icon at the
  very top named **GreenClouds**.
- In the main editor area, under **TARGETS**, select **GCInstallation** (the app
  itself is named "GC Installation"; the Xcode target/scheme has no space).
- Click the **Signing & Capabilities** tab.
- Make sure **Automatically manage signing** is checked.
- Under **Team**, choose your Apple ID (it'll show as something like
  _"Your Name (Personal Team)"_).
- Xcode will generate a provisioning profile automatically — if you see a red
  error here, click **Try Again**; it's usually transient the first time.

### 8. Connect and trust your iPhone

- Plug your iPhone into the Mac with a cable.
- Unlock the phone. A **"Trust This Computer?"** prompt appears — tap **Trust**
  and enter your passcode.
- On iOS 16+, you also need to enable **Developer Mode** on the phone (a
  security feature, separate from trusting the computer): go to
  **Settings > Privacy & Security > Developer Mode**, toggle it on, the phone
  will ask to **Restart**, and after restarting confirm **Turn On** when prompted.

### 9. Select your iPhone as the run target

In Xcode's toolbar, there's a device dropdown near the top-left (it likely shows
a simulator name like "iPhone 15 Pro" by default). Click it and choose your
actual iPhone from the list — it should appear once trusted.

### 10. Build and run

- Click the **▶ Play** button in the top-left of Xcode (or press **Cmd+R**).
- The first build takes a minute or two.
- **Expected first-run hiccup**: the build may succeed but the app fails to open
  on the phone, with an **"Untrusted Developer"** alert. On the iPhone, go to
  **Settings > General > VPN & Device Management**, tap your Apple ID under
  "Developer App", tap **Trust "[your Apple ID]"**, confirm, then go back to
  Xcode and hit **Cmd+R** again. You only need to do this once per Mac/phone pair.
- The app should now install and launch automatically on your phone.

### Notes for later

- Free-account builds expire after ~7 days — the app will simply refuse to open
  after that. Just reconnect the phone and hit Run again in Xcode; this is a
  non-issue while you're actively developing and rebuilding often.
- If Xcode ever shows a red signing error mentioning "bundle identifier" or "no
  account for team", it's almost always fixed by waiting a few seconds and
  clicking **Try Again** in Signing & Capabilities.

## Replacing the placeholder audio

`GCInstallation/Resources/Audio/message_01.m4a`, `message_02.m4a`, `message_03.m4a`
are currently **silent placeholders** (3–5s each) generated with ffmpeg, just so
the project builds and the sequence/UI can be tested end-to-end before real
recordings exist.

To use real voice messages:

1. Drop your `.m4a` recordings into `GCInstallation/Resources/Audio/`, named to
   match (or update the names in `GCInstallation/Models/Script.swift`).
2. Edit `GCInstallation/Models/Script.swift` to add/remove/reorder steps, set
   which side each bubble appears on (`isFromContact`), and the pause after each
   message (`postDelay`).
3. Re-run `xcodegen generate` if you added new files (XcodeGen needs to re-scan
   the folder), then rebuild.

## Replacing the placeholder app icon

`GCInstallation/Assets.xcassets/AppIcon.appiconset/icon-1024.png` is currently
just a solid WhatsApp-teal square, added only to satisfy Xcode's build (it
errors if `AppIcon` has no image at all). Replace `icon-1024.png` with a real
1024×1024 PNG (no transparency) before the actual performance — Xcode's
single-size icon format will scale it to every size automatically.

## Calibrating the pickup/put-down gesture

Core Motion can't be tested in the Simulator — this must be done on a real device.

1. Temporarily change the root view in `GCInstallation/GCInstallationApp.swift`
   from `RootView()` to `CalibrationView()`.
2. Run on your phone and watch the live `gravity.z` value while setting the phone
   flat on a table vs picking it up in your hand at different angles/speeds.
3. Adjust `pickedUpThreshold`, `flatThreshold`, and `requiredStableDuration` in
   `Shared/Services/MotionManager.swift` until the FLAT/PICKED UP indicator feels
   reliable and doesn't flicker.
4. Change the root view back to `RootView()`.

## Scaling to the full run (5 phones, 2 weeks)

Once the app is feature-complete and calibrated:

1. Enroll in the Apple Developer Program ($99/yr) if you haven't already.
2. Register all 5 iPhones' UDIDs (Xcode > Window > Devices and Simulators, or
   Apple Configurator 2).
3. Xcode will generate an ad-hoc provisioning profile covering those devices
   automatically once they're registered and Team is set (with Automatic signing).
4. Install onto each phone via Xcode (cable) or Apple Configurator 2.
5. Before each performance session, enable **Guided Access** on each phone
   (Settings > Accessibility > Guided Access, then triple-click the side button
   inside the app to start it) — this is what actually locks the audience member
   into the app with no way out. Also recommend enabling Do Not Disturb/Focus on
   each phone beforehand to suppress notification banners.

## Project layout

```
project.yml                  # XcodeGen config — defines the GCInstallation target
                              # (and, later, a GCPerformance target alongside it)

Shared/                      # Compiled into every app target — code, not content
  AppDelegate.swift           # Idle timer disable + portrait lock
  Models/
    ScriptStep.swift          # ScriptStep/ScriptStepKind types (the data using them
                               # lives per-app in <App>/Models/Script.swift)
    ChatItem.swift             # Unifies script bubbles + user-sent bubbles into one timeline
  Views/
    RootView.swift             # App root — switches between lock screen and chat
    LockScreenView.swift       # Fake lock screen: clock, background, notification banner
    ChatView.swift              # Chat screen, shown after tapping the notification
    ChatHeaderView.swift
    MessageBubble.swift         # Text bubble (script text steps and user-sent messages)
    ImageMessageBubble.swift    # Photo bubble (script image steps)
    VoiceMessageBubble.swift    # WhatsApp-style voice note bubble, tappable, shows progress
    ComposeBar.swift            # Bottom text input for typing/sending a message
    CalibrationView.swift       # Throwaway motion-sensor calibration harness
    DebugTriggerOverlay.swift   # Dev-only manual triggers for testing the sequence
  Services/
    MotionManager.swift         # Pickup/put-down detection (Core Motion)
    PlaybackSequencer.swift     # Drives the script, one step at a time
    SoundEffectPlayer.swift     # Sent/received/lock-screen alert sound + vibration

GCInstallation/               # Everything specific to the GC Installation app
  GCInstallationApp.swift      # App entry point (@main)
  Info.plist
  Models/
    Script.swift               # The actual message sequence for this app/performance
  Resources/Audio/              # Voice message + notification sound files
  Assets.xcassets/
    AppIcon.appiconset/          # App icon
    LockScreenBackground.imageset/ # Lock screen background photo
    Avatar.imageset/             # Chat header avatar
    photo_01.imageset/           # Example photo-message asset

GCPerformance/                # Planned second app — not built yet. Mirrors
                               # GCInstallation/'s layout above once it exists.
```

### Lock screen flow

`RootView` is now the app's actual root and owns both `MotionManager` and
`PlaybackSequencer`, switching between `LockScreenView` and `ChatView`:

1. Phone flat → plain lock screen (clock + background, no notification).
2. Phone picked up → after `notificationDelay` (default 1.2s), a "New voice
   message received" notification banner appears on the lock screen.
3. Tapping the notification calls `sequencer.start()` and switches to `ChatView`
   — the first voice message bubble is already sitting there, loaded and ready
   to tap-play (no "Sending…" phase for that one, since the notification already
   represented it arriving). Every message after the first still goes through
   the normal "Sending voice message…" phase.
4. Phone put down (whether still on the lock screen or mid-conversation) →
   after `putDownResetDelay`, the sequencer resets and the app switches back to
   the lock screen, ready for the next audience member.

Replace the image in `GCInstallation/Assets.xcassets/LockScreenBackground.imageset/`
with a real personalized photo before the performance — it's currently just a
generated placeholder gradient.

### Behavior notes

- Each step (other than the very first) shows a pulsing **"Sending voice
  message…"** status (`sendingDuration` in `PlaybackSequencer.swift`, default
  2s) before the actual bubble appears.
- Voice messages **do not autoplay** — the bubble appears paused/ready, and the
  audience member must tap the play circle to start it. Tapping again
  pauses/resumes. Only the **currently loaded** step is tappable; earlier,
  already-finished bubbles are static. The waveform fills left-to-right to show
  playback progress.
- The sequence only advances to the next step once the current one has actually
  been **played through to the end** (plus its `postDelay`) — if the audience
  member never presses play, it just waits there.
- Putting the phone down doesn't reset instantly — there's a ~2.5s grace period
  (`putDownResetDelay` in `RootView.swift`) so a brief adjustment of grip doesn't
  restart the whole piece. If it's picked back up within that window, nothing
  resets and playback continues where it left off.
- The compose bar at the bottom lets the audience member type and send their own
  message, which appears as a bubble on the right (like a normal outgoing
  message). It's purely cosmetic — it doesn't affect the script — and clears on
  reset (along with everything else in the chat) since `ChatView` unmounts
  entirely when returning to the lock screen.

## Note on WhatsApp branding

The UI is styled _in the manner of_ WhatsApp (colors, bubble shapes, voice-note
layout) but doesn't use Meta's actual logo or wordmark. That's fine for a private,
non-distributed art installation, but worth keeping in mind if the piece is ever
shown publicly or documented online.
