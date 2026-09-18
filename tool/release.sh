#!/usr/bin/env bash
# Builds, signs and ships MeshCore SAR for macOS and iOS.
#
#   ./tool/release.sh macos            # → dist/meshcore-sar-v<version>-macos.dmg
#   ./tool/release.sh ios              # → TestFlight, through the lanes in ios/fastlane
#   ./tool/release.sh all
#   ./tool/release.sh macos --dry-run  # resolve credentials + version, build nothing
#
# Credentials come from the environment, so the same script runs on a laptop and
# in CI with nothing changed. Locally, put them in tool/.release.env (gitignored,
# sourced automatically); in GitHub Actions they arrive as repository secrets.
#
#   MACOS_CERT_P12        base64 of the "Developer ID Application" .p12
#   MACOS_CERT_PASSWORD   password for that .p12
#   MACOS_SIGN_ID         e.g. "Developer ID Application: Name (JND55328G8)"
#   IOS_CERT_P12          base64 of the "Apple Distribution" .p12
#   IOS_CERT_PASSWORD     password for that .p12
#   ASC_KEY_ID            App Store Connect API key id
#   ASC_ISSUER_ID         App Store Connect issuer id
#   ASC_KEY_P8            base64 of the AuthKey_<ASC_KEY_ID>.p8
#   APPLE_TEAM_ID         optional, defaults to JND55328G8
#   IOS_PROFILE           optional base64 .mobileprovision; without it the API
#                         key fetches the profile via -allowProvisioningUpdates
#
# One App Store Connect key covers both halves: notarytool notarizes the DMG
# with it and altool uploads the IPA with it. The certificates never touch the
# login keychain — they are imported into a throwaway keychain that the exit
# trap deletes along with the decoded private key, whether the build succeeds or
# fails.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR"
DIST="$APP_DIR/dist"
ENV_FILE="$APP_DIR/tool/.release.env"

say()  { printf '→ %s\n' "$*"; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------- arguments --

COMMAND=""
VERSION=""
BUILD_NUMBER=""
DRY_RUN=0

usage() {
  sed -n '2,31p' "${BASH_SOURCE[0]}" | sed 's/^#\{1\} \{0,1\}//'
  exit "${1:-0}"
}

[ $# -gt 0 ] || usage 1
case "$1" in
  macos|ios|all) COMMAND="$1"; shift ;;
  -h|--help)     usage ;;
  *)             die "unknown command '$1' (expected macos, ios or all)" ;;
esac

while [ $# -gt 0 ]; do
  case "$1" in
    --version) VERSION="${2:-}"; shift 2 ;;
    --build)   BUILD_NUMBER="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage ;;
    *)         die "unknown option '$1'" ;;
  esac
done

# -------------------------------------------------------------- credentials --

if [ -f "$ENV_FILE" ]; then
  say "credentials from tool/.release.env"
  set -a; # shellcheck disable=SC1090
  . "$ENV_FILE"; set +a
fi

APPLE_TEAM_ID="${APPLE_TEAM_ID:-JND55328G8}"

# Names every missing variable at once — a build that dies on the fourth secret
# after twelve minutes of compiling is a waste of a coffee break.
require() {
  local missing=()
  for name in "$@"; do
    [ -n "${!name:-}" ] || missing+=("$name")
  done
  if [ ${#missing[@]} -gt 0 ]; then
    printf 'error: missing credentials: %s\n' "${missing[*]}" >&2
    printf '       set them in %s or in the environment\n' "${ENV_FILE#"$ROOT_DIR"/}" >&2
    exit 1
  fi
}

case "$COMMAND" in
  macos) require MACOS_CERT_P12 MACOS_CERT_PASSWORD MACOS_SIGN_ID ASC_KEY_ID ASC_ISSUER_ID ASC_KEY_P8 ;;
  ios)   require IOS_CERT_P12 IOS_CERT_PASSWORD ASC_KEY_ID ASC_ISSUER_ID ASC_KEY_P8 ;;
  all)   require MACOS_CERT_P12 MACOS_CERT_PASSWORD MACOS_SIGN_ID \
                 IOS_CERT_P12 IOS_CERT_PASSWORD ASC_KEY_ID ASC_ISSUER_ID ASC_KEY_P8 ;;
esac

# ------------------------------------------------------------------ version --

# pubspec.yaml carries the version `make bump` wrote. Its +build is a starting
# floor only: the iOS lane asks TestFlight what it has already accepted and
# takes whichever number is higher, so a release never needs a bump first.
if [ -z "$VERSION" ]; then
  VERSION="$(awk -F'[ +]' '/^version:/ {print $2}' "$APP_DIR/pubspec.yaml")"
fi
if [ -z "$BUILD_NUMBER" ]; then
  BUILD_NUMBER="$(awk -F'+' '/^version:/ {print $2}' "$APP_DIR/pubspec.yaml")"
fi
[ -n "$BUILD_NUMBER" ] || BUILD_NUMBER=0

# ------------------------------------------------------------------ flutter --

# mise.toml pins the SDK this project builds with; a bare `flutter` on PATH is
# some other version.
cd "$APP_DIR"
if command -v mise >/dev/null 2>&1 && [ -f "$ROOT_DIR/mise.toml" ]; then
  flutter() { mise exec -- flutter "$@"; }
else
  command -v flutter >/dev/null 2>&1 || die "flutter not found (install mise, or put flutter on PATH)"
fi

# ------------------------------------------------------- keychain + api key --

KEYCHAIN=""
WORK=""
KEYCHAINS_BEFORE=""

cleanup() {
  if [ -n "$KEYCHAIN" ]; then
    security delete-keychain "$KEYCHAIN" 2>/dev/null || true
    # Putting the search list back matters on a laptop, where the list the
    # build borrowed is the one the rest of the session depends on.
    if [ -n "$KEYCHAINS_BEFORE" ]; then
      # shellcheck disable=SC2086
      security list-keychains -d user -s $KEYCHAINS_BEFORE 2>/dev/null || true
    fi
  fi
  [ -n "$WORK" ] && rm -rf "$WORK" || true
}
trap cleanup EXIT

# Imports a .p12 into a keychain created for this run only. The partition list
# is what stops codesign from popping a UI prompt on a headless runner.
open_keychain() {
  [ -n "$KEYCHAIN" ] && return 0
  KEYCHAIN="meshcore-release.keychain"
  local pw; pw="$(uuidgen)"
  security delete-keychain "$KEYCHAIN" 2>/dev/null || true
  security create-keychain -p "$pw" "$KEYCHAIN"
  security set-keychain-settings -lut 21600 "$KEYCHAIN"
  security unlock-keychain -p "$pw" "$KEYCHAIN"
  KEYCHAINS_BEFORE="$(security list-keychains -d user | tr -d '"' | tr '\n' ' ')"
  # shellcheck disable=SC2086
  security list-keychains -d user -s "$KEYCHAIN" $KEYCHAINS_BEFORE
  KEYCHAIN_PW="$pw"
}

import_cert() {
  local b64="$1" password="$2" label="$3"
  open_keychain
  printf '%s' "$b64" | base64 --decode > "$WORK/cert.p12"
  security import "$WORK/cert.p12" -k "$KEYCHAIN" -P "$password" \
    -T /usr/bin/codesign -T /usr/bin/security >/dev/null
  security set-key-partition-list -S apple-tool:,apple:,codesign: \
    -s -k "$KEYCHAIN_PW" "$KEYCHAIN" >/dev/null
  rm -f "$WORK/cert.p12"
  say "imported $label certificate"
}

WORK="$(mktemp -d -t meshcore-release)"
KEY_FILE="$WORK/AuthKey_${ASC_KEY_ID}.p8"
printf '%s' "$ASC_KEY_P8" | base64 --decode > "$KEY_FILE"
chmod 600 "$KEY_FILE"
# altool looks the key up by id in a directory; notarytool takes the path.
export API_PRIVATE_KEYS_DIR="$WORK"

# -------------------------------------------------------------------- macos --

build_macos() {
  say "macOS $VERSION ($BUILD_NUMBER)"
  import_cert "$MACOS_CERT_P12" "$MACOS_CERT_PASSWORD" "Developer ID"

  flutter build macos --release \
    --build-name="$VERSION" --build-number="$BUILD_NUMBER"

  local app
  app="$(find "$APP_DIR/build/macos/Build/Products/Release" -maxdepth 1 -name '*.app' | head -1)"
  [ -n "$app" ] || die "no .app in build/macos/Build/Products/Release"

  # Sign inside out: nested code first, then the bundle. --force drops the
  # entitlements Xcode baked in, so hand them back on the outer signature or the
  # sandboxed app launches without network access.
  say "signing $(basename "$app")"
  while IFS= read -r nested; do
    codesign --force --options runtime --timestamp \
      --sign "$MACOS_SIGN_ID" "$nested"
  done < <(find "$app/Contents" -depth \( -name '*.framework' -o -name '*.dylib' \) -print 2>/dev/null)

  codesign --force --options runtime --timestamp \
    --entitlements "$APP_DIR/macos/Runner/Release.entitlements" \
    --sign "$MACOS_SIGN_ID" "$app"
  codesign --verify --strict --verbose=2 "$app"

  mkdir -p "$DIST"
  local dmg="$DIST/meshcore-sar-v$VERSION-macos.dmg"
  say "packaging $(basename "$dmg")"
  rm -f "$dmg"
  hdiutil create -volname "MeshCore SAR" -srcfolder "$app" -ov -format UDZO "$dmg" >/dev/null

  say "notarizing (this waits on Apple)"
  xcrun notarytool submit "$dmg" \
    --key "$KEY_FILE" --key-id "$ASC_KEY_ID" --issuer "$ASC_ISSUER_ID" --wait

  xcrun stapler staple "$app"
  xcrun stapler staple "$dmg"
  xcrun stapler validate "$dmg"
  spctl --assess --type exec -vv "$app"
  say "done: ${dmg#"$ROOT_DIR"/}"
}

# ---------------------------------------------------------------------- ios --

build_ios() {
  say "iOS $VERSION ($BUILD_NUMBER)"
  import_cert "$IOS_CERT_P12" "$IOS_CERT_PASSWORD" "Apple Distribution"

  if [ -n "${IOS_PROFILE:-}" ]; then
    local dir="$HOME/Library/MobileDevice/Provisioning Profiles"
    mkdir -p "$dir"
    printf '%s' "$IOS_PROFILE" | base64 --decode > "$dir/meshcore-release.mobileprovision"
    say "installed provisioning profile"
  fi

  # --config-only just refreshes Generated.xcconfig; the Flutter build itself
  # happens inside the Xcode build phase when fastlane archives. This is the
  # sequence `make release-ios` has always used.
  flutter build ios --release --no-codesign --config-only \
    --build-name="$VERSION" --build-number="$BUILD_NUMBER"

  [ -f "$APP_DIR/ios/Gemfile.lock" ] || die "run 'bundle install' in ios/ first"

  say "archiving and uploading through the ios/fastlane lanes"
  mkdir -p "$DIST"
  # fastlane refuses to handle non-ASCII metadata without a UTF-8 locale, and
  # a CI runner's locale is whatever the image felt like.
  export LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
  export FASTLANE_SKIP_UPDATE_CHECK=1
  export ASC_KEY_ID ASC_ISSUER_ID ASC_KEY_P8 APPLE_TEAM_ID
  export RELEASE_VERSION="$VERSION" RELEASE_BUILD="$BUILD_NUMBER"
  (cd "$APP_DIR/ios" && bundle exec fastlane ios release)
  # Not $BUILD_NUMBER: that is only the floor this script passed in, and
  # the lane prints the number it actually used a few lines above.
  say "done: $VERSION is on TestFlight"
}

# --------------------------------------------------------------------- main --

if [ "$DRY_RUN" -eq 1 ]; then
  if [ -n "${IOS_PROFILE:-}" ]; then profile_note="supplied"; else profile_note="fetched with -allowProvisioningUpdates"; fi
  cat <<SUMMARY
→ dry run, nothing will be built
  command       $COMMAND
  version       $VERSION ($BUILD_NUMBER)
  team          $APPLE_TEAM_ID
  api key       $ASC_KEY_ID (issuer ${ASC_ISSUER_ID:0:8}…)
  sign id       ${MACOS_SIGN_ID:-–}
  profile       $profile_note
  output        ${DIST#"$ROOT_DIR"/}
SUMMARY
  exit 0
fi

case "$COMMAND" in
  macos) build_macos ;;
  ios)   build_ios ;;
  all)   build_macos; build_ios ;;
esac
