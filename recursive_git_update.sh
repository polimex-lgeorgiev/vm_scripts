#!/bin/bash

# Start from the current directory
current_dir=$(pwd)

# Find all .git directories and execute git pull in their parent directories
find . -type d -name ".git" | while read git_dir; do
    repo_dir=$(dirname "$git_dir")
    echo "Pulling in $repo_dir"
    cd "$current_dir/$repo_dir" && git pull
done

# Return to the initial directory
cd "$current_dir"
