#!/bin/bash
# Copyright (C) 2023-2026 Polimex Holding Ltd. All rights reserved.
# Website: https://polimex.co
#
# PROPRIETARY AND CONFIDENTIAL
# Unauthorized copying, modification, distribution, or use is strictly prohibited.
#
# Author: Polimex Dev Team
# Description: Restore Odoo database from backup using pg_restore + filestore extraction
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/bash_odoo_utils"
parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+"${REMAINING_ARGS[@]}"}"

# Parse local arguments
no_neutralize=false
backup_file=""
dest_db=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo "Usage: $0 [--dry-run] [--yes] [--no-neutralize] <backup_file> [dest_db]"
            echo ""
            echo "Restores an Odoo database from a backup zip file using pg_restore."
            echo "Default dest_db: $DEFAULT_DB"
            echo "Backup directory: $BACKUP_DIR"
            echo ""
            echo "Options:"
            echo "  --no-neutralize  Skip database neutralization after restore"
            echo "  --dry-run        Show what would be done without making changes"
            echo "  --yes            Skip confirmation prompts"
            exit 0
            ;;
        --no-neutralize)
            no_neutralize=true
            ;;
        -*)
            print_error "Unknown option: $1"
            exit 1
            ;;
        *)
            if [[ -z "$backup_file" ]]; then
                backup_file="$1"
            elif [[ -z "$dest_db" ]]; then
                dest_db="$1"
            else
                print_error "Unexpected argument: $1"
                exit 1
            fi
            ;;
    esac
    shift
done

# Validate arguments
if [[ -z "$backup_file" ]]; then
    print_error "No backup file supplied!"
    echo "Usage: $0 <backup_file> [dest_db]"
    exit 1
fi

# If backup_file is not an absolute path, look in BACKUP_DIR
if [[ "$backup_file" != /* ]]; then
    backup_file="${BACKUP_DIR}/$backup_file"
fi

dest_db="${dest_db:-$DEFAULT_DB}"
start_time=$SECONDS

print_step "Odoo Restore (CLI)"
print_info "Backup file: $backup_file"
print_info "Target DB:   $dest_db"

# Pre-checks
require_command pg_restore || exit 1
require_command unzip || exit 1
validate_pg_connection || exit 1
validate_backup_file "$backup_file" || exit 1
check_disk_space "/opt" 500 || exit 1

if [[ "$DRY_RUN" == "true" ]]; then
    print_dry_run "Terminate connections to: $dest_db"
    print_dry_run "Drop database: $dest_db"
    print_dry_run "Create database: $dest_db"
    print_dry_run "pg_restore dump.sql into $dest_db"
    print_dry_run "Extract filestore to: ${ODOO_FILESTORE_PATH}/$dest_db"
    if [[ "$no_neutralize" == "false" ]]; then
        print_dry_run "Neutralize database: $dest_db"
    fi
    exit 0
fi

# Confirm destructive operation
if db_exists "$dest_db"; then
    confirm_action "Database '$dest_db' exists and will be DROPPED. Continue?" || exit 0
else
    confirm_action "Restore $backup_file to new database '$dest_db'?" || exit 0
fi

# Stop Odoo to prevent connections
print_step "Stopping Odoo service"
sudo systemctl stop "$ODOO_SERVICE_NAME"

# Terminate connections and drop existing DB
print_step "Preparing target: $dest_db"
terminate_db_connections "$dest_db"
sudo -u "$ODOO_USER" dropdb --if-exists "$dest_db"
sudo -u "$ODOO_USER" rm -rf "${ODOO_FILESTORE_PATH}/${dest_db}"

# Extract backup to temp directory
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

print_info "Extracting backup archive..."
unzip -q "$backup_file" -d "$tmp_dir"

# Verify dump.sql exists in archive
if [[ ! -f "${tmp_dir}/dump.sql" ]]; then
    print_error "Backup archive does not contain dump.sql — invalid format"
    sudo systemctl start "$ODOO_SERVICE_NAME"
    exit 1
fi

# Create database and restore
print_step "Restoring database: $dest_db"
sudo -u "$ODOO_USER" createdb --encoding=UTF8 --locale=en_US.UTF-8 --template=template0 "$dest_db"
sudo -u "$ODOO_USER" pg_restore --no-owner --dbname="$dest_db" "${tmp_dir}/dump.sql" 2>/dev/null || true
print_success "Database restored"

# Restore filestore
if [[ -d "${tmp_dir}/filestore" ]]; then
    print_step "Restoring filestore"
    sudo -u "$ODOO_USER" mkdir -p "${ODOO_FILESTORE_PATH}/${dest_db}"
    sudo cp -a "${tmp_dir}/filestore/." "${ODOO_FILESTORE_PATH}/${dest_db}/"
    sudo chown -R "${ODOO_USER}:${ODOO_USER}" "${ODOO_FILESTORE_PATH}/${dest_db}"
    print_success "Filestore restored"
else
    print_warning "No filestore found in backup archive"
fi

# Neutralize
if [[ "$no_neutralize" == "false" ]]; then
    neutralize_database "$dest_db"
else
    print_warning "Neutralization skipped (--no-neutralize)"
fi

# Start Odoo
print_step "Starting Odoo service"
sudo systemctl start "$ODOO_SERVICE_NAME"
check_odoo_running || print_warning "Odoo may not have started correctly"

elapsed=$(( SECONDS - start_time ))
print_success "Restore complete in $(format_duration $elapsed): $dest_db"
