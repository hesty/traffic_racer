#!/bin/bash
# Shared helpers for scripts/shorebird_release.sh and scripts/shorebird_patch.sh.
# Sourced, never executed on its own.

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_color() {
    printf "${2}${1}${NC}\n"
}

print_header() {
    echo ""
    print_color "========================================" "$BLUE"
    print_color "$1" "$BLUE"
    print_color "========================================" "$BLUE"
    echo ""
}

# Absolute path of the repository root, wherever the script was invoked from.
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

require_shorebird() {
    if ! command -v shorebird &> /dev/null; then
        print_color "Error: Shorebird CLI is not installed!" "$RED"
        print_color "Install it first: https://docs.shorebird.dev/getting-started" "$YELLOW"
        exit 1
    fi
}

# `shorebird account whoami` is the cheapest command that actually needs a
# session; `doctor` succeeds while logged out, which is why it is not used here.
require_auth() {
    local who
    if ! who=$(shorebird account whoami 2>&1); then
        print_color "Not authenticated with Shorebird." "$RED"
        print_color "Run: shorebird login" "$YELLOW"
        exit 1
    fi
    print_color "✓ Logged in as $(echo "$who" | grep -m1 '^Email:' | sed 's/Email: *//' | tr -d '\r')" "$GREEN"
}

# Turbo Traffic Rush is not a Shorebird project until `shorebird init` has
# written the app_id into shorebird.yaml (and pubspec.yaml lists it as an asset).
require_shorebird_project() {
    if [ ! -f "$PROJECT_ROOT/shorebird.yaml" ]; then
        print_color "Error: shorebird.yaml not found in $PROJECT_ROOT" "$RED"
        print_color "This project has not been initialised for Shorebird yet." "$YELLOW"
        print_color "Run once, from the project root: shorebird init" "$YELLOW"
        exit 1
    fi
    if ! grep -q "shorebird.yaml" "$PROJECT_ROOT/pubspec.yaml"; then
        print_color "⚠ shorebird.yaml is not listed under flutter/assets in pubspec.yaml." "$YELLOW"
        print_color "  The updater cannot read the app_id at runtime without it." "$YELLOW"
    fi
    print_color "✓ App: $(grep '^app_id:' "$PROJECT_ROOT/shorebird.yaml" | sed 's/app_id: *//')" "$GREEN"
}

# "2.0.2+11" straight out of pubspec.yaml — the release version Shorebird keys
# patches on, so it is never invented by these scripts.
project_version() {
    grep "^version:" "$PROJECT_ROOT/pubspec.yaml" | head -1 | sed 's/version: *//' | tr -d '\r'
}

# The RevenueCat SDK keys are baked into lib/services/revenuecat_keys.dart, so a
# normal build needs no dart-defines at all. Two optional overrides, in order of
# precedence, point a build at a different RevenueCat project:
#   1. dart_defines.<platform>.json in the project root (git-ignored)
#   2. RC_ANDROID_KEY / RC_IOS_KEY in the environment
# Result lands in the DART_DEFINE_ARGS array.
DART_DEFINE_ARGS=()
resolve_dart_defines() {
    local platform=$1
    local file="$PROJECT_ROOT/dart_defines.$platform.json"
    DART_DEFINE_ARGS=()

    if [ -f "$file" ]; then
        DART_DEFINE_ARGS=(--dart-define-from-file="$file")
        print_color "dart-defines: dart_defines.$platform.json" "$CYAN"
        return 0
    fi

    case "$platform" in
        android)
            if [ -n "$RC_ANDROID_KEY" ]; then
                DART_DEFINE_ARGS=(--dart-define=RC_ANDROID_KEY="$RC_ANDROID_KEY")
            fi
            ;;
        ios)
            if [ -n "$RC_IOS_KEY" ]; then
                DART_DEFINE_ARGS=(--dart-define=RC_IOS_KEY="$RC_IOS_KEY")
            fi
            ;;
    esac

    if [ ${#DART_DEFINE_ARGS[@]} -gt 0 ]; then
        print_color "dart-defines: RevenueCat key overridden from the environment" "$CYAN"
    else
        print_color "dart-defines: none (using lib/services/revenuecat_keys.dart)" "$CYAN"
    fi
    return 0
}

confirm() {
    local answer
    read -r -p "$1 (y/n): " answer
    [ "$answer" = "y" ] || [ "$answer" = "Y" ]
}
