#!/bin/bash
set -e

echo "Downloading editorconfig-checker..."

BASE_URL="https://github.com/editorconfig-checker/editorconfig-checker/releases/latest/download"

# Detect OS and architecture
OS="$(uname -s)"
ARCH="$(uname -m)"
case "$OS" in
Darwin)
  [ "$ARCH" = "arm64" ] && ARCH="arm64" || ARCH="amd64"
  URL="$BASE_URL/ec-darwin-${ARCH}.tar.gz"
  ;;
Linux)
  [ "$ARCH" = "aarch64" ] && ARCH="arm64" || ARCH="amd64"
  URL="$BASE_URL/ec-linux-${ARCH}.tar.gz"
  ;;
*)
  echo "Unsupported OS: $OS"
  exit 1
  ;;
esac

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

curl -L "$URL" | tar -xz -C "$TMPDIR"

# Choose install directory
INSTALL_DIR="${XDG_BIN_HOME:-$HOME/bin}"
[ -d "$INSTALL_DIR" ] || INSTALL_DIR="/usr/local/bin"

echo "Installing to $INSTALL_DIR..."

mkdir -p "$INSTALL_DIR" 2>/dev/null || true

if mv "$TMPDIR/bin/ec" "$INSTALL_DIR/editorconfig-checker" 2>/dev/null; then
  echo "✓ Installed editorconfig-checker to $INSTALL_DIR"
elif sudo mv "$TMPDIR/bin/ec" "$INSTALL_DIR/editorconfig-checker" 2>/dev/null; then
  echo "✓ Installed editorconfig-checker to $INSTALL_DIR (with sudo)"
else
  echo "Could not install to $INSTALL_DIR, using local copy"
  mkdir -p bin
  mv "$TMPDIR/bin/ec" bin/editorconfig-checker
  echo "Add $(pwd)/bin to your PATH to use editorconfig-checker"
fi

echo "Installation complete!"
