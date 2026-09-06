# MorseBoard media

Captured from the running app and keyboard extension on an iPhone 17 Pro Max simulator, iOS 26.3, on 6 September 2026. The message examples are staged demonstration text entered with the actual keyboard. The footage is edited to remove idle time; no keyboard interactions are generated or faked.

## App Store uploads

Upload these five PNGs in this order in the 6.9-inch iPhone screenshot slot:

1. `AppStore/01-type-in-morse.png` — dots and dashes
2. `AppStore/02-alphabet.png` — QWERTY letters to Morse
3. `AppStore/03-translate.png` — Morse to letters
4. `AppStore/04-single-key.png` — timed single-key layout
5. `AppStore/05-settings.png` — keyboard settings

All are opaque RGB PNGs, 1320 × 2868. They frame genuine cropped screenshots with orange/black typography. Unframed captures are in `Source/`.

Optional App Preview: `AppStore/morseboard-preview.mp4` — 25 seconds, 886 × 1920, 30 fps, H.264 High Level 4.0, AAC stereo at 48 kHz. The AAC track is silent because MorseBoard has no sound feature. `preview-poster.jpg` is a reference for the five-second poster frame; choose the poster in App Store Connect.

Apple references checked during export:
- https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications
- https://developer.apple.com/help/app-store-connect/reference/app-information/app-preview-specifications

App Store Connect still validates the upload; inspect the uploaded preview and screenshots before submitting.

## In-app guides

`MorseApp/Tutorials/` contains four captioned MP4s and matching JPEG posters:

- `enable-keyboard` — Settings → General → Keyboard → Keyboards → Add New Keyboard → MorseBoard
- `type-symbols` — enter SOS using dots and dashes
- `alphabet` — choose Alphabet and type HI MORSE
- `decode-letters` — decode Morse into SOS

The app bundles these assets, so the guides work offline. Open **Watch the guides** in MorseBoard. Playback starts only when requested and pauses when leaving the screen or backgrounding the app. Written instructions accompany every video.

`GIFs/` contains looping 300-pixel-wide, 8 fps versions for README/support use. Use MP4s inside the app for playback controls, clearer text, and smaller size. GIFs are not App Store screenshot or App Preview uploads.

## Keeping the repository manageable

The final PNG, MP4, JPEG and GIF exports are small enough to commit normally. Original `.mov` takes remain in `Source/` on this Mac but are gitignored, as is `.work/`. Copy the original takes to your own backup if you want to retain them when moving machines.

`make_media.py` preserves the edit decisions, captions and screenshot design. To regenerate, install Pillow and FFmpeg, then run:

```sh
FFMPEG=/path/to/ffmpeg python3 Release/Media/make_media.py
```

The script expects the two original takes: `Source/enable-keyboard.mov` and `Source/typing-and-settings.mov`. It uses the Arial fonts bundled with macOS. Re-record after changing controls or layout, and update the edit times in the script.

Before publishing, watch the full preview and try all four guides on your physical iPhone. The setup footage reflects iOS 26; instructions also appear as text for other supported iOS versions.
