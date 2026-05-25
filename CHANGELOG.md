# Changelog

This Changelog is inspired by the principles of [Common Changelog](https://common-changelog.org).

## Unreleased

### Changed

- Change the Flutter SDK version to 3.44.0
- Lower the XP requirement per level by flattening the growth curve
- Double the base XP gain for system events (USB, charger, external display, headphones)
- Raise the pet base XP gain from 2 to 5

## 1.4.0 - 2026-05-17

### Changed

- Restyle the Friday/Corporate pill in the top row as an icon-only accent-coloured chip matching the new "Ne pas déranger" button, so the three top-row chips share one visual language
- Scale the pet XP gain with the system volume, with a non-zero floor when the system is muted so petting still grants a small amount of XP
- Grant 1.5× XP in Friday mode for events that play a random sound (USB, charger, external display, headphones); the pet action is unaffected
- Average the system volume over each sound's playback duration when computing XP, instead of reading the instantaneous volume at event time, so muting mid-playback no longer awards full XP
- Couple pet XP to pet cry playback: XP is now granted on cry completion using the cry's average volume, replacing the previously independent pet XP cooldown
- Exclude the 3 most recently played sounds per mode from random selection to reduce perceived repetition

### Added

- Add a "Notifications" toggle in the options dialog: when enabled (and notification permission granted via `UNUserNotificationCenter`), Anchwatt fires a macOS local notification on Anchwatt level-ups (only when the window is hidden into the status bar and the silent mode is off), and on calendar-driven silent mode transitions (only when caused by the real start or end of a meeting, never by a manual override); clicking any notification restores the main window from the status bar
- Add an "auto-mute during meetings" toggle in the options dialog: when enabled, Anchwatt watches macOS Calendar via EventKit and turns the "Ne pas déranger" mode on automatically while a busy (non all-day) event is in progress; toggling the silent mode off during such an event opts out for the remainder of that event only, the next event re-engages the mute naturally
- Add a "Launch at login" toggle in the options dialog: when enabled, Anchwatt registers as a macOS background login item via `SMAppService` and starts silently in the status bar at the next session opening, with the window hidden until the icon is clicked
- Add a "Ne pas déranger" mode togglable from the options dialog and a dedicated app-bar chip, which cuts any in-flight sound the moment it turns on and gates incoming system events so neither sounds nor XP are awarded while it is active; state is persisted between launches
- Add an options dialog accessible from the app bar, exposing app info, the Friday/Corporate mode toggle with descriptions, a GitHub repository link, and a manual update check

## 1.3.0 - 2026-05-05

### Added

- Add new bamboozling sounds

## 1.2.0 - 2026-05-04

### Changed

- Move the update, system volume and sound mode badges to a dedicated top row in the Anchwatt view to avoid overlapping the level number and give the layout more breathing room
- Rename the home view to the Anchwatt view (file, classes, route and l10n keys) so `lib/main/` reflects the project's main feature
- Scale XP per event with the player level and the system volume
- Remove `AnchwattSettings.xpPerEvent`
- Introduce `AnchwattEventType` enum and `xpForEvent(...)` to support future event types
- Switch the USB event debounce to leading-edge so the sound plays on the first native event, with a 1500ms window wide enough to absorb the connect/disconnect/reconnect handshake some USB devices (notably iPhones) emit during enumeration

### Added

- Add a background mode that hides the window into a menu-bar status item when the user closes it via the red traffic-light, with a left-click to restore and a right-click "Quitter Anchwatt" menu
- Add a sound mode toggle (Corporate / Friday) in the Anchwatt view's top-right pill, persisting the chosen mode and filtering random sound playback to that mode's folder
- Add GitHub issues and pull requests templates
- Change the Flutter SDK version to 3.41.9
- Add an ephemeral `+{n}xp` floater shown above the XP gauge when XP is gained, with fade-in/out and rise animation
- Pet Anchwatt: hold click and drag on the sprite to gain XP (independent random cooldown)
- Random cry of the current evolution played while petting (independent cooldown)
- Sparkle particle burst at cursor while petting
- Add `chargerToggle`: react to the laptop AC adapter being plugged or unplugged (no-op on desktop Macs without a battery), playing a sound and granting XP like `usbToggle`
- Add `externalDisplayToggle`: react to an external display being connected or disconnected (HDMI, USB-C video, DisplayPort, AirPlay, Sidecar), playing a sound and granting XP like `usbToggle`
- Add `headphonesToggle`: react to the audio output switching to or from headphones / earphones (3.5mm jack or Bluetooth audio device), playing a sound and granting XP like `usbToggle`
- Coalesce simultaneous system events within a 500 ms window so a single physical action — e.g. plugging in a USB-C dock — yields one sound and one XP gain instead of several

### Fixed

- Fix doubled and phantom USB sounds by deduplicating IOKit notifications per device registry entry ID

## 1.1.0 - 2026-04-28

### Changed

- Reduce the USB event debounce window from 1000ms to 750ms for snappier sound playback
- Change the macOS app icon
- Change the Flutter SDK version to 3.41.8

### Added

- Add a system volume pill in the home view that mirrors the macOS output volume and mute state in real time
- Add some flabbergasting sounds

## 1.0.0 - 2026-04-27

### Added

- Sign, notarize and staple the macOS app in `./build.sh prod`, producing a signed DMG ready for distribution (with a `--no-notarize` escape hatch for local pipeline tests)
- Add the base project structure and initial files
- Pin the Flutter SDK to 3.41.7 and the Dart SDK to 3.11.5
- Add the build script
- Add the macOS app icon
- Add the "Inter" font family
- Add a fixed 320×420 non-resizable macOS window with a borderless, immersive style (transparent title bar), centered on screen at launch
- Set the macOS app display name to "Anchwatt" across the Dock, Finder and menu bar
- Set the copyright holder to "Maxime Meurisse"
- Translate the macOS system menus (Apple menu, Édition, Présentation, Fenêtre, Aide) to French
- Add the home view with the Anchwatt sprite, level header and XP progress bar
- Add three evolutions — Anchwatt, Lampéroie (level 15) and Ohmassacre (level 40) — on a progressive XP curve, with a brief hold at 100% before each level-up
- Add a temporary debug button to increment XP for local testing of evolution transitions, hidden outside the dev environment
- Add a dev/prod `Environment` flag in `Settings` to gate developer-only UI
- Add `readInt`/`writeInt` and `readString`/`writeString` methods to `PrefsStorage`
- Add `AnchwattStorage` to persist level and XP across launches with schema versioning, loaded on boot and saved after every XP change
- Add `UsbEventService` to detect USB connect/disconnect events via IOKit
- Add `SoundService` to play random sounds from `assets/sounds/`
- Play a random sound and grant XP on every USB connect/disconnect event
- Add `UpdateService` to check the latest GitHub Release at boot, with a 2-hour cooldown
- Add `UpdateStorage` to cache update-check results
- Add an update-available badge in the top-right of the home view, opening the release page on click
- Declare `Settings.latestReleaseEndpoint` for the latest release API URL
- Enable `com.apple.security.network.client` in the macOS Debug and Release entitlements for the GitHub API call
