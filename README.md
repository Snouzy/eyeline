<div align="center">
  <h1>Eyeline</h1>
</div>

<p align="center">
  <strong>A free, open-source iPhone teleprompter for a camera that is not the iPhone. It puts the text right next to the lens, so viewers do not see you read.</strong>
</p>

## ❓ Why?

Most teleprompter apps assume that the iPhone films you: they put the text under the front camera. When you film with another camera, such as a DJI Osmo Pocket 3, the iPhone is only a screen, and those apps put the text wherever it fits. Your eyes sweep full-width lines far from the lens, and it shows.

Viewers stop feeling eye contact when your gaze moves more than about **1°** left, right or up from the lens ([Chen, CHI 2002](https://graphics.stanford.edu/papers/eye_contact/paper.pdf)). The angle is `atan(offset from the lens ÷ distance)`:

| Text offset from the lens | 60 cm | 80 cm | 1 m |
| ------------------------- | ----- | ----- | ----- |
| 2.3 cm                    | 2.2°  | 1.6°  | 1.3°  |
| 5.8 cm                    | 5.5°  | 4.1°  | 3.3°  |
| 7.3 cm                    | 6.9°  | 5.2°  | 4.2°  |

A full-width line on an iPhone in landscape at 60 cm sweeps your eyes over more than 10°. Eyeline keeps the text against the camera body, with the reading line at lens height. Your eyes stay a few degrees from the lens and barely move.

## ✨ Features

- 🎯 **Lens-anchored text**: the text scrolls right against the camera body, on the left, on the right, or on both sides. On both sides, each line starts left of the camera and ends right of it.
- 📏 **Reading line at lens height**: the lines already read fade out; the lines to come stay visible down to the bottom of the screen.
- 🛠️ **On-screen setup**: drag the edges of the hidden band until they line up with the camera body, and drag the reading line to the lens.
- ↔️ **A width for each side**: drag the outer edge of each column. Text size (12 to 80 pt) and line spacing are settings too.
- ⏱️ **Speed in words per minute**: the app measures your layout and turns 130 words/min into the right scroll speed. The list shows the duration of each script.
- 3️⃣ **Countdown before each start**: time to go back to your place after you tap the phone.
- 📋 **Paste to start**: copy your script anywhere, tap **Coller**. No "Allow Paste" prompt. Markdown marks (`>`, `#`, `**`, list dashes) do not show in the prompter.
- 📁 **Plain text files**: each script is a `.txt` file in the Files app (On My iPhone › Eyeline).
- 🔒 **Nothing leaves the phone**: no network access, no account, no analytics, no permission.
- 🪶 **Small**: about 600 KB, no dependency. The display link runs only while the text scrolls.

## 📦 Installation

Eyeline is not on the App Store. Build it with Xcode.

1. **Requirements**: a Mac with Xcode 26 or later, an iPhone with iOS 18 or later, and an Apple account (a free one works; the app then expires after 7 days).
2. **Clone the repository:**

   ```sh
   git clone https://github.com/Snouzy/eyeline
   cd eyeline
   ```

3. **Set your signing team:**

   ```sh
   cp Config/Local.xcconfig.example Config/Local.xcconfig
   ```

   Put your Team ID in `Config/Local.xcconfig`. It is in Xcode › Settings › Accounts. If you are not the author, also set another `PRODUCT_BUNDLE_IDENTIFIER` there. Git ignores this file.

4. **Run:** open `Eyeline.xcodeproj`, choose your iPhone, press <kbd>⌘</kbd> + <kbd>R</kbd>.

> [!NOTE]
> The interface is in French: **Coller** (Paste), **Lire** (Read), **Réglages** (Setup), **Gauche / Les deux / Droite** (Left / Both / Right).

## 🚀 Quick Start

1. Put the iPhone in landscape, behind the camera, with the lens near the middle of the screen.
2. Copy your script, open Eyeline, tap **Coller**. Tap **Lire**.
3. Tap the sliders button (**Réglages**). Sit at your filming position and look at the screen:
   - drag each orange edge until it just disappears behind the camera body;
   - drag each white edge to set the width of the text on that side;
   - drag the horizontal line to the height of the lens;
   - choose the side of the text (**Gauche**, **Les deux**, **Droite**), the text size (**Taille du texte**) and the line spacing (**Interligne**).
4. Tap **OK**, start the camera, tap the screen. The text starts after 3, 2, 1.

## 🎮 Usage

| Action | Result |
| --- | --- |
| Tap anywhere | Start (after a countdown), pause, start again |
| Drag the text while paused | Go back or forward |
| **−** / **+** | Speed, by steps of 10 words per minute (60 to 240) |
| ⏮ | Back to the top |
| ✕ | Close the prompter |

Tips:

- Stand farther back and zoom in: at twice the distance, every angle is about half. The Pocket 3 has a 40 mm Med-Tele mode for this.
- A narrow column with 2 or 3 words per line moves your eyes less than a wide one.

## 🛠️ Development

The Xcode project is written by hand, with no generator and no package. A new Swift file in `Eyeline/` needs no change to the project.

```sh
xcodebuild -project Eyeline.xcodeproj -scheme Eyeline \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

The project brief is in [`CLAUDE.md`](CLAUDE.md), the Swift rules are in [`.claude/rules/swift.md`](.claude/rules/swift.md), and the design with its research is in [`docs/specs`](docs/specs).

## 📄 License

[MIT](LICENSE)

## 🙏 Acknowledgements

- [Textream](https://github.com/f/textream) and [Open Prompter](https://github.com/lelanddutcher/open-prompter), two MIT teleprompters, for the scrolling approach and the proof that a free prompter can be good.
- Milton Chen, [*Leveraging the asymmetric sensitivity of eye contact for videoconferencing*](https://graphics.stanford.edu/papers/eye_contact/paper.pdf) (CHI 2002), for the numbers behind the idea.
