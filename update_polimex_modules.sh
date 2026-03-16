#!/bin/bash
# Copyright (C) 2023-2026 Polimex Holding Ltd. All rights reserved.
# Website: https://polimex.co
#
# PROPRIETARY AND CONFIDENTIAL
# Unauthorized copying, modification, distribution, or use is strictly prohibited.
#
# Author: Polimex Dev Team
# Description: Update Polimex RFID modules from Git and restart Odoo
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/bash_odoo_utils"
parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+"${REMAINING_ARGS[@]}"}"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "Usage: $0 [--dry-run] [--verbose] [-d DATABASE] [-m MODULE] [--force]"
    echo "Updates Polimex RFID modules. Default module: hr_rfid"
    exit 0
fi

update_custom_module -m hr_rfid -r "${ODOO_CUSTOM_ADDONS}/polimex-rfid" "$@"
