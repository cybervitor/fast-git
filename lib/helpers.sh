#!/bin/bash

# Fetches the current GitLab project ID using the glab CLI.
# Outputs:
#   The numerical project ID.
# Returns:
#   0 on success, exits 1 on failure.
get_project_id() {
	glab repo view --output json --jq '.id' 2>&1 || [[ -z "$project_id" ]] || fatal_error "Failed to get project ID."
}

# Fetches all currently open issues for a specific GitLab project.
# Arguments:
#   $1 - The project ID.
# Outputs:
#   JSON string containing the open issues.
# Returns:
#   0 on success, exits 1 on failure.
get_open_issues() {
	local project_id="$1"
	glab api "/projects/${project_id}/issues?state=opened" 2>&1 || fatal_error "Failed to fetch issues from GitLab."
}

# Fetches the default branch from origin (usually main or master).
# Outputs:
#   The name of the default branch as a string.
# Returns:
#   0 upon successfully finding the branch.
get_default_branch() {
    local ref # Try to read the remote HEAD pointer directly
    if ref=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null); then
        echo "${ref#refs/remotes/origin/}" # Use native bash parameter expansion to strip the prefix
        return 0
    fi

    # Fallback: check if 'main' exists, otherwise assume 'master'
    if git show-ref --verify --quiet refs/remotes/origin/main; then
        echo "main"
    else
        echo "master"
    fi
}

# Checks if the current working directory is inside a Git repository.
# Returns:
#   0 if inside a git repo, 1 otherwise.
is_repo() {
	git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

# Checks if the user is currently authenticated with the glab CLI.
# Returns:
#   0 if authenticated, 1 otherwise.
is_glab_authenticated() {
	glab auth status >/dev/null 2>&1
}

# Prints a standard error message to standard error (STDERR) and exits.
# Arguments:
#   $1 - The error message to display.
# Returns:
#   Exits the script with status code 1.
fatal_error() {
	local msg="$1"
    echo "$msg" >&2
    exit 1
}

# Prints a highly visible, boxed error alert to STDERR and exits.
# Arguments:
#   $1 - The alert message to display inside the box.
# Returns:
#   Exits the script with status code 1.
fatal_alert() {
	local msg="$1"
	cat <<-EOF >&2
		############################################################
		###                                                      ###
		###            !!  ACTION REQUIRED  !!                   ###
		###                                                      ###
		############################################################

		$msg

		############################################################
	EOF
    exit 1
}

# Verifies that a required dependency is installed on the system.
# Arguments:
#   $1 - The name of the command to check (e.g., jq, glab).
# Returns:
#   0 if installed, exits 1 if missing.
require() {
	command -v "$1" >/dev/null || fatal_error "$1 not found, check the wiki for instructions."
}