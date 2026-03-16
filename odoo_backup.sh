#!/bin/bash
# Copyright (C) 2023-2026 Polimex Holding Ltd. All rights reserved.
# Website: https://polimex.co
#
# PROPRIETARY AND CONFIDENTIAL
# Unauthorized copying, modification, distribution, or use is strictly prohibited.
#
# Author: Polimex Dev Team
# Description: Create Odoo database backup via pg_dump + filestore archive
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/bash_odoo_utils"
parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+"${REMAINING_ARGS[@]}"}"

# Parse local arguments
retention_days="$BACKUP_RETENTION_DAYS"
database=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo "Usage: $0 [--dry-run] [--verbose] [--retention DAYS] [database]"
            echo ""
            echo "Creates a backup using pg_dump + filestore archive (zip)."
            echo "Default database: $DEFAULT_DB"
            echo "Default retention: $BACKUP_RETENTION_DAYS days"
            echo "Backup directory:  $BACKUP_DIR"
            exit 0
            ;;
        --retention)
            retention_days="$2"
            shift
            ;;
        -*)
            print_error "Unknown option: $1"
            exit 1
            ;;
        *)
            database="$1"
            ;;
    esac
    shift
done

database="${database:-$DEFAULT_DB}"
timestamp=$(date +'%Y%m%d_%H%M%S')
backup_file="${BACKUP_DIR}/backup_${database}_${timestamp}.zip"
start_time=$SECONDS

print_step "Odoo Backup (CLI): $database"
print_info "Target: $backup_file"

# Pre-checks
require_command pg_dump || exit 1
require_command zip || exit 1
validate_pg_connection || exit 1
check_disk_space "$BACKUP_DIR" 500 || exit 1

if ! db_exists "$database"; then
    print_error "Database does not exist: $database"
    exit 1
fi

if [[ "$DRY_RUN" == "true" ]]; then
    print_dry_run "pg_dump $database -> SQL dump"
    print_dry_run "Archive filestore: ${ODOO_FILESTORE_PATH}/$database"
    print_dry_run "Create zip: $backup_file"
    print_dry_run "Cleanup backups older than $retention_days days"
    exit 0
fi

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Create temp directory for backup assembly
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

# pg_dump (custom format for efficient restore)
print_info "Dumping database: $database"
sudo -u "$ODOO_USER" pg_dump --no-owner --format=c "$database" > "${tmp_dir}/dump.sql"
dump_size=$(stat -c%s "${tmp_dir}/dump.sql" 2>/dev/null || echo 0)
print_info "Database dump: $(format_size "$dump_size")"

# Filestore
filestore_path="${ODOO_FILESTORE_PATH}/${database}"
if [[ -d "$filestore_path" ]]; then
    print_info "Copying filestore..."
    sudo -u "$ODOO_USER" cp -a "$filestore_path" "${tmp_dir}/filestore"
    # Fix permissions so we can zip
    sudo chown -R "$USER:$USER" "${tmp_dir}/filestore"
else
    print_warning "No filestore found at $filestore_path"
    mkdir -p "${tmp_dir}/filestore"
fi

# Create zip
print_info "Creating archive..."
(cd "$tmp_dir" && zip -qr "$backup_file" dump.sql filestore/)

# Validate
if validate_backup_file "$backup_file"; then
    backup_size=$(stat -c%s "$backup_file" 2>/dev/null || echo 0)
    elapsed=$(( SECONDS - start_time ))
    print_success "Backup completed in $(format_duration $elapsed): $(format_size "$backup_size")"
else
    print_error "Backup validation failed!"
    exit 1
fi

# Cleanup old backups
old_count=$(find "$BACKUP_DIR" -type f -mtime +"$retention_days" -name "backup_${database}_*.zip" 2>/dev/null | wc -l)
if [[ "$old_count" -gt 0 ]]; then
    print_info "Removing $old_count backup(s) older than $retention_days days"
    find "$BACKUP_DIR" -type f -mtime +"$retention_days" -name "backup_${database}_*.zip" -delete
    print_success "Cleanup done"
else
    print_info "No old backups to clean up"
fi
