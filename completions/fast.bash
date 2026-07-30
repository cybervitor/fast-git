#!/bin/bash

_fast_completions() {
    # Get the current word the user is typing
    local cur="${COMP_WORDS[COMP_CWORD]}"
    
    # Define the available commands
    local commands="ticket ongoing backlog"
    
    # Generate the autocomplete matches
    COMPREPLY=( $(compgen -W "${commands}" -- "${cur}") )
}

# Bind the function to the 'fast' command
complete -F _fast_completions fast