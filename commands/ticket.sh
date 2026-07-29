ticket() {    
    local title="${1:-}" desc="${2:-${1:-}}"
    if [[ -z "$title" ]]; then # Checks if we have enough parameters to go ahead (Just the title is enough)
        echo "Missing title!"
        fatal_error "Usage: git-ticket \"Issue Title\" \"[Optional Description]\""
    fi

    is_repo || fatal_error "Not inside a git repository." # Checks if we're inside a git repo

    require glab && require git-town && require jq || return 1 # Checks for dependencies

    # Checks for glab authentication
    is_glab_authenticaded || fatal_error "glab is not authenticated. Check the wiki for instructions."
    
    local project_id # Fetch Project ID
    project_id=$(get_project_id)

    echo "Asking glab to create a ticket..."
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
        echo "Failed to parse issue ID from glab output." >&2
        fatal_error "Raw output: $issue_json"
    fi
    echo "Ticket created: #$issue_id ($issue_url)"

    local safe_title # Clean up the title string to a safe format
    safe_title=$(printf '%s' "$title" \
        | tr '[:upper:]' '[:lower:]' \
        | tr -c 'a-z0-9' '-' \
        | tr -s '-' \
        | sed -E 's/^-+|-+$//g')
    [[ -z "$safe_title" ]] && safe_title="untitled"

    local branch_name # Create the branch name to send to git
    branch_name="${issue_id}-${safe_title}"

    if git show-ref --verify --quiet "refs/heads/$branch_name"; then # Check if the branch already exists
        echo "Branch '$branch_name' already exists locally. Aborting to avoid conflicting with git hack." >&2
        echo "Issue #$issue_id was created: $issue_url" >&2
        echo "Delete or rename the existing branch, or reuse it manually." >&2
        return 1
    fi

    echo "Switching to $branch_name..."

    # Git Town's git hack does the work better than git checkout: it syncs master, cuts the branch, and checks it out
    if ! git-town hack "$branch_name"; then
        alert "git hack failed for branch '$branch_name'.
Issue #$issue_id was created but no branch exists: $issue_url"
        return 1
    fi

    echo "Publishing $branch_name to GitLab..."
    local push_output # Publishing so other devs can see the branch
    if ! push_output=$(git push --set-upstream origin "$branch_name" 2>&1); then
        alert "Branch '$branch_name' was created locally but FAILED TO PUSH.
Issue #$issue_id is now orphaned — no branch is visible to the team.
Issue: $issue_url

Push error:
$push_output

To fix, run:
  git push --set-upstream origin $branch_name"
        return 1
    fi

    echo "Ready to work on $branch_name. Hora do Martelanço!"
}