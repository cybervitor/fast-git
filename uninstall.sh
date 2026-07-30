#!/bin/bash
set -euo pipefail

PREFIX="${PREFIX:-/usr/local}"
LIB_DIR="$PREFIX/lib/git-tools"
BIN_WRAPPER="$PREFIX/bin/fast"
BASH_COMPLETION_FILE="$PREFIX/share/bash-completion/completions/fast"
ZSH_COMPLETION_FILE="$PREFIX/share/zsh/site-functions/_fast"

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

if [[ -f "$BASH_COMPLETION_FILE" ]]; then
	rm "$BASH_COMPLETION_FILE"
	echo "Removed $BASH_COMPLETION_FILE"
fi

if [[ -f "$ZSH_COMPLETION_FILE" ]]; then
	rm "$ZSH_COMPLETION_FILE"
	echo "Removed $ZSH_COMPLETION_FILE"
fi

echo "Uninstallation complete."