#!/usr/bin/env bash

set -euo pipefail

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
TARGET="${1:-}"

if [[ -z "$TARGET" ]]; then
  echo "Usage: ./build.sh [dev|prod]"
  exit 1
fi

if [[ "$TARGET" != "dev" && "$TARGET" != "prod" ]]; then
  echo -e "${RED}❌ Invalid target:${RESET} $TARGET (expected dev|prod)"
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
    fail_step "⚙️" "Switching environment to prod" "Could not update Environment in $SETTINGS_FILE."
  fi

  run_step "⚙️" "Switching environment to prod" true
  info "settings.dart updated temporarily (dev → prod)"
else
  run_step "⚙️" "Switching environment to prod" true
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
# 10) Restore
# -----------------------------
run_step "🔄" "Restoring edited files" restore_now
info "pubspec / settings / generated icons restored"

run_step "🎉" "Build completed ($TARGET)" true
