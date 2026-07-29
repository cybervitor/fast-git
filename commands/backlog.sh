backlog() {
    is_repo || fatal_error "Not inside a git repository." # Checks if we're inside a git repo
    
    require glab && require jq || return 1 # Checks for dependencies

    # Checks for glab authentication
    is_glab_authenticaded || fatal_error "glab is not authenticated. Check the wiki for instructions."

    local project_id #Obtains the project ID
    project_id=$(get_project_id)
    
    echo "Fetching team status (Issues and branches)..."
    
    local issues_json # Fetch open issues (Full Backlog)
    issues_json=$(get_open_issues "$project_id")
    
    local active_ids_json # Fetch active remote branches (Mark Ongoing state)
    active_ids_json=$(git ls-remote --heads origin | sed -nE 's|.*refs/heads/([0-9]+).*|\1|p' | jq -Rn '[inputs] | unique')
    # Default to an empty JSON array if no remote branches exist to prevent jq errors
    [[ -z "$active_ids_json" || "$active_ids_json" == "[]" ]] && active_ids_json="[]"

    echo ""
    echo "############################################################"
    echo "###                  TEAM BACKLOG STATUS                 ###"
    echo "############################################################"
    echo ""

    local members # Extract the sorted list of project members
    members=$(jq -r '.[] | .assignees[].username' <<< "$issues_json" | sort -u)

    local parsed_issues 
    # Extract all issues into a flat TSV format: Assignee <tab> Status <tab> IID <tab> Title
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

    # Iterate through every member in the project
    local user_issues
    for user in $members; do
        echo "🔨 $user:"
        
        # awk to exact-match the Assignee column and format output
        user_issues=$(awk -F'\t' -v u="$user" '$1 == u {print "  " $2 " ▶ #" $3 " - " $4}' <<< "$parsed_issues")
        
        if [[ -n "$user_issues" ]]; then
            echo "$user_issues"
        else
            echo "            ▶ Clear backlog!"
        fi
        echo "" # Print a blank between users
    done

    echo "️Team Backlog (Unassigned):" # Append Backlog (Unassigned tickets)

    # awk to extract rows wher Assignee column is "Unassigned"
    local unassigned_issues
    unassigned_issues=$(awk -F'\t' '$1 == "Unassigned" {print "            ▶ #" $3 " - " $4}' <<< "$parsed_issues")
    
    if [[ -n "$unassigned_issues" ]]; then
        echo "$unassigned_issues"
    else
        echo "            ▶ Backlog is empty!"
    fi

    echo ""
    echo "############################################################"
}