#!/bin/bash

_fast_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    
    local options="-v --verbose -h --help"
    local commands="ticket ongoing backlog"
    
    # Check if a subcommand has already been specified
    local has_subcommand=false
    local word
    for word in "${COMP_WORDS[@]:1:$COMP_CWORD-1}"; do
        case "$word" in
            ticket|ongoing|backlog)
                has_subcommand=true
                break
                ;;
        esac
    done
    
    # If no subcommand has been chosen yet, complete options or subcommands
    if [[ "$has_subcommand" == "false" ]]; then
        if [[ "$cur" == -* ]]; then
            COMPREPLY=( $(compgen -W "${options}" -- "${cur}") )
        else
            COMPREPLY=( $(compgen -W "${options} ${commands}" -- "${cur}") )
        fi
    fi
}

complete -F _fast_completions fast