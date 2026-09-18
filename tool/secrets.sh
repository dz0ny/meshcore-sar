#!/usr/bin/env bash
# Publishes the signing credentials this repo needs into GitHub Actions secrets.
#
#   ./tool/secrets.sh                  # export identities, push every secret
#   ./tool/secrets.sh --dry-run        # do everything except the push
#   ./tool/secrets.sh --asc-key ~/Downloads/AuthKey_ABC123.p8 \
#                     --asc-issuer 69a6de80-… --asc-key-id ABC123
#   ./tool/secrets.sh list             # what the repo has now, and what's local
#   ./tool/secrets.sh env              # write the same values to tool/.release.env
#
# The certificates come out of the login keychain live: there is no .p12 lying
# around to lose, and no step where a private key sits in Downloads. macOS will
# ask you to allow the export once per key — that prompt is the point.
#
# What ends up in the repo (see tool/release.sh for what reads them):
#   MACOS_CERT_P12 / MACOS_CERT_PASSWORD   Developer ID Application identity
#   MACOS_SIGN_ID                          its exact codesign name
#   IOS_CERT_P12 / IOS_CERT_PASSWORD       Apple Distribution identity
#   ASC_KEY_ID / ASC_ISSUER_ID / ASC_KEY_P8   App Store Connect key, if given
#
# `env` sends that same set to tool/.release.env instead of to GitHub, which is
# how a release runs on this machine: one export, two possible sinks.
#
# The App Store Connect key is not a keychain identity, so it comes from
# --asc-key/--asc-issuer/--asc-key-id or the matching environment variables.
# Leave them out and the three secrets are skipped, the certificates still go.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR"
TEAM="${APPLE_TEAM_ID:-JND55328G8}"

say() { printf '→ %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------- arguments --

COMMAND="push"
DRY_RUN=0
REPO=""
MACOS_IDENTITY=""
IOS_IDENTITY=""
ASC_KEY_FILE="${ASC_KEY_FILE:-}"
ASC_KEY_ID="${ASC_KEY_ID:-}"
ASC_ISSUER_ID="${ASC_ISSUER_ID:-}"
ENV_FILE="$APP_DIR/tool/.release.env"

usage() {
  sed -n '2,25p' "${BASH_SOURCE[0]}" | sed 's/^#\{1\} \{0,1\}//'
  exit "${1:-0}"
}

if [ $# -gt 0 ]; then
  case "$1" in
    push|list|env) COMMAND="$1"; shift ;;
  esac
fi

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)         DRY_RUN=1; shift ;;
    --repo)            REPO="${2:-}"; shift 2 ;;
    --macos-identity)  MACOS_IDENTITY="${2:-}"; shift 2 ;;
    --ios-identity)    IOS_IDENTITY="${2:-}"; shift 2 ;;
    --asc-key)         ASC_KEY_FILE="${2:-}"; shift 2 ;;
    --asc-key-id)      ASC_KEY_ID="${2:-}"; shift 2 ;;
    --asc-issuer)      ASC_ISSUER_ID="${2:-}"; shift 2 ;;
    -h|--help)         usage ;;
    *)                 die "unknown option '$1'" ;;
  esac
done

[ "$COMMAND" = "env" ] || command -v gh >/dev/null 2>&1 || die "gh not found (brew install gh)"
command -v openssl >/dev/null 2>&1 || die "openssl not found"

if [ -z "$REPO" ]; then
  REPO="$(git -C "$ROOT_DIR" remote get-url origin 2>/dev/null \
    | sed -E 's#^git@github\.com:##; s#^https://github\.com/##; s#\.git$##')"
fi
[ -n "$REPO" ] || die "no repo: pass --repo owner/name"

WORK="$(mktemp -d -t meshcore-secrets)"
trap 'rm -rf "$WORK"' EXIT

# ---------------------------------------------------------------- identities --

# `security find-identity` prints one line per usable identity; we want the
# named kind issued to this team, and we want to fail loudly on ambiguity rather
# than sign a release with whichever one sorted first.
find_identity() {
  local kind="$1" rows hashes
  # Each row is "<sha1> <name>". Xcode installs a copy of a certificate every
  # time it fetches one, so the same identity turns up several times; that is
  # not ambiguity. Only distinct certificates are.
  rows="$(security find-identity -v -p codesigning \
    | sed -n 's/^ *[0-9]*) \([0-9A-F]*\) "\(.*\)"$/\1 \2/p' \
    | grep " $kind:" | grep "($TEAM)" || true)"
  [ -n "$rows" ] || die "no \"$kind\" identity for team $TEAM in the keychain"

  hashes="$(printf '%s\n' "$rows" | cut -d' ' -f1 | sort -u)"
  if [ "$(printf '%s\n' "$hashes" | wc -l)" -gt 1 ]; then
    printf 'error: several different "%s" certificates for team %s:\n' "$kind" "$TEAM" >&2
    printf '%s\n' "$rows" | sort -u | sed 's/^/  /' >&2
    die "pick one with --macos-identity / --ios-identity"
  fi
  printf '%s' "$(printf '%s\n' "$rows" | head -1 | cut -d' ' -f2-)"
}

[ -n "$MACOS_IDENTITY" ] || MACOS_IDENTITY="$(find_identity 'Developer ID Application')"
[ -n "$IOS_IDENTITY" ]   || IOS_IDENTITY="$(find_identity 'Apple Distribution')"

if [ "$COMMAND" = "list" ]; then
  say "repo $REPO"
  gh secret list --repo "$REPO" || true
  printf '\n'
  say "local identities (team $TEAM)"
  printf '  macOS  %s\n  iOS    %s\n' "$MACOS_IDENTITY" "$IOS_IDENTITY"
  exit 0
fi

# ------------------------------------------------------------------- export --

# `security export` has no way to name a single identity, so everything comes out
# in one bundle and openssl splits it back apart. A cert and its key share a
# localKeyID inside the bundle, which is what pairs them here.
BUNDLE="$WORK/all.p12"
BUNDLE_PW="$(uuidgen)"
BAGS="$WORK/bags.pem"

say "exporting identities from the login keychain (allow the prompt)"
security export -k "$HOME/Library/Keychains/login.keychain-db" \
  -t identities -f pkcs12 -P "$BUNDLE_PW" -o "$BUNDLE" \
  || die "export refused — the prompt needs Allow, not Deny"

openssl pkcs12 -in "$BUNDLE" -passin "pass:$BUNDLE_PW" -nodes -legacy -out "$BAGS" 2>/dev/null \
  || openssl pkcs12 -in "$BUNDLE" -passin "pass:$BUNDLE_PW" -nodes -out "$BAGS" \
  || die "openssl could not read the exported bundle"
rm -f "$BUNDLE"

# Apple's intermediates ride along in the .p12 so the runner can build a chain
# to the root without having to already trust the right CA.
CHAIN="$WORK/chain.pem"
: > "$CHAIN"
for ca in "Apple Worldwide Developer Relations" "Developer ID Certification Authority"; do
  security find-certificate -a -c "$ca" -p >> "$CHAIN" 2>/dev/null || true
done

# Pulls one identity out of the bundle: the cert bag with this friendlyName, and
# the key bag carrying the same localKeyID.
split_identity() {
  local name="$1" out_cert="$2" out_key="$3"
  BAGS="$BAGS" NAME="$name" CERT="$out_cert" KEY="$out_key" python3 - <<'PY'
import os, re, sys

bags = open(os.environ["BAGS"]).read()
blocks = re.findall(r"Bag Attributes.*?-----END [A-Z ]+-----\n", bags, re.S)

def attr(block, key):
    m = re.search(rf"^\s*{key}:\s*(.+)$", block, re.M)
    return m.group(1).strip() if m else None

want = os.environ["NAME"]
cert = next((b for b in blocks
             if "BEGIN CERTIFICATE" in b and attr(b, "friendlyName") == want), None)
if cert is None:
    sys.exit(f"no certificate named {want!r} in the exported bundle")

key_id = attr(cert, "localKeyID")
key = next((b for b in blocks
            if "PRIVATE KEY" in b and attr(b, "localKeyID") == key_id), None)
if key is None:
    sys.exit(f"{want!r} has no private key in the keychain — it cannot sign")

pem = lambda b: b[b.index("-----BEGIN"):]
open(os.environ["CERT"], "w").write(pem(cert))
open(os.environ["KEY"], "w").write(pem(key))
PY
}

# Repacks one identity into its own .p12 and prints "<base64> <password>".
pack_identity() {
  local name="$1"
  local cert="$WORK/leaf.pem" key="$WORK/leaf.key" p12="$WORK/leaf.p12"
  local pw; pw="$(uuidgen)"
  split_identity "$name" "$cert" "$key"
  # An empty -certfile is an error rather than a no-op, so only pass it when
  # the intermediates were actually found. -legacy keeps the encryption to what
  # macOS `security import` reads without argument on every runner image.
  local chain=()
  if [ -s "$CHAIN" ]; then chain=(-certfile "$CHAIN"); fi
  openssl pkcs12 -export -legacy -out "$p12" -inkey "$key" -in "$cert" \
    ${chain[@]+"${chain[@]}"} -name "$name" -passout "pass:$pw" 2>/dev/null \
    || openssl pkcs12 -export -out "$p12" -inkey "$key" -in "$cert" \
         ${chain[@]+"${chain[@]}"} -name "$name" -passout "pass:$pw"
  printf '%s %s' "$(base64 < "$p12" | tr -d '\n')" "$pw"
  rm -f "$cert" "$key" "$p12"
}

say "packing ${MACOS_IDENTITY}"
read -r MACOS_CERT_P12 MACOS_CERT_PASSWORD <<<"$(pack_identity "$MACOS_IDENTITY")"
say "packing ${IOS_IDENTITY}"
read -r IOS_CERT_P12 IOS_CERT_PASSWORD <<<"$(pack_identity "$IOS_IDENTITY")"

# ---------------------------------------------------------- app store connect --

ASC_KEY_P8=""
if [ -n "$ASC_KEY_FILE" ]; then
  [ -f "$ASC_KEY_FILE" ] || die "no such key file: $ASC_KEY_FILE"
  ASC_KEY_P8="$(base64 < "$ASC_KEY_FILE" | tr -d '\n')"
  # AuthKey_ABC123.p8 names the key it holds; take the id from the filename
  # unless one was given, because that is one fewer thing to mistype.
  if [ -z "$ASC_KEY_ID" ]; then
    base="$(basename "$ASC_KEY_FILE")"; base="${base%.p8}"
    ASC_KEY_ID="${base#AuthKey_}"
  fi
  [ -n "$ASC_ISSUER_ID" ] || die "--asc-key needs --asc-issuer too"
fi

# --------------------------------------------------------------------- push --

set_secret() {
  local name="$1" value="$2"
  [ -n "$value" ] || return 0
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '  %-20s %s bytes\n' "$name" "${#value}"
    return 0
  fi
  if [ "$COMMAND" = "env" ]; then
    # Single-quoted so base64 padding and the spaces in an identity name stay
    # literal; the only character that could break out is escaped.
    printf "%s='%s'\n" "$name" "${value//\'/\'\\\'\'}" >> "$ENV_FILE"
    printf '  %-20s written\n' "$name"
    return 0
  fi
  # Through stdin, never as an argument: arguments are readable in `ps`.
  printf '%s' "$value" | gh secret set "$name" --repo "$REPO"
  printf '  %-20s set\n' "$name"
}

if [ "$DRY_RUN" -eq 1 ]; then
  say "dry run — $REPO would receive:"
elif [ "$COMMAND" = "env" ]; then
  say "writing ${ENV_FILE#"$ROOT_DIR"/}"
  # Created empty and locked down before anything is appended: the private keys
  # must never exist in a world-readable file, not even for an instant.
  rm -f "$ENV_FILE"
  install -m 600 /dev/null "$ENV_FILE"
  printf '# Written by tool/secrets.sh — read by tool/release.sh. Not in git.\n' >> "$ENV_FILE"
else
  say "pushing to $REPO"
fi

set_secret MACOS_CERT_P12      "$MACOS_CERT_P12"
set_secret MACOS_CERT_PASSWORD "$MACOS_CERT_PASSWORD"
set_secret MACOS_SIGN_ID       "$MACOS_IDENTITY"
set_secret IOS_CERT_P12        "$IOS_CERT_P12"
set_secret IOS_CERT_PASSWORD   "$IOS_CERT_PASSWORD"
set_secret ASC_KEY_ID          "$ASC_KEY_ID"
set_secret ASC_ISSUER_ID       "$ASC_ISSUER_ID"
set_secret ASC_KEY_P8          "$ASC_KEY_P8"

if [ -z "$ASC_KEY_P8" ]; then
  printf '\nnote: no App Store Connect key given, so ASC_KEY_ID, ASC_ISSUER_ID and\n'
  printf '      ASC_KEY_P8 were left alone. Add them with:\n'
  printf '      ./tool/secrets.sh --asc-key AuthKey_XXX.p8 --asc-issuer <uuid>\n'
fi
