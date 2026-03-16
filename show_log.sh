#!/bin/bash
# Copyright (C) 2023-2026 Polimex Holding Ltd. All rights reserved.
# Website: https://polimex.co
#
# PROPRIETARY AND CONFIDENTIAL
# Unauthorized copying, modification, distribution, or use is strictly prohibited.
#
# Author: Polimex Dev Team
# Description: Show Odoo log with optional line count and error filtering
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/bash_odoo_utils"
parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+"${REMAINING_ARGS[@]}"}"

case "${1:-}" in
    -h|--help)
        echo "Usage: $0 [-n LINES] [--errors [-n COUNT]]"
        echo "  (no args)     Tail log (live follow)"
        echo "  -n LINES      Number of lines to show (default: 50)"
        echo "  --errors      Show last errors/warnings instead of tailing"
        exit 0
        ;;
    --errors)
        shift
        odoo_errors "$@"
        ;;
    *)
        odoo_logs "$@"
        ;;
esac
