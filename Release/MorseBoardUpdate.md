# MorseBoard branding and settings update

Display names are MorseBoard for the app and extension. Existing project/scheme names and bundle identifiers remain stable.

App Store subtitle: Your Morse Code keyboard
Tagline: Text in Morse!
The combined requested phrase is longer than Apple's 30-character subtitle limit.

## Icon

Built-in imagegen was used. The selected generated image is copied to `MorseApp/Assets.xcassets/AppIcon.appiconset/MorseBoard.png`, resized to 1024 square for the app icon, and verified to have no alpha channel.

Final prompt: Create a pristine minimalist app icon. 1024x1024 square opaque pure black background. Exactly two solid flat orange #FF9500 geometric shapes centered together: a circular dot on the left, horizontal rectangular dash on the right. Circle diameter 160 pixels, dash width 400 pixels and height 160 pixels; black gap of 90 pixels between shapes. All shapes vertically centered at y=512. Clean smooth antialiased edges, absolutely no speckles, no glow, no gradients, no textures, no connecting marks between dot and dash, no text, no border. Flat vector-like precision.

## Behavior

- Fixed editing columns: Caps/Settings, Space, Delete, Enter. Gear fills the Caps slot in symbols mode. Globe is in the header.
- Settings slides up as a child view within the keyboard extension, rather than a full-screen modal over the host app. The panel grows to 380pt portrait / 240pt landscape and scrolls. Done restores 216pt / 160pt typing height.
- Layout picker selects two keys, one timed key, or an alphabet keyboard that outputs Morse. The translate toggle applies to Morse-key layouts. Dot picker chooses bullet or period. WPM slider is 5–30.
- Settings persist in the extension's own UserDefaults.
- Full Access is not requested or required; there is no networking code.
- Extension privacy manifest declares UserDefaults for preferences (CA92.1) and system uptime for press timing (35F9.1).

## Device checks before committing

- Install with Cmd-R; verify Home Screen and enabled keyboard names/icon.
- Compare symbols/letters mode: Space, Delete and Enter must stay in place.
- Open settings, scroll, change each control, tap Done, reopen, rotate while open.
- Verify . versus • literal output, decoded lower/uppercase output, invalid sequence discard, Enter and deletion.
- Verify all three key layouts and all settings work without Full Access.
- Inspect smallest supported iPhone portrait and landscape; check VoiceOver navigation and settings focus.

Apple references:
https://developer.apple.com/app-store/product-page/
https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/CustomKeyboard.html
https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
