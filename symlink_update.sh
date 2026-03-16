#!/bin/bash
# Copyright (C) 2023-2026 Polimex Holding Ltd. All rights reserved.
# Website: https://polimex.co
#
# PROPRIETARY AND CONFIDENTIAL
# Unauthorized copying, modification, distribution, or use is strictly prohibited.
#
# Author: Polimex Dev Team
# Description: Create symlinks for custom Odoo modules in the addons directory
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/bash_odoo_utils"
parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+"${REMAINING_ARGS[@]}"}"

usage() {
    echo "Usage: $0 [--dry-run] [-u USER] [source_folder] [destination_folder]"
    echo ""
    echo "Options:"
    echo "  -u USER       Run as specific user (default: $ODOO_USER)"
    echo "  --dry-run     Show what would be done without making changes"
    echo "  -h, --help    Show help information"
    echo ""
    echo "Creates symlinks for all subfolders containing a __manifest__.py file."
    echo "Default source:      $ODOO_CUSTOM_ADDONS"
    echo "Default destination: $ODOO_ADDONS_DIR"
    exit 0
}

# Parse local options
user="$ODOO_USER"
while [[ $# -gt 0 ]]; do
    case "$1" in
        -u)     user="$2"; shift ;;
        -h|--help) usage ;;
        -*)     print_error "Unknown option: $1"; usage ;;
        *)      break ;;
    esac
    shift
done

src_folder="${1:-$ODOO_CUSTOM_ADDONS}"
dest_folder="${2:-$ODOO_ADDONS_DIR}"

# Validate folders
if ! sudo -u "$user" test -d "$src_folder"; then
    print_error "Source folder does not exist: $src_folder"
    exit 1
fi
if ! sudo -u "$user" test -d "$dest_folder"; then
    print_error "Destination folder does not exist: $dest_folder"
    exit 1
fi

print_step "Creating symlinks: $src_folder -> $dest_folder (as $user)"

created=0 skipped=0 failed=0

sudo -u "$user" find "$src_folder" -type f -name "__manifest__.py" -exec dirname {} \; | while read -r folder; do
    folder_name=$(basename "$folder")
    symlink_target="$dest_folder/$folder_name"

    if sudo -u "$user" [ -L "$symlink_target" ] && [ "$(sudo -u "$user" readlink -f "$symlink_target")" == "$(sudo -u "$user" readlink -f "$folder")" ]; then
        [[ "$VERBOSE" == "true" ]] && print_info "Skipped (exists): $folder_name"
        skipped=$((skipped + 1))
    elif sudo -u "$user" [ -d "$symlink_target" ]; then
        print_warning "Skipped (directory exists): $symlink_target"
        skipped=$((skipped + 1))
    else
        if [[ "$DRY_RUN" == "true" ]]; then
            print_dry_run "ln -s $folder $symlink_target"
            created=$((created + 1))
        else
            if sudo -u "$user" ln -s "$folder" "$symlink_target"; then
                print_success "Created: $folder_name -> $folder"
                created=$((created + 1))
            else
                print_error "Failed: $folder_name"
                failed=$((failed + 1))
            fi
        fi
    fi
done

print_info "Summary: created=$created, skipped=$skipped, failed=$failed"
