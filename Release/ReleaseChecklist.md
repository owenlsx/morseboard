# First App Store release

Status: preparation started; not ready for submission. Work through this with Xcode and App Store Connect's graphical interfaces.

## 1. Account and product choices

- Confirm paid Apple Developer Program membership (Personal Team is for development).
- Confirmed: version 1 targets iPhone only. Both app and extension device families are set to iPhone for Debug and Release.
- Recommended minimum: iOS 17.0 on both targets; build with installed Xcode 26.3.
- Confirm final app name, free versus paid, countries, and public support contact.
- Individual enrollment uses your personal legal name as seller. Review enrollment information before purchasing.

## 2. Release build preparation

- Keep app identifier com.owen.morsekeyboard and extension identifier com.owen.morsekeyboard.keyboard if these are available under the enrolled team.
- Select the enrolled development team for both targets; keep automatic signing enabled.
- Decide orientations after the supported devices are chosen. Support portrait and landscape on iPhone; all four orientations if shipping native iPad support.
- Implemented: orange-on-black dot/dash app icon, compiled asset catalog verified. Check its appearance on-device.
- Replace deprecated appearance callback (implemented; verify build).
- Implemented and bundle-verified: privacy manifest for UserDefaults (CA92.1) and systemUptime (35F9.1).
- Add privacy policy and support information to the app and publish working public URLs.
- Review copy for accurate statements about storage, keyboard limitations, WPM and unsupported Morse sequences.
- Check version/build numbers match across app and extension. Initial version 1.0, build 1; increase build number for subsequent uploads.
- Archive the app scheme in Xcode and validate the distribution archive; recheck the signed-binary stripping warning there.

## 3. Test the release candidate

- Two-key and one-key modes, symbols/letters, WPM bounds and persistence.
- Valid letters/digits, invalid sequence discarded, spaces, delete, canceled touches, switching keyboards and apps.
- Small and large supported iPhone sizes, portrait/landscape, light/dark, larger text and VoiceOver.
- Supported minimum OS and current OS, with physical-device testing.
- If iPad is supported: iPad layouts, rotation, resizing and keyboard presentation.
- TestFlight installation and keyboard enablement from a clean install.
- Capture genuine screenshots of the final build, without personal messages.

## 4. App Store Connect

- Create one iOS app record for the containing app; the keyboard extension ships inside it.
- Enter final name, primary language, bundle ID and internal SKU.
- Set category, price, availability and any required regional business information.
- Complete age-rating questionnaire based on this app's features, not the host messaging apps.
- Complete App Privacy after final audit; current app has no developer-operated collection or tracking.
- Supply public privacy policy URL, support URL and copyright.
- Add icon via the build and required screenshots via the listing. Use current size requirements shown in App Store Connect.
- Add review contact details and keyboard setup/testing notes; no demo login is required for this app.
- Answer export-compliance questions based on the final build.
- Select uploaded build; resolve processing or validation messages.
- Choose manual release to control when an approved version goes live.
- Add for Review, then submit the submission to App Review. Respond to reviewer questions if needed.
- After approval, manually release and verify the listing/download.

## Draft listing copy (review before publishing)

Name: MorseBoard (availability not checked)

Subtitle: Your Morse Code keyboard

Tagline: Text in Morse!

Description:

Type Morse code with a keyboard made for dots and dashes.

Use two large keys to enter • and -, or switch to one key: tap for a dot and hold for a dash. Send the symbols themselves, or turn on letters mode to translate Morse sequences into A–Z and 0–9 as you type.

• Two-key and single-key layouts
• Symbols or decoded letters
• Adjustable timing from 5 to 30 WPM
• Space and delete keys
• Built-in setup guide, practice field, and Morse reference
• Works without Full Access
• No ads, accounts, or analytics

Enable MorseBoard in iPhone Settings, then select it using the globe key. Adjust layout, output and timing with the keyboard's gear button. In letters mode, a pause finishes each letter; invalid sequences are discarded. Word spaces are entered manually.

iOS uses its own keyboard in secure fields and certain other inputs. Some apps do not allow custom keyboards.

Draft review notes:

This app contains a custom Morse keyboard extension. No account or Full Access permission is required. Enable it in Settings > General > Keyboard > Keyboards > Add New Keyboard > MorseBoard. Open the containing app's practice field and switch to MorseBoard using the globe key. Default output is literal • and -. Use the gear to select one-key input or letters mode and adjust WPM. In letters mode, enter ... and pause to produce S. Unsupported Morse sequences intentionally produce no output.

## Sources

- https://developer.apple.com/programs/enroll/
- https://developer.apple.com/news/upcoming-requirements/
- https://developer.apple.com/app-store/review/guidelines/
- https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
- https://developer.apple.com/help/app-store-connect/
