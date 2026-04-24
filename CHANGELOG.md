# Changelog

This Changelog is inspired by the principles of [Common Changelog](https://common-changelog.org).

## Unreleased

### Changed

- Change the Flutter version to 3.41.7
- Change the Dart SDK version to 3.11.5
- Change the macOS window to a fixed 320x420 non-resizable size
- Change the home view internals to use centralized styling tokens and granular `Selector` state observation
- Replace the Anchwatt growth stages (baby/normal/mega) with proper evolutions (Anchwatt, Lampéroie, Ohmassacre) and their dedicated sprites
- Apply a progressive XP curve — early levels ramp fast, high levels require substantially more XP
- Move the evolution thresholds to level 15 (Lampéroie) and level 40 (Ohmassacre)
- Hold the XP progress bar at 100% briefly before applying the level-up
- Set the macOS window title to "Anchwatt"

### Added

- Add the base project structure and initial files
- Add the macOS app icon
- Add the "Inter" font family
- Add the build script
- Add the home view with the Anchwatt sprite, level, XP progress bar and evolution stages
- Add a temporary debug button to increment XP for local testing of stage transitions
