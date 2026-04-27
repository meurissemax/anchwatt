#!/usr/bin/env bash

set -euo pipefail

# -----------------------------
# Usage
# -----------------------------
# ./build.sh dev                  Local dev build (unsigned)
# ./build.sh prod                 Signed + notarized + stapled DMG
# ./build.sh prod --no-notarize   Signed DMG, skips Apple notarization

# -----------------------------
# Styling (ANSI colors)
# -----------------------------
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
DIM="\033[2m"
RESET="\033[0m"

# -----------------------------
# Helpers
# -----------------------------
STEP_WIDTH=44  # adjust padding so PASSED/FAILED align nicely

run_step() {
  local emoji="$1"
  local label="$2"
  shift 2

  # Left part (aligned)
  printf "%s %-*s" "$emoji" "$STEP_WIDTH" "$label"

  if "$@" > /dev/null 2>&1; then
    echo -e " ${GREEN}PASSED${RESET} ✅"
  else
    echo -e " ${RED}FAILED${RESET} ❌"
    exit 1
  fi
}

fail_step() {
  local emoji="$1"
  local label="$2"
  local message="$3"

  printf "%s %-*s" "$emoji" "$STEP_WIDTH" "$label"
  echo -e " ${RED}FAILED${RESET} ❌"
  echo -e "    ↳ ${DIM}${message}${RESET}"
  exit 1
}

info() {
  echo -e "    ↳ ${DIM}$1${RESET}"
}

# -----------------------------
# Args
# -----------------------------
TARGET=""
NOTARIZE=true

for arg in "$@"; do
  case "$arg" in
    dev|prod) TARGET="$arg" ;;
    --no-notarize) NOTARIZE=false ;;
    *)
      echo -e "${RED}❌ Unknown argument:${RESET} $arg"
      echo "Usage: ./build.sh [dev|prod] [--no-notarize]"
      exit 1
      ;;
  esac
done

if [[ -z "$TARGET" ]]; then
  echo "Usage: ./build.sh [dev|prod] [--no-notarize]"
  exit 1
fi

# Build flags (string; avoids bash-array nounset issues)
OBFUSCATE_ARGS=""
SYMBOLS_DIR="symbols"
if [[ "$TARGET" == "prod" ]]; then
  OBFUSCATE_ARGS="--obfuscate --split-debug-info=$SYMBOLS_DIR"
fi

# -----------------------------
# Files
# -----------------------------
PUBSPEC_FILE=""
if [[ -f "pubspec.yml" ]]; then
  PUBSPEC_FILE="pubspec.yml"
elif [[ -f "pubspec.yaml" ]]; then
  PUBSPEC_FILE="pubspec.yaml"
else
  fail_step "🧩" "Checking required files" "pubspec.yml/pubspec.yaml not found."
fi

SETTINGS_FILE="lib/settings.dart"
if [[ ! -f "$SETTINGS_FILE" ]]; then
  fail_step "🧩" "Checking required files" "$SETTINGS_FILE not found."
fi

# -----------------------------
# 1) Tooling checks
# -----------------------------
run_step "🔍" "Checking git command" command -v git
run_step "🔍" "Checking dart command" command -v dart
run_step "🔍" "Checking perl command" command -v perl
run_step "🔍" "Checking flutter command" command -v flutter

# -----------------------------
# 1.5) Signing prerequisites (prod only)
# -----------------------------
DEVELOPER_ID=""
NOTARY_PROFILE=""

if [[ "$TARGET" == "prod" ]]; then
  run_step "🔍" "Checking codesign command" command -v codesign
  run_step "🔍" "Checking xcrun command" command -v xcrun
  run_step "🔍" "Checking hdiutil command" command -v hdiutil
  run_step "🔍" "Checking security command" command -v security

  if [[ -n "${ANCHWATT_DEVELOPER_ID:-}" ]]; then
    DEVELOPER_ID="$ANCHWATT_DEVELOPER_ID"
    run_step "🔐" "Using Developer ID from env" true
    info "Identity: ${CYAN}${DEVELOPER_ID}${RESET}"
  else
    MATCHES=$(security find-identity -v -p codesigning | grep "Developer ID Application" || true)
    COUNT=$(echo -n "$MATCHES" | grep -c . || true)

    if [[ "$COUNT" -eq 0 ]]; then
      printf "%s %-*s" "🔐" "$STEP_WIDTH" "Resolving Developer ID identity"
      echo -e " ${RED}FAILED${RESET} ❌"
      info "No 'Developer ID Application' certificate in Keychain."
      info "1. Create one at developer.apple.com (team BL57QBUV6S)"
      info "2. Double-click the .cer to install"
      info "3. Verify: ${CYAN}security find-identity -v -p codesigning${RESET}"
      exit 1
    elif [[ "$COUNT" -gt 1 ]]; then
      printf "%s %-*s" "🔐" "$STEP_WIDTH" "Resolving Developer ID identity"
      echo -e " ${RED}FAILED${RESET} ❌"
      info "Multiple identities found:"
      echo "$MATCHES"
      info "Set ${CYAN}ANCHWATT_DEVELOPER_ID${RESET} to disambiguate."
      exit 1
    fi

    DEVELOPER_ID=$(echo "$MATCHES" | head -n1 | sed -E 's/.*"([^"]+)".*/\1/')
    run_step "🔐" "Auto-detected Developer ID identity" true
    info "Identity: ${CYAN}${DEVELOPER_ID}${RESET}"
  fi

  NOTARY_PROFILE="${ANCHWATT_NOTARY_PROFILE:-anchwatt-notary}"
  if [[ "$NOTARIZE" == true ]]; then
    if ! xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null 2>&1; then
      printf "%s %-*s" "🔐" "$STEP_WIDTH" "Checking notary keychain profile"
      echo -e " ${RED}FAILED${RESET} ❌"
      info "Profile '${YELLOW}${NOTARY_PROFILE}${RESET}' missing or invalid."
      info "Create it once with:"
      info "  ${CYAN}xcrun notarytool store-credentials \"${NOTARY_PROFILE}\" \\${RESET}"
      info "  ${CYAN}  --apple-id \"<your-apple-id>\" \\${RESET}"
      info "  ${CYAN}  --team-id \"BL57QBUV6S\" \\${RESET}"
      info "  ${CYAN}  --password \"<app-specific-password>\"${RESET}"
      info "Get an app-specific password at appleid.apple.com → Sign-In and Security."
      exit 1
    fi
    run_step "🔐" "Checking notary keychain profile" true
    info "Profile: ${CYAN}${NOTARY_PROFILE}${RESET}"
  fi
fi

# -----------------------------
# 2) Flutter version check (.fvmrc)
# -----------------------------
if [[ ! -f ".fvmrc" ]]; then
  fail_step "🔍" "Checking Flutter version (.fvmrc)" ".fvmrc file not found."
fi

EXPECTED_VERSION=$(grep -o '"flutter": *"[^"]*"' .fvmrc | sed 's/.*"flutter": *"\([^"]*\)".*/\1/')
if [[ -z "$EXPECTED_VERSION" ]]; then
  fail_step "🔍" "Checking Flutter version (.fvmrc)" "Could not read Flutter version from .fvmrc."
fi

INSTALLED_VERSION=$(flutter --version 2>/dev/null | head -n 1 | awk '{print $2}')
if [[ -z "$INSTALLED_VERSION" ]]; then
  fail_step "🔍" "Checking Flutter version" "Could not read installed Flutter version."
fi

if [[ "$EXPECTED_VERSION" != "$INSTALLED_VERSION" ]]; then
  printf "%s %-*s" "🔍" "$STEP_WIDTH" "Checking Flutter version"
  echo -e " ${RED}FAILED${RESET} ❌"
  info "Expected: ${YELLOW}$EXPECTED_VERSION${RESET}"
  info "Installed: ${YELLOW}$INSTALLED_VERSION${RESET}"
  info "Run: ${CYAN}fvm use $EXPECTED_VERSION${RESET}"
  exit 1
fi

run_step "🔍" "Checking Flutter version" true
info "Flutter: ${CYAN}$INSTALLED_VERSION${RESET}"

# -----------------------------
# 3) Git clean check (must be BEFORE temp edits)
# -----------------------------
run_step "🧹" "Checking git working tree clean" test -z "$(git status --porcelain)"

# -----------------------------
# Temp edits + restore (pubspec + settings + generated icons)
# -----------------------------
PUBSPEC_BACKUP="$(mktemp)"
cp "$PUBSPEC_FILE" "$PUBSPEC_BACKUP"

SETTINGS_BACKUP="$(mktemp)"
cp "$SETTINGS_FILE" "$SETTINGS_BACKUP"

restore_everything() {
  cp "$PUBSPEC_BACKUP" "$PUBSPEC_FILE" 2>/dev/null || true
  cp "$SETTINGS_BACKUP" "$SETTINGS_FILE" 2>/dev/null || true

  # Restore generated platform icons to repo state (tracked files only)
  git restore --quiet macos/Runner/Assets.xcassets/AppIcon.appiconset 2>/dev/null || true

  rm -f "$PUBSPEC_BACKUP" 2>/dev/null || true
  rm -f "$SETTINGS_BACKUP" 2>/dev/null || true
}

# Always restore on exit (success or failure)
trap restore_everything EXIT

# Allows doing an explicit restore step at the end (while keeping trap as safety net)
restore_now() {
  restore_everything
  # Avoid double “restore” attempts after explicit restore
  trap - EXIT
}

# -----------------------------
# 4) Dependencies
# -----------------------------
run_step "📦" "Fetching dependencies" flutter pub get

# -----------------------------
# 5) Launcher icons
# -----------------------------
if [[ "$TARGET" == "prod" ]]; then
  PROD_ICON="assets/images/icons/app/icon__app.png"

  if [[ ! -f "$PROD_ICON" ]]; then
    fail_step "🎨" "Preparing prod launcher icon" "Missing: $PROD_ICON"
  fi

  perl -i -pe '
    s|(image_path:\s*.*)icon__app--dev\.png|${1}icon__app.png|;
  ' "$PUBSPEC_FILE"

  if grep -q "icon__app--dev\.png" "$PUBSPEC_FILE"; then
    fail_step "🎨" "Preparing prod launcher icon" "Could not update flutter_launcher_icons path in $PUBSPEC_FILE."
  fi

  run_step "🎨" "Generating launcher icons (prod)" dart run flutter_launcher_icons
  info "pubspec updated temporarily (dev → prod icon)"
else
  run_step "🎨" "Generating launcher icons (dev)" true
  info "Skipped (dev keeps existing dev icons)"
fi

# -----------------------------
# 6) Settings environment
# -----------------------------
if [[ "$TARGET" == "prod" ]]; then
  perl -i -pe '
    s|(static const Environment environment\s*=\s*)Environment\.dev|${1}Environment.prod|;
  ' "$SETTINGS_FILE"

  if ! grep -q "environment = Environment.prod" "$SETTINGS_FILE"; then
    fail_step "🌐" "Switching environment to prod" "Could not update Environment in $SETTINGS_FILE."
  fi

  run_step "🌐" "Switching environment to prod" true
  info "settings.dart updated temporarily (dev → prod)"
else
  run_step "🌐" "Switching environment to prod" true
  info "Skipped (dev keeps Environment.dev)"
fi

# -----------------------------
# 7) Analyze
# -----------------------------
run_step "🔎" "Running analyze" flutter analyze

# -----------------------------
# 8) Tests
# -----------------------------
run_step "🧪" "Running tests" flutter test

# -----------------------------
# 9) Build (macOS)
# -----------------------------
run_step "🧹" "Cleaning" flutter clean
run_step "📦" "Fetching dependencies" flutter pub get

if [[ "$TARGET" == "prod" ]]; then
  run_step "🧩" "Preparing symbols directory" mkdir -p "$SYMBOLS_DIR"
fi

# shellcheck disable=SC2086
run_step "🚀" "Building macOS app ($TARGET)" flutter build macos --release $OBFUSCATE_ARGS
info "Output: ${CYAN}build/macos/Build/Products/Release/${RESET}"

# -----------------------------
# 10) Codesign (prod only)
# -----------------------------
APP_PATH="build/macos/Build/Products/Release/anchwatt.app"
DMG_PATH=""

if [[ "$TARGET" == "prod" ]]; then
  ENTITLEMENTS="macos/Runner/Release.entitlements"

  if [[ ! -d "$APP_PATH" ]]; then
    fail_step "🔏" "Code-signing app" "Missing $APP_PATH (build did not produce it)."
  fi

  rm -rf dist
  mkdir -p dist

  run_step "🔏" "Code-signing .app (Developer ID + hardened)" \
    codesign --force --deep --timestamp \
      --options runtime \
      --entitlements "$ENTITLEMENTS" \
      --sign "$DEVELOPER_ID" \
      "$APP_PATH"

  run_step "🔎" "Verifying codesign" \
    codesign --verify --deep --strict --verbose=2 "$APP_PATH"
fi

# -----------------------------
# 11) DMG packaging + signing (prod only)
# -----------------------------
if [[ "$TARGET" == "prod" ]]; then
  VERSION=$(grep -E '^version:' "$PUBSPEC_FILE" | sed -E 's/version:[[:space:]]*([^+]+).*/\1/' | tr -d '[:space:]')
  DMG_NAME="anchwatt-${VERSION}.dmg"
  DMG_PATH="dist/${DMG_NAME}"
  STAGING_DIR="$(mktemp -d)"

  cp -R "$APP_PATH" "$STAGING_DIR/"
  ln -s /Applications "$STAGING_DIR/Applications"

  run_step "💿" "Creating DMG" \
    hdiutil create \
      -volname "Anchwatt ${VERSION}" \
      -srcfolder "$STAGING_DIR" \
      -ov -format UDZO \
      "$DMG_PATH"

  rm -rf "$STAGING_DIR"

  run_step "🔏" "Code-signing DMG" \
    codesign --force --timestamp --sign "$DEVELOPER_ID" "$DMG_PATH"

  info "DMG: ${CYAN}${DMG_PATH}${RESET}"
fi

# -----------------------------
# 12) Notarize + staple (prod only, skipped if --no-notarize)
# -----------------------------
if [[ "$TARGET" == "prod" && "$NOTARIZE" == true ]]; then
  info "Submitting to Apple notary service (this can take 1-15 minutes)..."

  NOTARY_OUTPUT="$(mktemp)"
  if ! xcrun notarytool submit "$DMG_PATH" \
        --keychain-profile "$NOTARY_PROFILE" \
        --wait \
        --output-format plist \
        > "$NOTARY_OUTPUT" 2>&1; then
    printf "%s %-*s" "📨" "$STEP_WIDTH" "Notarizing DMG"
    echo -e " ${RED}FAILED${RESET} ❌"
    cat "$NOTARY_OUTPUT"
    rm -f "$NOTARY_OUTPUT"
    exit 1
  fi

  SUBMISSION_ID=$(/usr/libexec/PlistBuddy -c "Print :id" "$NOTARY_OUTPUT" 2>/dev/null || echo "")
  STATUS=$(/usr/libexec/PlistBuddy -c "Print :status" "$NOTARY_OUTPUT" 2>/dev/null || echo "")
  rm -f "$NOTARY_OUTPUT"

  if [[ "$STATUS" != "Accepted" ]]; then
    printf "%s %-*s" "📨" "$STEP_WIDTH" "Notarizing DMG"
    echo -e " ${RED}FAILED${RESET} ❌"
    info "Status: ${YELLOW}${STATUS}${RESET}"
    info "Submission ID: ${CYAN}${SUBMISSION_ID}${RESET}"
    info "Fetching notary log..."
    xcrun notarytool log "$SUBMISSION_ID" --keychain-profile "$NOTARY_PROFILE" || true
    exit 1
  fi

  run_step "📨" "Notarizing DMG" true
  info "Status: ${GREEN}${STATUS}${RESET} (id ${SUBMISSION_ID})"

  run_step "📎" "Stapling notarization ticket" \
    xcrun stapler staple "$DMG_PATH"

  xcrun stapler staple "$APP_PATH" >/dev/null 2>&1 || true
elif [[ "$TARGET" == "prod" && "$NOTARIZE" == false ]]; then
  run_step "📨" "Notarizing DMG" true
  info "Skipped (--no-notarize). DMG is signed but NOT notarized — do not ship."
fi

# -----------------------------
# 13) Final verification (prod only)
# -----------------------------
if [[ "$TARGET" == "prod" && "$NOTARIZE" == true ]]; then
  run_step "🔒" "Gatekeeper assess (DMG)" \
    spctl --assess --type open --context context:primary-signature "$DMG_PATH"

  run_step "🔒" "Gatekeeper assess (.app)" \
    spctl --assess --type execute "$APP_PATH"

  run_step "📎" "Validating stapled ticket" \
    xcrun stapler validate "$DMG_PATH"
fi

# -----------------------------
# 14) Restore
# -----------------------------
run_step "🔄" "Restoring edited files" restore_now
info "pubspec / settings / generated icons restored"

if [[ "$TARGET" == "prod" ]]; then
  info "Artifact: ${CYAN}${DMG_PATH}${RESET}"
  if [[ "$NOTARIZE" == true ]]; then
    info "Ready for: ${CYAN}distribution${RESET}"
  fi
fi

run_step "🎉" "Build completed ($TARGET)" true
