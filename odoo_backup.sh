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
list_only=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo "Usage: $0 [--dry-run] [--verbose] [--list] [--retention DAYS] [database]"
            echo ""
            echo "Creates a full backup of your Odoo system: the database AND all"
            echo "attached documents (filestore) in a single zip file."
            echo ""
            echo "  Default database:  $DEFAULT_DB"
            echo "  Backups folder:    $BACKUP_DIR"
            echo "  Kept for:          $BACKUP_RETENTION_DAYS days (older ones are removed)"
            echo ""
            echo "Examples:"
            echo "  $0                    Back up the default database"
            echo "  $0 --list             Show existing backups"
            echo "  $0 --retention 30     Keep backups for 30 days"
            echo ""
            echo "To restore a backup:  ${SCRIPT_DIR}/odoo_restore.sh <backup_file>"
            exit 0
            ;;
        --list)
            list_only=true
            ;;
        --retention)
            retention_days="${2:-}"
            if [[ ! "$retention_days" =~ ^[0-9]+$ || "$retention_days" -lt 1 ]]; then
                print_error "--retention expects a number of days (got: '${retention_days}')"
                exit 1
            fi
            shift
            ;;
        -*)
            print_error "Unknown option: $1 (see --help)"
            exit 1
            ;;
        *)
            database="$1"
            ;;
    esac
    shift
done

database="${database:-$DEFAULT_DB}"

# --list: show existing backups and exit
if [[ "$list_only" == "true" ]]; then
    print_step "Backups in $BACKUP_DIR"
    if ! ls "${BACKUP_DIR}"/backup_*.zip &>/dev/null; then
        print_info "No backups yet. Run '$0' to create one."
        exit 0
    fi
    for f in "${BACKUP_DIR}"/backup_*.zip; do
        size=$(stat -c%s "$f" 2>/dev/null || echo 0)
        printf '  %s  %8s  %s\n' \
            "$(date -r "$f" +'%Y-%m-%d %H:%M')" "$(format_size "$size")" "$(basename "$f")"
    done
    exit 0
fi

timestamp=$(date +'%Y%m%d_%H%M%S')
backup_file="${BACKUP_DIR}/backup_${database}_${timestamp}.zip"
start_time=$SECONDS

print_step "Odoo Backup (CLI): $database"
print_info "Target: $backup_file"

# Pre-checks
require_command pg_dump || exit 1
require_command zip || exit 1
validate_pg_connection || exit 1

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

# Create backup directory before the disk-space check
mkdir -p "$BACKUP_DIR"

# Require free space for what we are about to write: DB + filestore size
# (the zip is smaller, but dump + copy coexist in the temp dir), min 500 MB.
db_size_mb=$(sudo -u "$ODOO_USER" psql -d postgres -tAc \
    "SELECT pg_database_size('$database') / 1048576" 2>/dev/null || echo 0)
fs_size_mb=$(sudo du -sm "${ODOO_FILESTORE_PATH}/${database}" 2>/dev/null | cut -f1 || echo 0)
need_mb=$(( db_size_mb + fs_size_mb + 500 ))
print_info "Estimated size: database $(format_size $((db_size_mb * 1048576))), documents $(format_size $((fs_size_mb * 1048576)))"
check_disk_space "$BACKUP_DIR" "$need_mb" || exit 1

# Temp dir owned by ODOO_USER so pg_dump (peer auth) can write directly.
# Kept world-readable for traversal; cleanup uses sudo because contents are odoo19's.
tmp_dir=$(sudo -u "$ODOO_USER" mktemp -d)
sudo chmod 0755 "$tmp_dir"
trap 'sudo rm -rf "$tmp_dir"' EXIT

# pg_dump as the odoo user, writes directly into its own tmp_dir
print_info "Backing up database (this may take a few minutes)..."
sudo -u "$ODOO_USER" pg_dump --no-owner --format=c --file="${tmp_dir}/dump.sql" "$database"
dump_size=$(sudo stat -c%s "${tmp_dir}/dump.sql" 2>/dev/null || echo 0)
print_info "Database dump: $(format_size "$dump_size")"

# Filestore — cp as root (can read any user's tree, write into odoo19's tmp_dir)
filestore_path="${ODOO_FILESTORE_PATH}/${database}"
if [[ -d "$filestore_path" ]]; then
    print_info "Copying attached documents (filestore)..."
    sudo cp -a "$filestore_path" "${tmp_dir}/filestore"
else
    print_warning "No filestore found at $filestore_path"
    sudo -u "$ODOO_USER" mkdir -p "${tmp_dir}/filestore"
fi

# Hand everything to the invoker so the zip step can read without sudo
sudo chown -R "$USER:$USER" "$tmp_dir"

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
fi

# Friendly summary
total_count=$(find "$BACKUP_DIR" -type f -name "backup_${database}_*.zip" 2>/dev/null | wc -l)
echo ""
print_info "Backup file:      $backup_file"
print_info "Backups on disk:  $total_count (kept $retention_days days)"
print_info "To restore:       ${SCRIPT_DIR}/odoo_restore.sh $(basename "$backup_file")"
