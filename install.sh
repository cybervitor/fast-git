#!/bin/bash
set -euo pipefail

PREFIX="${PREFIX:-/usr/local}"

CHECK_DIR="$PREFIX" # Find the closest existing parent directory to check write permissions
while [[ ! -d "$CHECK_DIR" ]]; do
	CHECK_DIR="$(dirname "$CHECK_DIR")"
done

if [[ ! -w "$CHECK_DIR" ]]; then # Evaluate if the executing user has write access to that directory
	echo "Error: You do not have write permissions for '$CHECK_DIR'." >&2
	echo "Please run this script with sudo (e.g., sudo ./install.sh)" >&2
	echo "or choose a user-owned PREFIX (e.g., PREFIX=~/.local ./install.sh)." >&2
	exit 1
fi

LIB_DIR="$PREFIX/lib/git-tools"
BIN_DIR="$PREFIX/bin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing git-tools to $LIB_DIR..."
install -d "$LIB_DIR/lib" "$LIB_DIR/commands" "$BIN_DIR"
install -m644 "$SCRIPT_DIR/lib/helpers.sh" "$LIB_DIR/lib/helpers.sh"
install -m644 "$SCRIPT_DIR"/commands/*.sh "$LIB_DIR/commands/"
install -m755 "$SCRIPT_DIR/fast.sh" "$LIB_DIR/fast.sh"

# Create a symlink in the binary directory pointing to the real script
ln -sf "$LIB_DIR/fast.sh" "$BIN_DIR/fast"

echo "Installed. Run 'fast <command>' from anywhere."
echo ""
"$BIN_DIR/fast" || true