---
paths:
  - "**/*.swift"
  - "Config/*.xcconfig"
  - "Eyeline.xcodeproj/**"
---

# Swift rules for Eyeline

The project brief in `CLAUDE.md` has priority when a rule conflicts with it.
The sources are at the end of this file.

## Style

- Name a symbol for clarity at the call site. Name it by its role, not by its type.
- Write Boolean names as assertions: `isScrolling`, `isSetupShown`.
- Use `UpperCamelCase` for types. Use `lowerCamelCase` for all other names. Do not use a `k` prefix.
- Give each declaration the strictest access level that compiles. Use `private` before `fileprivate`.
- Mark each class `final`.
- Let the compiler infer types. Write a type annotation only when there is no initial value, or for an empty collection.
- Use the short forms `[T]`, `[K: V]` and `T?`. Do not write `get` in a read-only computed property. Do not write `-> Void`.
- Put `guard` at the top of a scope for early exits. Keep the main path at the left margin.
- Use the short unwrap form: `if let script`, `guard let self`.
- Do not use semicolons. Write one statement per line.
- Use trailing-closure syntax only when the call has one closure.
- Omit `self.` unless the compiler requires it.
- Divide a long file with `// MARK: - Name`. Use `//` comments only, not `/* */`.
- In a `switch` over a project enum, list all cases. Do not add `default`.
- Put constants in a caseless `enum` as `static let`.
- Keep lines at 120 columns or less, the SwiftLint default. Indent with 4 spaces.
- Write comments in English. Write a comment only for a reason, a constraint or a gotcha.

## Safety

- Do not use `!`, `as!` or `try!`. Exception: the adjacent code makes the invariant obvious, or a comment states it.
- Mark an unused `required init?(coder:)` with `@available(*, unavailable)`. Keep `fatalError` in its body.
- For an unexpected state that the app can survive: call `assertionFailure`, then return.
- Use `fatalError("message")` only when the app cannot continue.
- Capture `[weak self]` in each closure that can outlive `self`. Do not use `unowned`.

## Concurrency

- The build setting `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` applies to all targets. Do not add `@MainActor` in the app target.
- Exception: an `XCTestCase` subclass is `nonisolated`, and each test method is `@MainActor`. The `XCTestCase` initializers are nonisolated, so the class cannot take the module default.
- The `App` struct uses `@main`.
- Selector callbacks (`CADisplayLink`, gesture recognizers) run on the main run loop. They need no isolation code.
- A `Task {}` made in a view runs on the main actor. Check `Task.isCancelled` after each `await`.
- Do not use `nonisolated(unsafe)`.

## SwiftUI

- Put logic in `Layout` and `ScriptStore`, not in views. When a test should check a value, a view does not compute it.
- Take each `@AppStorage` key and default from `Setting`. Never write a key string or a default value in a view.
- Clamp a stored value when it is read (in `Layout`). A value stored on another screen size then stays valid.
- A tap must reach the UIKit canvas under the SwiftUI controls. A `Spacer` or an empty `frame` does not take taps. A `contentShape` does: use it only where the taps must stop (Setup).

## UIKit text engine

- Make the text view with `UITextView(usingTextLayoutManager: false)`. TextKit 2 estimates the height of a long text, and the scroll speed needs the real height.
- Change a standalone `CALayer` (the fade mask) inside a `CATransaction` with `setDisableActions(true)`. Otherwise each change animates for 0.25 s.
- Invalidate the `CADisplayLink` on pause, at the end, and when the view leaves the window. Then set its reference to `nil`.

## Performance and memory

- No timer at rest. Start the display link when the text starts to scroll, not before.
- Compute the position from elapsed time. Keep it in a `Double`.
- Run the text layout only when an input changes.
- Declare nothing `public`.

## Tests

- Unit tests use Swift Testing. Flow tests use XCUITest.
- A UI test sets the orientation it needs before it launches the app: a test that ran in portrait leaves the device in portrait.
- After a rotation, wait one second before a tap. On iOS 18, a tap during the rotation animation is lost.
- Tap a text view at a coordinate, not with `element.tap()`: the accessibility point of a text view can be under the navigation bar.
- Wait for the keyboard before `typeText`. The focus comes a moment after the tap.
- In a UI test, take screenshots with `XCUIScreen.main.screenshot()` and rotate the landscape ones. `app.screenshot()` of a landscape app comes out rotated and cropped. Outside a test, use `xcrun simctl io booted screenshot`.

## Build

- The build must give zero warnings. `COPY_PHASE_STRIP = NO` and `ALWAYS_SEARCH_USER_PATHS = NO` remove the two build-system warnings of a hand-written project.
- Object IDs in `project.pbxproj` are 24 hexadecimal digits that start with `E1E1`. A new object gets the next free ID in that pattern.

## Rules that were examined and rejected

- A `///` comment on each declaration: the app has no public API.
- SwiftData for the scripts: a schema and migrations for one text field, and the scripts stay locked inside the app.
- XcodeGen or Tuist: a dependency to generate a file that folder-synchronised groups keep stable.
- `ScrollView` with `scrollPosition` for the prompter: SwiftUI lazy stacks estimate their offsets (WWDC26 session 321).
- A per-frame `.offset` in SwiftUI: reports of jitter on ProMotion screens.
- Volume buttons as a remote: App Review guideline 2.5.9.

## Sources

- Swift API Design Guidelines: https://www.swift.org/documentation/api-design-guidelines/
- Google Swift Style Guide: https://google.github.io/swift/
- Airbnb Swift Style Guide: https://github.com/airbnb/swift
- SwiftLint rule directory: https://realm.github.io/SwiftLint/rule-directory.html
- SE-0466, default actor isolation: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0466-control-default-actor-isolation.md
- ProMotion and `CADisableMinimumFrameDurationOnPhone`: https://developer.apple.com/documentation/quartzcore/optimizing-iphone-and-ipad-apps-to-support-promotion-displays
- `UITextView(usingTextLayoutManager:)`: https://developer.apple.com/documentation/uikit/uitextview/init(usingtextlayoutmanager:)
- WWDC26 session 321, scroll views: https://developer.apple.com/videos/play/wwdc2026/321/
- Textream (MIT), a `UITextView` moved by a `CADisplayLink`: https://github.com/f/textream
- App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
