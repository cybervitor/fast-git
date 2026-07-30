#!/bin/bash
set -euo pipefail

PREFIX="${PREFIX:-/usr/local}"
LIB_DIR="$PREFIX/lib/git-tools"
BIN_WRAPPER="$PREFIX/bin/fast"

# Find the closest existing parent directory to check write permissions
CHECK_DIR="$PREFIX"
while [[ ! -d "$CHECK_DIR" ]]; do
	CHECK_DIR="$(dirname "$CHECK_DIR")"
done

# Evaluate if the executing user has write access to that directory
if [[ ! -w "$CHECK_DIR" ]]; then
	echo "Error: You do not have write permissions for '$CHECK_DIR'." >&2
	echo "Please run this script with sudo (e.g., sudo ./uninstall.sh)" >&2
	echo "or specify your user-owned PREFIX (e.g., PREFIX=~/.local ./uninstall.sh)." >&2
	exit 1
fi

echo "Uninstalling git-tools from $PREFIX..."

if [[ -L "$BIN_WRAPPER" ]] || [[ -f "$BIN_WRAPPER" ]]; then
	rm "$BIN_WRAPPER"
	echo "Removed $BIN_WRAPPER"
else
	echo "Executable not found: $BIN_WRAPPER"
fi

if [[ -d "$LIB_DIR" ]]; then
	rm -rf "$LIB_DIR"
	echo "Removed $LIB_DIR"
else
	echo "Library directory not found: $LIB_DIR"
fi

echo "Uninstallation complete."