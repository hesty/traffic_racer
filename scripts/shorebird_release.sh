#!/bin/bash
#
# Shorebird release helper for Turbo Traffic Rush (turbo_traffic_rush).
#
# Builds a store artifact with the Shorebird engine and registers it as a
# release, so later code-only fixes can ship as patches instead of a store
# review. Run it from anywhere: ./scripts/shorebird_release.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/shorebird_common.sh
source "$SCRIPT_DIR/lib/shorebird_common.sh"

ENTRY_POINT="lib/main.dart"
RELEASES_DIR="releases"

print_header "Turbo Traffic Rush — Shorebird Release"

require_shorebird
require_auth
cd "$PROJECT_ROOT"
require_shorebird_project

RELEASE_VERSION=$(project_version)
print_color "Version in pubspec.yaml: $RELEASE_VERSION" "$GREEN"

echo ""
echo "Select platform:"
echo "1) Android"
echo "2) iOS"
echo "3) Both"
read -r -p "Enter choice (1-3): " PLATFORM_CHOICE
case $PLATFORM_CHOICE in
    1|2|3) ;;
    *)
        print_color "Invalid choice: $PLATFORM_CHOICE" "$RED"
        exit 1
        ;;
esac

# Android ships as an AAB to Play; APK is only for sideloading a build onto a
# test device.
ARTIFACT_ARGS=()
ARTIFACT_LABEL="AAB"
ANDROID_EXT="aab"
if [ "$PLATFORM_CHOICE" != "2" ]; then
    echo ""
    echo "Android artifact type:"
    echo "1) AAB (default - for Play Store)"
    echo "2) APK (for direct distribution)"
    read -r -p "Enter choice (1-2): " ARTIFACT_CHOICE
    if [ "$ARTIFACT_CHOICE" = "2" ]; then
        ARTIFACT_ARGS=(--artifact apk)
        ARTIFACT_LABEL="APK"
        ANDROID_EXT="apk"
    fi
fi

# The release is the baseline every future patch diffs against; a red test suite
# baked into a release is a store round-trip to undo.
print_header "Static Checks"
if confirm "Run flutter analyze + flutter test first?"; then
    flutter analyze
    flutter test
    print_color "✓ Analyze and tests passed" "$GREEN"
else
    print_color "⚠ Skipped analyze/test" "$YELLOW"
fi

print_header "Release Configuration"
print_color "Version:  $RELEASE_VERSION (from pubspec.yaml)" "$YELLOW"
case $PLATFORM_CHOICE in
    1) print_color "Platform: Android ($ARTIFACT_LABEL)" "$YELLOW" ;;
    2) print_color "Platform: iOS" "$YELLOW" ;;
    3) print_color "Platform: Android ($ARTIFACT_LABEL) & iOS" "$YELLOW" ;;
esac
print_color "Entry:    $ENTRY_POINT" "$YELLOW"
print_color "Note: to change the version, edit pubspec.yaml and re-run." "$CYAN"

echo ""
if ! confirm "Proceed with release?"; then
    print_color "Release cancelled." "$RED"
    exit 0
fi

print_header "Cleaning Build Artifacts"
flutter clean
flutter pub get

mkdir -p "$RELEASES_DIR"

copy_android_artifact() {
    local name candidates=()
    if [ "$ARTIFACT_LABEL" = "APK" ]; then
        name="turbo-traffic-rush-${RELEASE_VERSION}.apk"
        candidates=(
            "build/app/outputs/flutter-apk/app-release.apk"
            "build/app/outputs/apk/release/app-release.apk"
        )
    else
        name="turbo-traffic-rush-${RELEASE_VERSION}.aab"
        candidates=("build/app/outputs/bundle/release/app-release.aab")
    fi

    local path
    for path in "${candidates[@]}"; do
        if [ -f "$path" ]; then
            cp "$path" "$RELEASES_DIR/$name"
            print_color "✓ Artifact copied to: $RELEASES_DIR/$name" "$GREEN"
            return 0
        fi
    done
    print_color "⚠ Warning: Android artifact not found (looked in ${candidates[*]})" "$YELLOW"
}

copy_ios_artifact() {
    local name="turbo-traffic-rush-${RELEASE_VERSION}.ipa"
    local f
    for f in build/ios/ipa/*.ipa; do
        if [ -f "$f" ]; then
            cp "$f" "$RELEASES_DIR/$name"
            print_color "✓ Artifact copied to: $RELEASES_DIR/$name" "$GREEN"
            return 0
        fi
    done
    print_color "⚠ Warning: IPA not found in build/ios/ipa/" "$YELLOW"
}

release_android() {
    print_header "Creating Android Release"
    resolve_dart_defines "android"
    shorebird release -p android --target "$ENTRY_POINT" \
        "${ARTIFACT_ARGS[@]}" "${DART_DEFINE_ARGS[@]}"
    copy_android_artifact
}

release_ios() {
    print_header "Creating iOS Release"
    resolve_dart_defines "ios"
    shorebird release -p ios --target "$ENTRY_POINT" "${DART_DEFINE_ARGS[@]}"
    copy_ios_artifact
}

case $PLATFORM_CHOICE in
    1) release_android ;;
    2) release_ios ;;
    3)
        release_android
        release_ios
        ;;
esac

print_header "Release Complete!"
print_color "✅ Release $RELEASE_VERSION created successfully!" "$GREEN"
echo ""
print_color "📦 Build artifacts in $RELEASES_DIR/:" "$GREEN"
ls -la "$RELEASES_DIR"/*"$RELEASE_VERSION"* 2>/dev/null || true
echo ""
print_color "Next steps:" "$YELLOW"
print_color "1. Test the release build on a physical device (portrait-only, tilt steering)" "$NC"
case $PLATFORM_CHOICE in
    1) print_color "2. Upload to Play Console: $RELEASES_DIR/turbo-traffic-rush-${RELEASE_VERSION}.$ANDROID_EXT" "$NC" ;;
    2) print_color "2. Upload to App Store Connect: $RELEASES_DIR/turbo-traffic-rush-${RELEASE_VERSION}.ipa" "$NC" ;;
    3)
        print_color "2. Upload to Play Console + App Store Connect from $RELEASES_DIR/" "$NC"
        ;;
esac
print_color "3. Verify the Turbo Pass paywall against live RevenueCat products" "$NC"
print_color "4. Ship code-only fixes with: ./scripts/shorebird_patch.sh" "$NC"
echo ""
print_color "Console: https://console.shorebird.dev" "$BLUE"
