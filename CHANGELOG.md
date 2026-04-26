# Changelog

This Changelog is inspired by the principles of [Common Changelog](https://common-changelog.org).

## Unreleased

### Added

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
- Add a temporary debug button to increment XP for local testing of evolution transitions
- Add a dev/prod `Environment` flag in `Settings` to gate developer-only UI
- Add `readInt`/`writeInt` methods to `PrefsStorage`
- Add `AnchwattStorage` to persist level and XP across launches with schema versioning
- Add `UsbEventService` to detect USB connect/disconnect events via IOKit
- Add `SoundService` to play random sounds from `assets/sounds/`
- Play a random sound and grant XP on every USB connect/disconnect event

### Changed

- Hide the debug XP button outside the dev environment
- Load and persist the Anchwatt progression in `HomeViewModel` on boot and after every XP change
