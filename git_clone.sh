#!/bin/bash
# Copyright (C) 2023-2026 Polimex Holding Ltd. All rights reserved.
# Website: https://polimex.co
#
# PROPRIETARY AND CONFIDENTIAL
# Unauthorized copying, modification, distribution, or use is strictly prohibited.
#
# Author: Polimex Dev Team
# Description: Clone Git repositories with branch selection (interactive or direct)
set -euo pipefail

# Function to display help
display_help() {
    echo "Usage: $0 [repository_url] [branch_name]"
    echo ""
    echo "Without arguments: interactive menu for branch and repo selection."
    echo "With arguments:    clone a single repository."
    echo ""
    echo "Example:"
    echo "  $0 https://github.com/OCA/hr-holidays.git 19.0"
}

# Direct clone mode
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    display_help
    exit 0
elif [[ $# -eq 2 ]]; then
    git clone "$1" --depth 1 --branch "$2" --single-branch --no-tags
    exit 0
fi

# Predefined arrays
declare -a branches=("14.0" "15.0" "16.0" "17.0" "18.0" "19.0")
declare -a repos=(
    "https://github.com/polimex/polimex-rfid.git"
    "https://github.com/OCA/OCB.git"
    "https://github.com/OCA/web.git"
    "https://github.com/OCA/hr.git"
    "https://github.com/OCA/hr-attendance.git"
    "https://github.com/OCA/hr-holidays.git"
    "https://github.com/OCA/server-brand.git"
    "https://github.com/OCA/server-tools.git"
    "https://github.com/OCA/server-ux.git"
    "https://github.com/OCA/social.git"
    "https://github.com/OCA/data-protection.git"
    "https://github.com/OCA/multi-company.git"
    "https://github.com/OCA/calendar.git"
)

# Extract short names for display
repo_names=()
for url in "${repos[@]}"; do
    name=$(basename "$url" .git)
    repo_names+=("$name")
done

# Branch selection
echo ""
echo "Select a branch:"
select branch in "${branches[@]}"; do
    if [[ -n "$branch" ]]; then
        echo ""
        echo "Branch: $branch"
        break
    fi
    echo "Invalid selection."
done

# Repo selection — show numbered list, accept space-separated numbers or 'a' for all
echo ""
echo "Available repositories:"
for i in "${!repo_names[@]}"; do
    printf "  %2d) %s\n" $((i + 1)) "${repo_names[$i]}"
done
echo ""
echo "Enter numbers separated by spaces, or 'a' for all:"
echo -n "#? "
read -r selection

selected_repos=()
if [[ "$selection" == "a" || "$selection" == "A" ]]; then
    selected_repos=("${repos[@]}")
else
    for num in $selection; do
        if [[ "$num" =~ ^[0-9]+$ ]] && (( num >= 1 && num <= ${#repos[@]} )); then
            selected_repos+=("${repos[$((num - 1))]}")
        else
            echo "Skipping invalid number: $num"
        fi
    done
fi

if [[ ${#selected_repos[@]} -eq 0 ]]; then
    echo "No repositories selected."
    exit 1
fi

# Confirm
echo ""
echo "Will clone ${#selected_repos[@]} repo(s) on branch $branch:"
for url in "${selected_repos[@]}"; do
    echo "  - $(basename "$url" .git)"
done
echo ""
echo -n "Continue? [Y/n] "
read -r confirm
if [[ "$confirm" =~ ^[Nn]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Clone
echo ""
ok=0 fail=0
for repo in "${selected_repos[@]}"; do
    name=$(basename "$repo" .git)
    echo "Cloning $name ($branch)..."
    if git clone "$repo" --depth 1 --branch "$branch" --single-branch --no-tags 2>&1; then
        ok=$((ok + 1))
    else
        echo "FAILED: $name"
        fail=$((fail + 1))
    fi
    echo ""
done

echo "Done: $ok cloned, $fail failed."
