# Green Clouds

A single-screen iOS app that looks like a WhatsApp conversation and plays a scripted
sequence of voice messages. The sequence starts when the phone is picked up
(accelerometer/gyro) and resets when it's put back down. See
`/home/arran/.claude/plans/i-want-to-build-velvety-crown.md` for the full design
plan.

This repo is a single XcodeGen project (`project.yml`) holding two apps as
separate targets, sharing most of their code:

- **GC Installation** (`GCInstallation/`) — a lock-screen prop: starts its scripted
  message sequence when the phone is picked up, resets when it's put back down.
  See "GC Installation: lock screen flow" below.
- **GC Performance** (`GCPerformance/`) — just the chat screen, no lock screen: it's
  the performer's own control surface. Sending any message starts the scripted
  sequence; sending exactly "reset" clears the chat and sequencer back to the
  start. See "GC Performance" below.

Code used by both apps lives in `Shared/` — the chat screen itself and its bubbles,
the playback sequencer, sound effects, and the `ScriptStep`/`ChatItem` models. Code
specific to only one app (GC Installation's lock screen/motion detection, each
app's own root view) lives in that app's own folder, alongside its `Info.plist`,
`Assets.xcassets`, `Resources/Audio`, and `Models/Script.swift` (the actual message
content/sequence for that app).

## Media files are not tracked in git

All audio (`.m4a`, `.mp3`, `.wav`, `.caf`, `.aiff`) and image (`.png`, `.jpg`,
`.jpeg`, `.heic`, `.gif`) files are excluded via `.gitignore`, wherever they live
in the project — `Resources/Audio/`, every imageset under `Assets.xcassets/`,
anywhere. Only the asset catalogs' `Contents.json` metadata is tracked, so the
folder structure and Xcode configuration survive a clone, but the actual voice
recordings and photos do not.

This means a fresh clone builds but is missing all real media — you'll need to
supply it locally on each machine, per app (`GCInstallation/` and/or
`GCPerformance/`):

- **Voice messages**: drop `.m4a` files into `<App>/Resources/Audio/` (see
  "Replacing the placeholder audio" below).
- **Notification/UI sounds**: `alert.mp3`, `message_received.wav`,
  `message_sent.wav` also go in `<App>/Resources/Audio/` — both apps need their
  own copies.
- **Images**: the app icon (`<App>/Assets.xcassets/AppIcon.appiconset/`), avatar
  (`Avatar.imageset/`), and — for GC Installation only — the lock-screen
  background (`LockScreenBackground.imageset/`) and any photo message assets
  (`photo_01.imageset/`, etc.) each need their image file placed alongside the
  existing `Contents.json` in that imageset folder.

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

### 7. Set the signing team on each app target

There are two targets — **GCInstallation** and **GCPerformance** (the apps
themselves are named "GC Installation"/"GC Performance"; Xcode target/scheme
names have no space) — and signing is set per target, so repeat this for both:

- In the left sidebar (**Project Navigator**), click the blue project icon at the
  very top named **GreenClouds**.
- In the main editor area, under **TARGETS**, select **GCInstallation**.
- Click the **Signing & Capabilities** tab.
- Make sure **Automatically manage signing** is checked.
- Under **Team**, choose your Apple ID (it'll show as something like
  _"Your Name (Personal Team)"_).
- Xcode will generate a provisioning profile automatically — if you see a red
  error here, click **Try Again**; it's usually transient the first time.
- Repeat the above for the **GCPerformance** target.

The device dropdown/run button in step 10 builds whichever scheme is selected in
Xcode's toolbar (next to the device picker) — switch it between "GCInstallation"
and "GCPerformance" depending on which app you want to build and run.

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

`GCInstallation/Resources/Audio/message_01.m4a`/`message_02.m4a`/`message_03.m4a`
and `GCPerformance/Resources/Audio/message_01.m4a`/`message_02.m4a` are currently
**silent placeholders** generated with ffmpeg, just so each project builds and the
sequence/UI can be tested end-to-end before real recordings exist.

To use real voice messages, for either app:

1. Drop your `.m4a` recordings into `<App>/Resources/Audio/`, named to match (or
   update the names in `<App>/Models/Script.swift`).
2. Edit `<App>/Models/Script.swift` to add/remove/reorder steps, set which side
   each bubble appears on (`isFromContact`), and the pause after each message
   (`postDelay`).
3. Re-run `xcodegen generate` if you added new files (XcodeGen needs to re-scan
   the folder), then rebuild.

## Replacing the placeholder app icon

`GCInstallation/Assets.xcassets/AppIcon.appiconset/icon-1024.png` (solid
WhatsApp-teal) and `GCPerformance/Assets.xcassets/AppIcon.appiconset/icon-1024.png`
(solid indigo) are placeholders, added only to satisfy Xcode's build (it errors
if `AppIcon` has no image at all). Replace `icon-1024.png` with a real 1024×1024
PNG (no transparency) before the actual performance/run — Xcode's single-size
icon format will scale it to every size automatically. Same goes for each app's
placeholder `Avatar.imageset/avatar.jpg` (currently a solid-color square).

## Calibrating the pickup/put-down gesture

GC Installation only — GC Performance has no motion detection, it starts on the
performer's first message instead. Core Motion can't be tested in the Simulator,
so this must be done on a real device.

1. Temporarily change the root view in `GCInstallation/GCInstallationApp.swift`
   from `RootView()` to `CalibrationView()`.
2. Run on your phone and watch the live `gravity.z` value while setting the phone
   flat on a table vs picking it up in your hand at different angles/speeds.
3. Adjust `pickedUpThreshold`, `flatThreshold`, and `requiredStableDuration` in
   `GCInstallation/Services/MotionManager.swift` until the FLAT/PICKED UP
   indicator feels reliable and doesn't flicker.
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
project.yml                   # XcodeGen config — defines both app targets

Shared/                       # Compiled into every app target
  AppDelegate.swift            # Idle timer disable + portrait lock
  Models/
    ScriptStep.swift           # ScriptStep/ScriptStepKind types (the data using them
                                # lives per-app in <App>/Models/Script.swift)
    ChatItem.swift              # Unifies script bubbles + user-sent bubbles into one timeline
  Views/
    ChatView.swift               # The chat screen itself — used by both apps' root views
    ChatHeaderView.swift
    MessageBubble.swift           # Text bubble (script text steps and user-sent messages)
    ImageMessageBubble.swift      # Photo bubble (script image steps)
    FullScreenImageView.swift     # Full-screen photo viewer (tap a photo bubble)
    VoiceMessageBubble.swift      # WhatsApp-style voice note bubble, tappable, shows progress
    ComposeBar.swift              # Bottom text input for typing/sending a message
  Services/
    PlaybackSequencer.swift       # Drives the script, one step at a time
    SoundEffectPlayer.swift       # Sent/received/lock-screen alert sound + vibration

GCInstallation/                # Everything specific to the GC Installation app
  GCInstallationApp.swift       # App entry point (@main)
  Info.plist
  Models/
    Script.swift                 # The actual message sequence for this app
  Views/
    RootView.swift                # App root — switches between lock screen and ChatView
    LockScreenView.swift          # Fake lock screen: clock, background, notification banner
    CalibrationView.swift         # Throwaway motion-sensor calibration harness
    DebugTriggerOverlay.swift     # Dev-only manual pickup/put-down triggers (simulator only)
  Services/
    MotionManager.swift           # Pickup/put-down detection (Core Motion)
  Resources/Audio/                # Voice message + notification sound files
  Assets.xcassets/
    AppIcon.appiconset/            # App icon
    LockScreenBackground.imageset/ # Lock screen background photo
    Avatar.imageset/               # Chat header avatar
    photo_01.imageset/             # Example photo-message asset

GCPerformance/                 # Everything specific to the GC Performance app
  GCPerformanceApp.swift        # App entry point (@main)
  Info.plist
  Models/
    Script.swift                 # The actual message sequence for this app
  Views/
    PerformanceRootView.swift     # App root — shows ChatView directly, no lock screen
  Resources/Audio/                # Voice message + notification sound files
  Assets.xcassets/
    AppIcon.appiconset/            # App icon
    Avatar.imageset/               # Chat header avatar
```

## GC Installation: lock screen flow

`RootView` is GC Installation's actual root and owns both `MotionManager` and
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

Putting the phone down doesn't reset instantly — there's a ~2.5s grace period
(`putDownResetDelay` in `RootView.swift`) so a brief adjustment of grip doesn't
restart the whole piece. If it's picked back up within that window, nothing
resets and playback continues where it left off.

The compose bar at the bottom lets the audience member type and send their own
message, which appears as a bubble on the right (like a normal outgoing
message). In this app it's purely cosmetic — it doesn't affect the script — and
clears on reset (along with everything else in the chat) since `ChatView`
unmounts entirely when returning to the lock screen.

## GC Performance

`PerformanceRootView` is GC Performance's root — it shows `ChatView` directly,
with no lock screen, since this app is the performer's own control surface
rather than a prop pretending to be a stranger's phone:

1. The chat is empty and idle on launch. The performer types and sends a
   message (the compose bar is a real input here, not cosmetic) — whatever they
   type, it just needs to be sent.
2. That first send calls `sequencer.start()`, and the scripted sequence begins
   revealing bubbles from `GCPerformance/Models/Script.swift`, exactly as
   described in "Chat behavior" below (tap-to-play voice notes, etc).
3. Sending the exact message **"reset"** (case-insensitive) at any point clears
   the whole chat and resets the sequencer back to the start, instead of being
   added as a bubble — ready for the performer to send a fresh first message
   and start again.

This interception happens in `PerformanceRootView.handleSend` via `ChatView`'s
`onBeforeSend` hook — GC Installation doesn't pass one, so its compose bar keeps
the default cosmetic behavior described above.

## Chat behavior (both apps)

- Each step (other than the very first, for GC Installation) shows a pulsing
  **"Sending voice message…"** status (`sendingDuration` in
  `PlaybackSequencer.swift`, default 2s) before the actual bubble appears.
- Voice messages **do not autoplay** — the bubble appears paused/ready, and
  someone must tap the play circle to start it. Tapping again pauses/resumes.
  Once a voice message has finished playing, tapping it again replays it from
  the start, independent of the sequence itself. The waveform fills
  left-to-right to show playback progress.
- The sequence only advances to the next step once the current one has actually
  been **played through to the end** (plus its `postDelay`) — if nobody presses
  play, it just waits there.
- Tapping a photo message bubble shows it full-screen with its caption below;
  a back button in the top-left returns to the chat.
- Once the last script step's `postDelay` elapses with nothing left to advance
  to, the contact's status in the header switches from "online" to "offline" —
  the visible sign that the sequence (and the performance) has ended.

## Note on WhatsApp branding

The UI is styled _in the manner of_ WhatsApp (colors, bubble shapes, voice-note
layout) but doesn't use Meta's actual logo or wordmark. That's fine for a private,
non-distributed art installation, but worth keeping in mind if the piece is ever
shown publicly or documented online.
