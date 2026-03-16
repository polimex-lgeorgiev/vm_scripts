#!/bin/bash
# Copyright (C) 2023-2026 Polimex Holding Ltd. All rights reserved.
# Website: https://polimex.co
#
# PROPRIETARY AND CONFIDENTIAL
# Unauthorized copying, modification, distribution, or use is strictly prohibited.
#
# Author: Polimex Dev Team
# Description: Clone Odoo database using pg_dump/pg_restore + filestore copy
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/bash_odoo_utils"
parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+"${REMAINING_ARGS[@]}"}"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "Usage: $0 [--dry-run] [--yes] [--no-neutralize] [source_db] [dest_db]"
    echo ""
    echo "Clones an Odoo database using pg_dump/pg_restore + filestore copy."
    echo "Default source_db: $DEFAULT_DB"
    echo "Default dest_db:   ${DEFAULT_DB}_clone"
    echo ""
    echo "Options:"
    echo "  --no-neutralize  Skip database neutralization after clone"
    echo "  --dry-run        Show what would be done without making changes"
    echo "  --yes            Skip confirmation prompts"
    exit 0
fi

odoo_clone_db "$@"
