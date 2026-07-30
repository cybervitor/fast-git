#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
LIB_DIR="$SCRIPT_DIR/lib"
COMMANDS_DIR="$SCRIPT_DIR/commands"

source "$LIB_DIR/helpers.sh"

usage() {
	echo "Usage: fast <command> [args...]"
	echo ""
	echo "Available commands:"
	for cmd_file in "$COMMANDS_DIR"/*.sh; do
		[[ -e "$cmd_file" ]] || continue
		echo "  $(basename "$cmd_file" .sh)"
	done
}

subcommand="${1:-}"

if [[ -z "$subcommand" ]]; then
	usage
	exit 1
fi
shift

command_file="$COMMANDS_DIR/$subcommand.sh"

if [[ ! -f "$command_file" ]]; then
	echo "Unknown command: '$subcommand'" >&2
	echo "" >&2
	usage >&2
	exit 1
fi

source "$command_file"

if ! declare -f "$subcommand" >/dev/null; then
	echo "Internal error: '$command_file' does not define a '$subcommand' function." >&2
	exit 1
fi

"$subcommand" "$@"