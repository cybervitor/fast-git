#!/bin/bash

get_project_id() {
    glab repo view --output json --jq '.id' 2>&1 || [[ -z "$project_id" ]] || fatal_error "Failed to get project ID."
}
get_open_issues() {
    local project_id="$1"
    glab api "/projects/${project_id}/issues?state=opened" 2>&1 || fatal_error "Failed to fetch issues from GitLab."
}

is_repo() {
    git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

is_glab_authenticaded() {
    glab auth status >/dev/null 2>&1
}

fatal_error() {
    local msg="$1" >&2
    exit 1
}

fatal_alert() {
    local msg="$1"
    echo ""
    echo "############################################################"
    echo "###                                                      ###"
    echo "###   !!  ACTION REQUIRED  !!                            ###"
    echo "###                                                      ###"
    echo "############################################################"
    echo ""
    echo "$msg"
    echo ""
    echo "############################################################"
    echo ""
    exit 1
}

require() {
    command -v "$1" >/dev/null || fatal_error "$1 not found, check the wiki for instructions."
}