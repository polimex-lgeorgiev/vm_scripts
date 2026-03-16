#!/bin/bash
# Copyright (C) 2023-2026 Polimex Holding Ltd. All rights reserved.
# Website: https://polimex.co
#
# PROPRIETARY AND CONFIDENTIAL
# Unauthorized copying, modification, distribution, or use is strictly prohibited.
#
# Author: Polimex Dev Team
# Description: Toggle single-database mode in Odoo config (comment/uncomment db_name)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/bash_odoo_utils"
parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+"${REMAINING_ARGS[@]}"}"

CONFIG_FILE="$ODOO_CONF_PATH"
DB_NAME_LINE="db_name ="

print_usage() {
    echo "Usage: $0 [--dry-run] [--yes] <on|off>"
    echo "  on  : Uncomment the db_name line (single-database mode)"
    echo "  off : Comment the db_name line (multi-database mode)"
}

# Root check
if [[ "$(id -u)" -ne 0 ]]; then
    print_error "This script requires root access. Please run with sudo."
    exit 1
fi

if [[ $# -eq 0 ]]; then
    print_usage
    exit 1
fi

# Show current state
print_info "Config file: $CONFIG_FILE"
current_line=$(grep -E "^;?${DB_NAME_LINE}" "$CONFIG_FILE" 2>/dev/null || true)
if [[ -n "$current_line" ]]; then
    print_info "Current state: $current_line"
fi

case "$1" in
    off)
        if [[ "$DRY_RUN" == "true" ]]; then
            print_dry_run "Comment db_name line in $CONFIG_FILE"
            print_dry_run "Restart service $ODOO_SERVICE_NAME"
            exit 0
        fi
        confirm_action "Comment db_name line (switch to multi-database mode)?" || exit 0
        sed -i "/^${DB_NAME_LINE}/s/^/;/" "$CONFIG_FILE"
        print_success "db_name line has been commented (multi-database mode)"
        sudo systemctl restart "$ODOO_SERVICE_NAME"
        ;;
    on)
        if [[ "$DRY_RUN" == "true" ]]; then
            print_dry_run "Uncomment db_name line in $CONFIG_FILE"
            print_dry_run "Restart service $ODOO_SERVICE_NAME"
            exit 0
        fi
        confirm_action "Uncomment db_name line (switch to single-database mode)?" || exit 0
        sed -i "/^;${DB_NAME_LINE}/s/;//" "$CONFIG_FILE"
        print_success "db_name line has been uncommented (single-database mode)"
        sudo systemctl restart "$ODOO_SERVICE_NAME"
        ;;
    *)
        print_usage
        exit 1
        ;;
esac

# Show new state
new_line=$(grep -E "^;?${DB_NAME_LINE}" "$CONFIG_FILE" 2>/dev/null || true)
if [[ -n "$new_line" ]]; then
    print_info "New state: $new_line"
fi
