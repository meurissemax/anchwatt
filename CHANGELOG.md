# Changelog

This Changelog is inspired by the principles of [Common Changelog](https://common-changelog.org).

## Unreleased

### Changed

- Rename the home view to the Anchwatt view (file, classes, route and l10n keys) so `lib/main/` reflects the project's main feature

### Added

- Add a sound mode toggle (Corporate / Friday) in the Anchwatt view's top-right pill, persisting the chosen mode and filtering random sound playback to that mode's folder
- Add GitHub issues and pull requests templates
- Change the Flutter SDK version to 3.41.9

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
