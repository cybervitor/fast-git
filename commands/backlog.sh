#!/bin/bash
# Private helper to filter and print issue groups 
# Expects $parsed_issues to be available in the current scope
_print_issue_group() { 
	local assignee="$1"
	local issues
	
	if [[ "$assignee" == "Unassigned" ]]; then	# The unassigned block uses different indentation and ignores the $2 column
		echo "🔨 $1"
		issues=$(awk -F'\t' '$1 == "Unassigned" {print "            ▶ #" $3 " - " $4}' <<< "$parsed_issues")
	else
		echo "Team Backlog (Unassigned):"
		issues=$(awk -F'\t' -v u="$assignee" '$1 == u {print "  " $2 " ▶ #" $3 " - " $4}' <<< "$parsed_issues")
	fi

	if [[ -n "$issues" ]]; then
		echo "$issues"
	else
		echo "            ▶ Backlog is empty"
	fi
}

backlog() {
	{ require glab && require jq; } || return 1 # Checks for dependencies

	# Checks for glab authentication
	is_glab_authenticated || fatal_error "glab is not authenticated. Check the wiki for instructions."

	is_gitlab_repo || fatal_error "Not inside a git***LAB*** repository." # Checks if we're inside a gitLAB repo

	local project_id #Obtains the project ID
	project_id=$(get_project_id)
	
	log "Fetching team status (Issues and branches)..."
	
	local issues_json # Fetch open issues (Full Backlog)
	issues_json=$(get_open_issues "$project_id")
	
	local active_ids_json # Fetch active remote branches (Mark Ongoing state)
	active_ids_json=$(git ls-remote --heads origin | sed -nE 's|.*refs/heads/([0-9]+).*|\1|p' | jq -Rn '[inputs] | unique')
	[[ -z "$active_ids_json" || "$active_ids_json" == "[]" ]] && active_ids_json="[]" # empty array if no remote branches exist

	cat <<-EOF

		############################################################
		###                  TEAM BACKLOG STATUS                 ###
		############################################################

	EOF

	local members # Extract the sorted list of project members
	members=$(jq -r '.[] | .assignees[].username' <<< "$issues_json" | sort -u)

	local parsed_issues # Extract all issues into a flat TSV format: Assignee <tab> Status <tab> IID <tab> Title
	# Make sure to check if the IID exists in the active branches map and format the tag
	# Unroll assignees (so shared tickets create multiple rows) or mark as Unassigned
	parsed_issues=$(jq -r --argjson active "$active_ids_json" '
		($active | map({key: ., value: true}) | from_entries) as $active_map
		| .[]?
		| .iid as $iid
		| .title as $title
		| (if ($active_map[.iid | tostring] // false) then "♨️" else "         " end) as $status
		| (if (.assignees | length) > 0 then .assignees[].username else "Unassigned" end) as $assignee
		| "\($assignee)\t\($status)\t\($iid)\t\($title)"
	' <<< "$issues_json" | sort -t$'\t' -k1,1 -k2,2r -k3,3n)

	for user in $members; do # Iterate through every member in the project
		_print_issue_group "$user"
		echo "" # Empty line between repository members
	done
	_print_issue_group "Unassigned"

	cat <<-EOF

		############################################################
	EOF
}