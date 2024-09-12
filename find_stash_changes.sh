#!/bin/bash
# This script searches through git stashes to find changes for a specific file.

file_to_search=".\CustomUIComponents\objectListComponent.mlapp"  # Update this with the actual file path

for stash in $(git stash list | awk -F: '{print $1}'); do
    echo "Checking $stash for changes in $file_to_search:"
    git stash show -p $stash -- $file_to_search && echo "Found in $stash" || echo "Not found in $stash"
done