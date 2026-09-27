# Eyeline — project brief

## Goal

Eyeline is a free, open-source teleprompter for iPhone, made for one setup: the iPhone stands behind a DJI Osmo Pocket 3, in landscape, and the Pocket hides the middle of the screen. The app puts the text right against the Pocket, on one side or on both sides, with the reading line at lens height, so that the eyes move as little as possible away from the lens.

The first priorities are **the eye angle** and **simple code**. Each addition must be justified. When in doubt, do not add.

The design and its research are in `docs/specs/2026-09-27-eyeline-design.md`.

## Keep this file current

After each change to the project, update this file in the same change when the change makes a part of it false or incomplete: architecture, commands, constraints, current state, out of scope. Do the same for `README.md` when the change is visible to a user. Do not touch this file when the change has no effect on what it says.

## Technical constraints (not negotiable)

- **Swift 6 and SwiftUI** for the screens. **UIKit only for the scrolling text** (`ScrollingText.swift`). No dependency, no Swift package, no project generator.
- **The Xcode project is written by hand** and uses folder-synchronised groups: a new file in `Eyeline/`, `EyelineTests/` or `EyelineUITests/` needs no change to `project.pbxproj`.
- **iPhone only, iOS 18 minimum, landscape only** (`Config/Info.plist`).
- **Build settings are in `Config/Base.xcconfig`.** The signing team goes in `Config/Local.xcconfig`, which git ignores. `Config/Local.xcconfig.example` shows the format.
- **Default actor isolation is `MainActor`, and warnings are errors.** Zero warnings, build-system warnings included.
- **No network access, no account, no analytics, no permission prompt.** The paste goes through `PasteButton`, which does not show the "Allow Paste" prompt.
- **Bundle identifier: `com.snouzy.eyeline`.**
- **License**: MIT.
- **Swift code rules**: `.claude/rules/swift.md`.
- **The interface strings are in French.** Code, comments and documentation are in English.
- **Distribution**: GitHub only. Users build with Xcode.

## Commands

```sh
# Unit tests and UI tests, about 1 minute.
xcodebuild -project Eyeline.xcodeproj -scheme Eyeline \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4.1' test

# The iOS 18 floor: same command with this destination.
#   -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.3.1'

# Screenshot of the booted simulator. XCUITest screenshots of a landscape-only app are rotated and cropped.
xcrun simctl io booted screenshot shot.png
```

## Current architecture

- `Setting` (`Settings.swift`): the `@AppStorage` keys, their defaults and their limits: speed, text size, line spacing, width of the left and of the right column, side, band, reading line. `ColumnSide`: left, both (the default) or right.
- `Layout`: pure functions, all tested. Band, column and reading-line geometry, and the drag of their edges; the hole of a two-sided column; scroll range and speed; fade stops; Markdown cleanup (`plainText`), word count, title, duration.
- `ScriptStore` (`@Observable`): one UTF-8 `.txt` file per script in the Documents folder, visible in the Files app. The file name is the creation date and never changes: it is the identifier. The store deletes the scripts without words when it loads.
- `ScriptListView`: list, `PasteButton`, "+", swipe to delete, error alert.
- `EditorView`: plain text, saved on each change. Deletes the script when it closes empty. Opens the prompter with the text without its Markdown marks; the saved script keeps them.
- `PrompterView`: phases (ready, countdown, scrolling, paused, ended); a 3-second countdown before each start; pause when the app leaves the foreground; screen kept on; controls in one row at the top, where the fade hides the text.
- `ScrollingText` / `PrompterCanvas`: a full-screen `UIView` that catches the taps and holds the column. A `UITextView` with TextKit 1 (exact height), moved by a `CADisplayLink`. Position = start offset + speed × elapsed time. A `CAGradientLayer` mask fades the lines above the reading line; the text below stays visible to the bottom. In a two-sided column, an exclusion path over the band cuts each line: the text fills the left part, then the right part.
- `SetupHandles`: the hidden band (orange edges), the outer edge of each column (white) and the reading line, moved by drag. The handles run the full screen height. `SetupPanel`: two blocks at the top, side and OK on the left, text size and line spacing on the right.

## Performance principles to keep

- **No timer at rest.** The display link exists only while the text scrolls.
- **The position comes from elapsed time**, never from a fixed step per frame.
- **The text layout runs only when an input changes**: text, text size, column frame or reading line.
- `CADisableMinimumFrameDurationOnPhone` in `Info.plist` allows 120 Hz on ProMotion iPhones.

## Current state

v1 is complete. It builds with zero warnings, and the tests pass on the iOS 26.4.1 and 18.3.1 simulators: 40 unit tests (Swift Testing) and 2 flow tests (XCUITest). The Release app is 588 KB. It was installed and launched on an iPhone 16 Pro Max on 2026-09-27. After the first test on the rig, the user asked for text on both sides of the Pocket: the two-sided column is now the default. After the second test, each side got its own width (drag handles), the line spacing became a setting, the text can go down to 12 pt, and the prompter hides the Markdown marks.

Not checked yet, and checked only on the user's iPhone: smooth scrolling at 120 Hz, Setup behind the Pocket, legibility at 60 cm to 1 m, a test recording, a 5,000-word script, the Files app folder. Follow-up in `tasks/todo.md`.

## Out of scope (v1)

Voice tracking, Bluetooth remote, Apple Watch, mirror mode, ticker mode, word-group mode, camera, Pocket 3 control, file import, share extension, iCloud, Markdown, iPad, App Store.
