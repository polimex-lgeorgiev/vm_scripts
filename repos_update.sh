#!/bin/bash
# Copyright (C) 2023-2026 Polimex Holding Ltd. All rights reserved.
# Website: https://polimex.co
#
# PROPRIETARY AND CONFIDENTIAL
# Unauthorized copying, modification, distribution, or use is strictly prohibited.
#
# Author: Polimex Dev Team
# Description: Update all Git repositories in custom-addons directory
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/bash_odoo_utils"
parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+"${REMAINING_ARGS[@]}"}"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "Usage: $0 [--dry-run] [--verbose] [root_dir]"
    echo ""
    echo "Searches for Git repositories and updates them with 'git pull'."
    echo "Excludes: odoo/, polimex-rfid/, *venv*"
    echo "Default root_dir: $ODOO_CUSTOM_ADDONS"
    exit 0
fi

root_dir="${1:-$ODOO_CUSTOM_ADDONS}"

# Auto-detect root_dir if default doesn't exist
if [[ ! -d "$root_dir" ]]; then
    opt_dirs=(/opt/*/)
    if [[ ${#opt_dirs[@]} -eq 1 ]]; then
        root_dir="${opt_dirs[0]}custom-addons"
    else
        echo "Please choose a directory from the list below:"
        select choice in /opt/*/; do
            if [[ -n "$choice" ]]; then
                root_dir="${choice}custom-addons"
                break
            else
                echo "Invalid selection. Please choose a valid directory."
            fi
        done
    fi
fi

if [[ ! -d "$root_dir" ]]; then
    print_error "Directory does not exist: $root_dir"
    exit 1
fi

# Extract user name from path (e.g., /opt/odoo19/custom-addons -> odoo19)
user_name=$(echo "$root_dir" | sed 's:.*/\([^/]*\)/.*:\1:')

print_step "Updating repos in: $root_dir (as $user_name)"
local_start=$SECONDS
repo_count=0

sudo -u "$user_name" bash -c "find \"$root_dir\" -type d -name \".git\" \
  -not -path \"*/odoo/*\" \
  -not -path \"*/polimex-rfid/*\" \
  -not -path \"*/venv/*\"" | while read -r dir; do
    repo_dir=$(dirname "$dir")
    repo_name=$(basename "$repo_dir")
    repo_count=$((repo_count + 1))

    if [[ "$DRY_RUN" == "true" ]]; then
        print_dry_run "git pull in $repo_dir"
    else
        print_info "Updating: $repo_name"
        if sudo -u "$user_name" bash -c "cd '$repo_dir' && git pull" 2>&1; then
            print_success "$repo_name updated"
        else
            print_error "Failed to update: $repo_name"
        fi
    fi
done

local_elapsed=$(( SECONDS - local_start ))
print_success "Repos update finished in $(format_duration $local_elapsed)"
