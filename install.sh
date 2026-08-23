#!/usr/bin/env bash
# Install / uninstall swarm into ~/.swarm/.
# Checkout: uses this tree. Piped curl: fetches a release tarball (not git).
set -euo pipefail

SWARM_DIST_BASE="${SWARM_DIST_BASE:-https://github.com/Eric-Boss/swarm-install/releases/latest/download}"

_install_is_checkout() {
  local src root
  src="${BASH_SOURCE[0]:-}"
  [[ -n "$src" && "$src" != "-" ]] || return 1
  [[ -f "$src" ]] || return 1
  root="$(cd "$(dirname "$src")" && pwd)" || return 1
  [[ -f "$root/bin/swarm-install.inc" ]]
}

_install_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$@"
  else
    shasum -a 256 "$@"
  fi
}

_install_fetch_dist() {
  # Must run in this shell (not $()) so the unpack dir survives.
  local tarpath got expect
  _SWARM_FETCH_TMP="$(mktemp -d "${TMPDIR:-/tmp}/swarm-dist.XXXXXX")"
  # shellcheck disable=SC2064
  trap "rm -rf '$_SWARM_FETCH_TMP'" EXIT

  if [[ -n "${SWARM_DIST_TARBALL:-}" ]]; then
    [[ -f "$SWARM_DIST_TARBALL" ]] || {
      echo "swarm install: SWARM_DIST_TARBALL not a file: $SWARM_DIST_TARBALL" >&2
      exit 1
    }
    tarpath="$SWARM_DIST_TARBALL"
  else
    echo "swarm install: fetching $SWARM_DIST_BASE/swarm.tar.gz" >&2
    curl -fsSL "$SWARM_DIST_BASE/swarm.tar.gz" -o "$_SWARM_FETCH_TMP/swarm.tar.gz" || {
      echo "swarm install: download failed from $SWARM_DIST_BASE/swarm.tar.gz" >&2
      exit 1
    }
    tarpath="$_SWARM_FETCH_TMP/swarm.tar.gz"
    if curl -fsSL "$SWARM_DIST_BASE/SHA256SUMS" -o "$_SWARM_FETCH_TMP/SHA256SUMS"; then
      got="$(_install_sha256 "$tarpath" | awk '{print $1}')"
      expect="$(awk '/[ *]swarm\.tar\.gz$/ {print $1; exit}' "$_SWARM_FETCH_TMP/SHA256SUMS")"
      [[ -n "$expect" ]] || {
        echo "swarm install: SHA256SUMS has no swarm.tar.gz line" >&2
        exit 1
      }
      [[ "$got" == "$expect" ]] || {
        echo "swarm install: checksum mismatch (got $got want $expect)" >&2
        exit 1
      }
    else
      echo "swarm install: SHA256SUMS missing at $SWARM_DIST_BASE — refuse unsigned dist" >&2
      exit 1
    fi
  fi

  mkdir -p "$_SWARM_FETCH_TMP/unpack"
  tar -xzf "$tarpath" -C "$_SWARM_FETCH_TMP/unpack"
  if [[ -f "$_SWARM_FETCH_TMP/unpack/bin/swarm-install.inc" ]]; then
    _ROOT="$_SWARM_FETCH_TMP/unpack"
  elif [[ -f "$_SWARM_FETCH_TMP/unpack/swarm/bin/swarm-install.inc" ]]; then
    _ROOT="$_SWARM_FETCH_TMP/unpack/swarm"
  else
    echo "swarm install: tarball missing bin/swarm-install.inc" >&2
    exit 1
  fi
}

if _install_is_checkout; then
  _ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  # Piped one-liner has no local tree. Fetch the toolkit tarball.
  if [[ -z "${SWARM_DIST_TARBALL:-}" ]] && ! command -v curl >/dev/null 2>&1; then
    echo "swarm install: curl required for remote install" >&2
    exit 1
  fi
  _install_fetch_dist
  # Piped stdin is the script, not a tty. Wire PATH unless caller said no.
  if [[ "${SWARM_YES:-}" != "0" ]] && [[ " $* " != *" --uninstall "* ]]; then
    export SWARM_YES="${SWARM_YES:-1}"
  fi
fi
export SWARM_HOME="${SWARM_HOME:-$_ROOT}"
# shellcheck source=bin/swarm-install.inc
source "$_ROOT/bin/swarm-install.inc"

YES="${SWARM_YES:-0}"
UNINSTALL=0
ARGS=()
for arg in "$@"; do
  case "$arg" in
    --yes|-y) YES=1 ;;
    --uninstall) UNINSTALL=1 ;;
    -h|--help)
      cat <<'EOF'
install.sh — install swarm to ~/.swarm/

  curl -fsSL https://raw.githubusercontent.com/Eric-Boss/swarm-install/main/install.sh | bash
  ./install.sh              install (upgrade in place on re-run)
  ./install.sh --yes        allow rc edits when stdin is not a tty
  ./install.sh --uninstall  remove ~/.swarm + PATH lines from shell rc
  ./install.sh --version    print version

Env: SWARM_YES=1  SWARM_INSTALL_DIR=  SWARM_INTERACTIVE=0
     SWARM_DIST_BASE=  SWARM_DIST_TARBALL=
EOF
      exit 0
      ;;
    --version|-V) cmd_swarm_version; exit 0 ;;
    *) ARGS+=("$arg") ;;
  esac
done
[[ ${#ARGS[@]} -gt 0 ]] && echo "install.sh: ignoring extra args: ${ARGS[*]}" >&2
export SWARM_YES="$YES"

if [[ "$UNINSTALL" -eq 1 ]]; then
  cmd_uninstall
else
  cmd_install
fi
