#!/bin/bash

# Start from the current directory
current_dir=$(pwd)

# Find all .git directories and execute git pull in their parent directories
find . -type d -name ".git" | while read git_dir; do
    repo_dir=$(dirname "$git_dir")
    echo "Pulling in $repo_dir"
    cd "$current_dir/$repo_dir" && git fetch --depth=1 && git pull && git clean -fdx && git fetch --depth=1 && git gc --prune=now --aggressive
done

# Return to the initial directory
cd "$current_dir"
