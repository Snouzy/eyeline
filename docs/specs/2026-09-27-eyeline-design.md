# Eyeline — design

Date: 2026-09-27. Status: approved. Updated after the spike (see "Changes after the spike").

## Problem

The user records videos with a DJI Osmo Pocket 3. The iPhone is the prompter screen only, never the camera. It stands behind the Pocket, in landscape, with the Pocket lens near the centre of the screen. The Pocket body hides a vertical band of the screen. The user sits 60 cm to 1 m from the Pocket.

On the recordings, viewers see that the user reads: the eyes sweep lines of text that sit beside the lens. The iOS prompter apps do not help. They are paid, and they put the text under the iPhone front camera, which is useless when another camera films.

## Research basis

- Viewers lose eye contact when the gaze moves more than about 1° left, right or up from the lens. Downward they tolerate up to about 5°. Sources: Chen, CHI 2002 (https://graphics.stanford.edu/papers/eye_contact/paper.pdf); Gao et al. 2024 (https://arxiv.org/html/2404.17104v1).
- Angle = atan(offset from the lens / distance to the eye). With the phone behind the Pocket, text cannot go below the lens: the Pocket body is there. Text goes to the side, the most sensitive direction.
- The Pocket 3 body is 42 mm wide. The hidden band on the screen is about 45 mm wide, so the nearest text is about 23 mm from the lens. On an iPhone Pro in landscape, each side strip is about 50 mm wide.

| Text offset from the lens | 60 cm | 80 cm | 1 m |
| --- | --- | --- | --- |
| 2.3 cm (edge of the hidden band) | 2.2° | 1.6° | 1.3° |
| 4.5 cm (edge of a 2.2 cm column) | 4.3° | 3.2° | 2.6° |
| 5.8 cm (edge of the default 3.5 cm column) | 5.5° | 4.1° | 3.3° |
| 7.3 cm (outer edge of the screen) | 6.9° | 5.2° | 4.2° |

- Conclusion: put the text in a narrow column right against the hidden band, with the reading line at lens height. The app reduces the sweep. It cannot remove the offset.
- No app that we found lays text out around an external camera, and none limits the column width to a few words.
- Two free MIT apps exist: Open Prompter (https://github.com/lelanddutcher/open-prompter) and Textream (https://github.com/f/textream). Both are built around the iPhone camera or the Mac. We build from zero and take ideas, not code.

## Goals (v1)

1. Show the script in a narrow column right against the hidden band, with the reading line at lens height.
2. Scroll at a constant speed, set in words per minute.
3. Let the user set the hidden band and the reading line directly on the screen.
4. Keep a list of scripts that the user pastes from the clipboard.
5. Free and open source (MIT). No network access, no account, no analytics, no permission prompt.

## Non-goals (v1)

- Voice tracking, Bluetooth remote, Apple Watch.
- Mirror mode, "ticker" mode (B), "word groups" mode (C).
- Camera, recording, Pocket 3 control.
- File import, share extension, iCloud sync, Markdown, rich text.
- iPad, portrait prompter.
- App Store or TestFlight distribution.

## Platform

- iPhone only, iOS 18 or later. The app is landscape only (left and right).
- Interface strings in French. Code, comments and documentation in English.
- Distribution: GitHub only. Users build with Xcode.
- Name: Eyeline. Bundle identifier: `com.snouzy.eyeline`.

## Screens and behaviour

### Script list

- One row per script: the title, the word count, and the estimated duration at the current speed ("≈ 2 min 30 s").
- The title is the first line that is not empty, trimmed. An empty script shows "Sans titre".
- Order: last modified first.
- Toolbar: a system `PasteButton` makes a new script from the clipboard text and opens it in the editor. The system button reads the clipboard without the "Allow Paste" prompt. A "+" button makes an empty script and opens it in the editor.
- Tap a row: open the editor. Swipe left: delete.

### Editor

- A `TextEditor` with the plain text. The text saves each time it changes.
- When the user leaves the editor and the text is empty, the app deletes the script.
- Toolbar: "Lire" opens the prompter in full screen.

### Prompter

- Black background, white text, system font, semibold. The status bar is hidden.
- The screen stays on while the prompter is open: `isIdleTimerDisabled` is true on appear and false on disappear.
- The column: its inner edge touches the hidden band, on the side set in Setup (right by default). The text is left-aligned. The column width and the text size come from Setup.
- The reading line: at the height set in Setup. A small grey mark at the outer edge of the column shows it.
- Fade: about one line above and three lines below the reading line are fully visible. The text then fades to transparent within two lines, up and down. The values are tuned on the device.
- At the start, the first line sits on the reading line.
- States:

| State | Tap | Other |
| --- | --- | --- |
| Ready | Start the countdown | Controls visible |
| Countdown (3, 2, 1 at the reading line) | Cancel, back to the previous state | — |
| Scrolling | Pause | Controls hidden |
| Paused | Start the countdown | Controls visible. A vertical drag moves the text |
| Ended (last line past the reading line) | Start the countdown from the top | Controls visible |

- The countdown runs before each start and each restart: the phone is behind the Pocket, and the user needs 3 seconds to go back to position.
- Controls: close (✕), speed − and + (steps of 10 words per minute, 60 to 240), back to the top, Setup. They are in the side strip opposite the column, so they never cover the text.

### Setup

- A mode of the prompter, opened from the controls. The script stays visible, so each change shows at once.
- The hidden band shows as a coloured translucent rectangle over the full screen height. The reading line shows as a horizontal line.
  - Drag an edge of the band: move that edge (20 pt minimum between the edges). The middle of the band is behind the Pocket and cannot be touched, so the edges are the only handles.
  - Drag the reading line: move it up or down.
- A panel in the side strip opposite the column: side of the column (Gauche / Droite), column width, text size, and an "OK" button that goes back to the previous state.
- Each value saves at once.
- The user sits at the filming position, checks that the band edges disappear behind the Pocket, and adjusts. This takes a few tries, because the band width depends on the eye position (parallax).

### Settings and defaults

| Setting | Stored as | Default | Range |
| --- | --- | --- | --- |
| Words per minute | integer | 130 | 60–240 |
| Text size | points | 34 | 20–80 |
| Column width | points | 220 (about 3.5 cm) | 60 to the width of the side strip |
| Column side | left or right | right | — |
| Hidden band centre | fraction of the screen width | 0.5 | band stays on screen |
| Hidden band width | points | 280 (about 45 mm on an iPhone Pro) | 20 to half the screen width |
| Reading line | fraction of the screen height | 0.5 | 0.1–0.9 |

- The app stores these values with `@AppStorage`. Each key is defined one time.
- The column never goes past the screen edge. When the side strip is narrower than the column width, the column takes the full strip.

## Speed and duration

- Word count: the number of tokens separated by white space or line breaks. "l'objectif" counts as one word.
- Scroll speed in points per second = (words per minute ÷ 60) × (height of the laid-out text ÷ word count). Blank lines between paragraphs add height, so they give a natural pause. With zero words, the text does not scroll.
- Duration on the list = word count ÷ words per minute, rounded to 10 seconds.
- A speed change during a pause applies at the next start. The position does not change.

## Architecture

### Stack

- SwiftUI for the list, the editor, the prompter controls and Setup.
- The scrolling text is UIKit: a `UITextView` (not editable, not selectable) in a `UIViewRepresentable`. A `CADisplayLink` sets `contentOffset` on each frame.
  - Reason: this is the approach known to be smooth at 120 Hz (Textream uses it). A per-frame offset in SwiftUI jitters on ProMotion screens, and one very tall `Text` handles long scripts badly.
- Swift 6 language mode, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, zero warnings.

### Scroll engine

- Position = offset at start + speed × (frame time − start time). The engine computes it from time on each frame and keeps it in a `Double`. It never adds a fixed step per frame.
- `preferredFrameRateRange` asks for up to 120 Hz. The Info.plist key `CADisableMinimumFrameDurationOnPhone` unlocks more than 60 Hz on iPhone.
- The display link exists only while the text scrolls. It is invalidated on pause, at the end and on disappear. No timer runs at rest.
- Content insets let the first line sit on the reading line at the start, and let the last line reach it at the end.
- The fade is a `CAGradientLayer` mask on the view that holds the text view, not on the scrolled content.

### Storage

- One UTF-8 `.txt` file per script, in the app Documents folder.
- The file name is the creation date and time, `2026-09-27 14.03.21.txt`. It never changes, so it is the script identifier. Two scripts made in the same second get " 2", " 3", and so on.
- The Info.plist keys `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace` make the folder visible in the Files app. Backup and export need no code.
- `ScriptStore` (`@Observable`): list (last modified first), create, save (atomic write), delete. Tests give it a temporary folder.
- Errors: a failed read or write shows an alert with the message. The app continues. The list skips a file that it cannot read.
- When the list loads, it deletes the scripts that have no words. The editor deletes them on close, but not when the app is killed first.

### Files

| File | Role |
| --- | --- |
| `EyelineApp.swift` | Entry point, `ScriptStore` injection |
| `ScriptStore.swift` | Scripts as `.txt` files: list, create, save, delete |
| `ScriptListView.swift` | List, paste, new script, delete |
| `EditorView.swift` | Plain-text editor, "Lire" button |
| `PrompterView.swift` | States, countdown, tap, drag, controls, idle timer |
| `ScrollingText.swift` | `UITextView` + `CADisplayLink` + fade mask |
| `SetupView.swift` | Hidden band, reading line, side, width, text size |
| `Layout.swift` | Pure functions: column frame, speed, duration, word count, title |
| `Settings.swift` | The `@AppStorage` keys and defaults |

### Project

- `Eyeline.xcodeproj`, written by hand, with folder-synchronised groups for `Eyeline/` and `EyelineTests/`. Adding a source file does not change the project file. No XcodeGen, no Swift package, no dependency.
- Targets: `Eyeline` (app), `EyelineTests` (unit tests with Swift Testing) and `EyelineUITests` (flow tests with XCUITest). A shared scheme is committed.
- `IPHONEOS_DEPLOYMENT_TARGET = 18.0`, `TARGETED_DEVICE_FAMILY = 1`, `SWIFT_TREAT_WARNINGS_AS_ERRORS = YES`. `COPY_PHASE_STRIP = NO` and `ALWAYS_SEARCH_USER_PATHS = NO` remove the two build-system warnings.
- Signing: `Config/Base.xcconfig` includes `Local.xcconfig` if it exists (`#include?`). `Local.xcconfig` is git-ignored and holds `DEVELOPMENT_TEAM`, and optionally another `PRODUCT_BUNDLE_IDENTIFIER` for a contributor. `Local.xcconfig.example` is committed.
- Command line: `xcodebuild -project Eyeline.xcodeproj -scheme Eyeline -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4.1' test`. The iOS 18 floor is checked with `name=iPhone 16 Pro,OS=18.3.1`.

## Testing

- Unit tests (Swift Testing):
  - `Layout`: column frame on each side, clamp to the screen edge, strip narrower than the column, speed formula, zero words, duration rounding, word count, title of an empty or blank script.
  - `ScriptStore` on a temporary folder: create, list order, save, delete, unreadable file skipped, two scripts in the same second.
- UI tests (XCUITest), with the device turned to landscape:
  - new script, typing, "Lire", tap: countdown, then scrolling; tap: pause; Setup opens and closes; close.
  - a new script left empty is deleted when the user goes back.
- Simulator: build with zero warnings, all tests pass. Screenshots come from `xcrun simctl io <device> screenshot`: XCUITest screenshots of a landscape-only app come out rotated and cropped.
- On the user's iPhone only, and never reported as verified before the user checks it:
  - smooth scrolling at 120 Hz;
  - Setup behind the Pocket, from the filming position;
  - legibility at 60 cm to 1 m;
  - a test recording with the Pocket 3, to judge how visible the reading is.
- `tasks/todo.md` records each result.

## Success criteria

1. The user pastes a script, sets the band and the reading line, and reads it at a constant speed with the phone behind the Pocket.
2. On a test recording at 60 cm to 1 m, the user judges the reading less visible than before. This is the user's judgment, not a measurement.
3. No visible jitter on a 120 Hz iPhone.
4. Zero warnings, all unit tests pass.
5. No network access and no permission prompt.

## Repository conventions

- `CLAUDE.md` (English): goal, "Keep this file current", constraints that are not negotiable, architecture, performance principles, current state, out of scope, build and test commands. The model is `trace/CLAUDE.md`.
- `.claude/rules/swift.md` for `**/*.swift`: the style, safety and concurrency rules of `trace`, and its sections "Rules that were examined and rejected" and "Sources". Removed: Carbon, AppKit and global shortcut rules. Added: logic lives in `Layout` and `ScriptStore`, not in the views; `@main` is allowed.
- `tasks/todo.md` (French) holds the implementation plan and the checks. `tasks/lessons.md` starts with the `trace` lessons that apply here.
- `README.md` (English), on the model of the `trace` README. It explains the eye angle with the table above. Acknowledgements: Textream, Open Prompter, Chen 2002.
- `LICENSE`: MIT, "Copyright (c) 2026 Mathias Bradiceanu".
- `.gitignore`: `xcuserdata/`, `DerivedData/`, `build/`, `Local.xcconfig`, `.DS_Store`.
- Git: local repository. Before each commit, `/ponytail-review`, then an explicit yes from the user. The public GitHub repository `Snouzy/eyeline` is made only after an explicit yes. The user pushes the first commit to `main`. After that, each change goes on a branch and through a pull request against `main`, one at a time.

## Changes after the spike

A throwaway build of the whole app ran on the simulator (iOS 18.3.1 and 26.4.1) before the plan. It changed these points:

- Default column width 150 → 220 pt: at 34 pt, "aujourd'hui" did not fit in 150 pt and broke inside the word.
- The prompter controls moved to the side strip opposite the column: in a corner, they covered the text.
- Setup moves the band by its edges only: the middle is behind the Pocket.
- The list deletes empty scripts when it loads.
- A UI test target was added: the command line cannot tap, and the taps through the UIKit text were the main risk.

## Risks

- The column is 1.3° to 4° from the lens at 60 cm to 1 m, above the 1° threshold. If the reading still shows, the next steps are: stand farther back with the 40 mm Med-Tele mode of the Pocket, then test mode B or C.
- Parallax makes Setup a few tries.
- The tap to start needs a hand near the rig, which can move it. The countdown gives time to go back to position. A remote is a later option.
- Editing in landscape is less comfortable. Pasting is the main way in.
- Patent US 9,953,646 (PromptSmart) covers voice tracking of a script. v1 has no voice tracking. Check the patent before any voice feature.

## Later (not v1), in order

1. Bluetooth remote or keyboard: start, pause, speed.
2. Mode B (ticker), if the column still shows on camera.
3. Voice tracking, after the patent check.
4. Start the Pocket 3 recording from the app (unofficial protocol, can break with a firmware update).
