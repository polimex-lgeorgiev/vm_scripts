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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/bash_odoo_utils"
parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+"${REMAINING_ARGS[@]}"}"

# Direct clone mode
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "Usage: $0 [--dry-run] [repository_url branch_name]"
    echo ""
    echo "Without arguments: interactive menu (default branch: $ODOO_VERSION)"
    echo "With arguments:    clone a single repository"
    echo ""
    echo "Example:"
    echo "  $0 https://github.com/OCA/hr-holidays.git 19.0"
    exit 0
elif [[ $# -eq 2 ]]; then
    if [[ "$DRY_RUN" == "true" ]]; then
        print_dry_run "git clone $1 --branch $2"
        exit 0
    fi
    git clone "$1" --depth 1 --branch "$2" --single-branch --no-tags
    exit 0
fi

# Predefined repos
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
    repo_names+=("$(basename "$url" .git)")
done

# Branch — use ODOO_VERSION as default, allow override
echo ""
echo -n "Branch [$ODOO_VERSION]: "
read -r branch_input
branch="${branch_input:-$ODOO_VERSION}"

# Repo selection
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
    print_error "No repositories selected."
    exit 1
fi

# Confirm
echo ""
print_step "Will clone ${#selected_repos[@]} repo(s) on branch $branch:"
for url in "${selected_repos[@]}"; do
    echo "  - $(basename "$url" .git)"
done
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
    for url in "${selected_repos[@]}"; do
        print_dry_run "git clone $(basename "$url" .git) --branch $branch"
    done
    exit 0
fi

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
    print_info "Cloning $name ($branch)..."
    if git clone "$repo" --depth 1 --branch "$branch" --single-branch --no-tags 2>&1; then
        print_success "$name"
        ok=$((ok + 1))
    else
        print_error "Failed: $name"
        fail=$((fail + 1))
    fi
done

echo ""
print_success "Done: $ok cloned, $fail failed."
