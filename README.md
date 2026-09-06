# Morse Keyboard

An iOS 17+ app and custom keyboard extension. Open **MorseKeyboard.xcodeproj**, not just the repository folder, in Xcode.

## Run on your iPhone (Xcode 26)

1. Open `MorseKeyboard.xcodeproj` from Finder or Xcode → File → Open.
2. Click the blue project icon in the navigator. Under **Targets**, select **MorseKeyboard**, then **Signing & Capabilities**.
3. Enable **Automatically manage signing** and select your Apple development team. Add your Apple Account in Xcode → Settings → Accounts if necessary.
4. Change the app bundle identifier from `com.example.morsekeyboard` to a unique identifier, such as `com.yourname.morsekeyboard`. Select **MorseExtension** and set its team too, and use the same identifier plus `.keyboard` for its bundle identifier.
5. Connect and unlock your iPhone, trust the Mac if prompted, and enable Developer Mode on the phone if Xcode asks. Select **MorseKeyboard** as the scheme in the top toolbar and your iPhone as the destination. Press **⌘R**.
6. On the phone, open **Settings → General → Keyboard → Keyboards → Add New Keyboard → Morse Keyboard**.
7. Open the app's practice field or Notes. Hold the globe key and select Morse Keyboard.

A free Personal Team can be used for initial device testing; distribution requires Apple Developer Program enrollment. Signing and device provisioning are configured locally in Xcode. No App Groups or Full Access are needed.

For simulator testing, select an installed iPhone simulator and press ⌘R; enable the keyboard in the simulator's Settings in the same way. If it does not appear while editing text, turn off Simulator → I/O → Keyboard → Connect Hardware Keyboard.

## MVP behavior

- Starts with two large keys that insert exactly `•` (U+2022) and `-` (ASCII hyphen). Space and delete operate on the host text field.
- Gear opens keyboard-local settings, persisted across keyboard sessions.
- One-key layout: press and release for a dot, hold for a dash. A dot unit is `1.2 / WPM` seconds; the dash threshold is two units. Canceled/outside touches produce no symbol.
- Letters mode decodes A–Z and 0–9 after three units of silence. A held single key pauses the letter timer. Output is uppercase. Unknown sequences are cleared without inserting any text.
- Delete removes a pending Morse element first, then host text. Space commits the letter and inserts a space. Word spaces are manual.
- At 10 WPM: dot unit = 120 ms, dash threshold = 240 ms, letter pause = 360 ms.
- The single-key layout retains space, settings and keyboard switching for practical use. It is a mode of one installed extension, not a second item in iOS Settings.
- The companion app provides onboarding, practice and a reference. Cross-app settings synchronization is deferred; adding it requires App Groups and revisiting keyboard access configuration.

## Code tour

- `MorseApp/MorseApp.swift`: SwiftUI app entry point and declarative onboarding/practice screen. `@State` stores the temporary practice text.
- `MorseKeyboard/KeyboardViewController.swift`: UIKit extension controller. `textDocumentProxy` inserts/deletes in the app currently using the keyboard. Touch-down/up events measure the single key; a timer commits decoded letters.
- `Shared/Morse.swift`: pure Swift Morse alphabet and timing functions, compiled into both targets.
- `MorseKeyboard/Info.plist`: registers the keyboard extension and disables Full Access requests.
- `MorseKeyboard.xcodeproj`: app target, extension target, and extension embedding. No external packages or project generator needed.

The app and extension are separate processes. Their ordinary `UserDefaults` are separate, which is why the MVP keeps real keyboard settings on the keyboard.

## Validation

Simulator SDK build (no signing):

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project MorseKeyboard.xcodeproj -scheme MorseKeyboard -sdk iphonesimulator -configuration Debug -derivedDataPath /tmp/morse-derived CODE_SIGNING_ALLOWED=NO build
```

Pure Swift mapping and timing checks:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swiftc -module-cache-path /tmp/morse-module-cache Shared/Morse.swift Tests/main.swift -o /tmp/morse-tests
/tmp/morse-tests
```

Before shipping, test on a physical phone:

- Default keys produce `•-`, space inserts a space, delete removes a character.
- One-key short/long presses produce the right symbols at 5, 10 and 30 WPM; dragging outside cancels input.
- Letters mode produces SOS from `...`, `---`, `...` with letter pauses; deleting pending elements and changing text fields does not commit stale input.
- Globe switches keyboards and supports the system input-mode menu.
- Settings persist after switching apps; test portrait, landscape, light/dark appearance, and VoiceOver with the two-key layout.
- Secure fields use the system keyboard. Some apps prohibit custom keyboards, as allowed by iOS.

This is a development MVP, not a submitted App Store release. App icon, device/accessibility QA, screenshots, store metadata and privacy disclosures remain release tasks. It has no networking, analytics, typing-history persistence, automatic word spacing, punctuation decoding or repeat-on-hold delete.

Apple documentation: [Creating a custom keyboard](https://developer.apple.com/documentation/uikit/creating-a-custom-keyboard), [UIInputViewController](https://developer.apple.com/documentation/uikit/uiinputviewcontroller).
