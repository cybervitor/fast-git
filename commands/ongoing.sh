#!/bin/bash

ongoing() {
	is_repo || fatal_error "Not inside a git repository." # Checks if we're inside a git repo
	
	{ require glab && require jq; } || return 1 # Checks for dependencies

	# Checks for glab authentication
	is_glab_authenticated || fatal_error "glab is not authenticated. Check the wiki for instructions."

	local project_id # Fetch Project ID
	project_id=$(get_project_id)

	echo "Scanning remote branches for active tickets..."
	
	# Extract active Issue IDs from remote branches
	# - Gets all remote branches
	# - Strips "refs/heads/"
	# - Grabs only the numeric prefix matching the issue ID (e.g., "42" from "42-feature")
	# - Converts to a unique JSON array to feed directly into jq
	local active_ids_json
	active_ids_json=$(git ls-remote --heads origin | sed -nE 's|.*refs/heads/([0-9]+).*|\1|p' | jq -Rn '[inputs] | unique')    
	if [[ "$active_ids_json" == "[]" || -z "$active_ids_json" ]]; then
		fatal_error "No active issue branches found on the remote."
	fi

	echo "Cross-referencing with GitLab open issues..."
	
	local issues_json # Fetch open issues using the GitLab API
	issues_json=$(get_open_issues "$project_id")
	
	cat <<-EOF

		############################################################
		###                  ACTIVE ONGOING TICKETS              ###
		############################################################

	EOF

	# Use jq strictly to extract flat, Tab-Separated Values (TSV)
	# Format: Assignee <tab> IID <tab> Title
	# If there are multiple assignees, we unrolls them into multiple rows
	local parsed_issues
	parsed_issues=$(jq -r --argjson active "$active_ids_json" '
		($active | map({key: ., value: true}) | from_entries) as $active_map
		| map(select(.iid | tostring as $id | $active_map | has($id)))
		| .[]?
		| .iid as $iid
		| .title as $title
		| (if (.assignees | length) > 0 then .assignees[].username else "Unassigned" end) as $assignee
		| "\($assignee)\t\($iid)\t\($title)"
	' <<< "$issues_json")

	# Handle the empty state
	if [[ -z "$parsed_issues" ]]; then
		echo "No open tickets have active remote branches."
	else
		local sorted_issues # Sort alphabetically by Assignee so they group together naturally
		sorted_issues=$(echo "$parsed_issues" | sort)
		local current_assignee=""
		
		# Loop through the TSV data
		while IFS=$'\t' read -r assignee iid title; do          # IFS=$'\t' ensures that spaces inside ticket titles don't break our variables
			if [[ "$assignee" != "$current_assignee" ]]; then   # When the assignee changes, print the header
				[[ -n "$current_assignee" ]] && echo ""         # Print a blank line between users (if it is not the very first one)
				echo "👤 $assignee:"
				current_assignee="$assignee"
			fi
			echo "  ▶ #$iid - $title"
		done <<< "$sorted_issues"
	fi

	echo ""
	echo "############################################################"
}