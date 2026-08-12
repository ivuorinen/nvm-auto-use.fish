#!/bin/bash
set -euo pipefail

# EDITORCONFIG_CHECKER_VERSION must be a pinned GitHub release tag (e.g. v3.6.1).
# The Makefile passes the Renovate-pinned tag; manual invocations must set it.
EDITORCONFIG_CHECKER_VERSION="${EDITORCONFIG_CHECKER_VERSION:?Set EDITORCONFIG_CHECKER_VERSION to a pinned release tag}"

echo "Downloading editorconfig-checker (${EDITORCONFIG_CHECKER_VERSION})..."

_EC_BASE="https://github.com/editorconfig-checker/editorconfig-checker/releases/download"
BASE_URL="${_EC_BASE}/${EDITORCONFIG_CHECKER_VERSION}"

# Detect OS and architecture
OS="$(uname -s)"
ARCH="$(uname -m)"
case "$OS" in
Darwin)
  case "$ARCH" in
    arm64) ARCH="arm64" ;;
    x86_64) ARCH="amd64" ;;
    *) echo "Unsupported architecture on Darwin: $ARCH"; exit 1 ;;
  esac
  URL="$BASE_URL/ec-darwin-${ARCH}.tar.gz"
  ;;
Linux)
  case "$ARCH" in
    aarch64) ARCH="arm64" ;;
    x86_64) ARCH="amd64" ;;
    *) echo "Unsupported architecture on Linux: $ARCH"; exit 1 ;;
  esac
  URL="$BASE_URL/ec-linux-${ARCH}.tar.gz"
  ;;
*)
  echo "Unsupported OS: $OS"
  exit 1
  ;;
esac

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

curl -fsSL "$URL" | tar -xz -C "$TMPDIR"

# The release archive ships the binary arch-suffixed as bin/ec-<os>-<arch>
# (e.g. bin/ec-linux-amd64), never a plain bin/ec — verified against v3.8.0
# and v3.10.0. Locate it rather than hardcoding a name, and fail loudly if the
# layout changes again instead of letting `mv` fail into a confusing
# "command not found" later.
EC_BINARY="$(find "$TMPDIR/bin" -maxdepth 1 -type f -name 'ec*' | head -n 1)"
if [ -z "$EC_BINARY" ]; then
  echo "Could not find editorconfig-checker binary in archive"
  exit 1
fi

# Choose install directory — attempt to create the XDG/home dir first so a
# fresh environment doesn't fall back to /usr/local/bin unnecessarily.
INSTALL_DIR="${XDG_BIN_HOME:-$HOME/bin}"
mkdir -p "$INSTALL_DIR" 2>/dev/null || true
if [ ! -w "$INSTALL_DIR" ]; then
  INSTALL_DIR="/usr/local/bin"
  mkdir -p "$INSTALL_DIR" 2>/dev/null || true
fi

echo "Installing to $INSTALL_DIR..."

if mv "$EC_BINARY" "$INSTALL_DIR/editorconfig-checker" 2>/dev/null; then
  echo "✓ Installed editorconfig-checker to $INSTALL_DIR"
elif sudo mv "$EC_BINARY" "$INSTALL_DIR/editorconfig-checker" 2>/dev/null; then
  echo "✓ Installed editorconfig-checker to $INSTALL_DIR (with sudo)"
else
  echo "Could not install to $INSTALL_DIR, using local copy"
  mkdir -p bin
  mv "$EC_BINARY" bin/editorconfig-checker
  echo "Add $(pwd)/bin to your PATH to use editorconfig-checker"
fi

echo "Installation complete!"
