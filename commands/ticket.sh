#!/bin/bash

ticket() {    
	local title="${1:-}" desc="${2:-${1:-}}"
	
	if [[ -z "$title" ]]; then # Checks if we have enough parameters to go ahead (Just the title is enough)
		fatal_error "Missing title! Usage: fast ticket \"Issue Title\" \"[Optional Description]\""
	fi

	{ require glab && require jq; } || fatal_error "Missing dependencies (glab or jq). Check the wiki."

	is_glab_authenticated || fatal_error "glab is not authenticated. Check the wiki for instructions."

	is_gitlab_repo || fatal_error "Not inside a git***LAB*** repository." # Checks if we're inside a gitLAB repo

	local project_id # Fetch Project ID
	project_id=$(get_project_id)

	log "Asking glab to create a ticket..."
	local issue_json
	if ! issue_json=$(glab api "/projects/${project_id}/issues" -X POST \
		-F "title=${title}" \
		-F "description=${desc}" 2>&1); then
		fatal_error "Failed to create issue."
	fi

	local issue_id issue_url
	issue_id=$(jq -r '.iid // empty' <<<"$issue_json")                  # Grab the issue ID
	issue_url=$(jq -r '.web_url // .webUrl // empty' <<<"$issue_json")  # and the URL

	if [[ -z "$issue_id" ]]; then # Check if there was any problem with creating the issue
		fatal_error "Failed to parse issue ID from glab output. Raw output: $issue_json"
	fi
	log "Ticket created: #$issue_id ($issue_url)"

	local safe_title # Clean up the title string to a safe format
	safe_title=$(printf '%s' "$title" \
		| tr '[:upper:]' '[:lower:]' \
		| tr -c 'a-z0-9' '-' \
		| tr -s '-' \
		| sed -E 's/^-+|-+$//g')
	[[ -z "$safe_title" ]] && safe_title="untitled"

	local branch_name # Create the branch name to send to git
	branch_name="${issue_id}-${safe_title}"

	if git show-ref --verify --quiet "refs/heads/$branch_name"; then 
		fatal_error "$( cat <<-EOF
				Branch '$branch_name' already exists locally.
				Issue #$issue_id was created: $issue_url
				Delete or rename the existing branch, or reuse it manually.
			EOF
		)"
	fi

	log "Syncing with origin..."

	git fetch origin --quiet || fatal_error "Failed to fetch from origin."

	local default_branch # Dynamically determine if the default branch is main or master
	default_branch=$(get_default_branch)

	log "Switching to $branch_name (from origin/$default_branch)..."

	# Branch directly from the latest remote state
	if ! git checkout -b "$branch_name" "origin/$default_branch"; then
		fatal_error "$( cat <<-EOF
				Failed to create branch '$branch_name'. 
				Issue #$issue_id was created but no branch exists: $issue_url
			EOF
		)"
	fi

	log "Publishing $branch_name to GitLab..."

	local push_output # Publishing so other devs can see the branch
	if ! push_output=$(git push --set-upstream origin "$branch_name" 2>&1); then
		fatal_error "$( cat <<-EOF
				Branch '$branch_name' was created locally but FAILED TO PUSH.
				Issue #$issue_id is now orphaned — no branch is visible to the team.
				Issue: $issue_url

				Push error:
				$push_output

				To fix, run:
					git push --set-upstream origin $branch_name
			EOF
		)"
	fi

	echo "Ready to work on $branch_name. Hora do Martelanço!"
}