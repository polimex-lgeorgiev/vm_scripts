#!/bin/bash
# Copyright (C) 2023-2026 Polimex Holding Ltd. All rights reserved.
# Website: https://polimex.co
#
# PROPRIETARY AND CONFIDENTIAL
# Unauthorized copying, modification, distribution, or use is strictly prohibited.
#
# Author: Polimex Dev Team
# Description: Odoo log analysis tool — tail, errors, warnings, search, summary, cron, slow
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/bash_odoo_utils"
parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+"${REMAINING_ARGS[@]}"}"

case "${1:-}" in
    -h|--help)
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Commands:"
        echo "  (no args)       Tail log (live follow, default)"
        echo "  errors          Show last errors"
        echo "  warnings        Show last warnings"
        echo "  search          Search for pattern in logs"
        echo "  summary         Log statistics (counts, top modules)"
        echo "  cron            Show cron job activity"
        echo "  slow            Show slow HTTP requests"
        echo "  databases       List databases in log"
        echo ""
        echo "Common options:"
        echo "  -n COUNT        Number of entries (default varies by command)"
        echo "  --since DATE    Start time (e.g., '2026-03-16' or '2026-03-16 10:00')"
        echo "  --until DATE    End time"
        echo "  --module MOD    Filter by Odoo module"
        echo "  --traceback     Include traceback lines"
        echo "  --count         Only show count (errors/warnings)"
        echo ""
        echo "Examples:"
        echo "  $0                              # Live tail"
        echo "  $0 errors -n 10                 # Last 10 errors"
        echo "  $0 errors --since '2026-03-16'  # Errors since date"
        echo "  $0 warnings --module odoo.addons.sale"
        echo "  $0 search -p 'bad query' -n 20"
        echo "  $0 summary --since '2026-03-16'"
        echo "  $0 slow -t 3.0                  # Requests slower than 3s"
        echo "  $0 cron -n 30                   # Last 30 cron entries"
        echo "  $0 databases                    # List databases in log"
        exit 0
        ;;
    errors)
        shift
        odoo_errors "$@"
        ;;
    warnings)
        shift
        odoo_warnings "$@"
        ;;
    search)
        shift
        odoo_log_search "$@"
        ;;
    summary)
        shift
        odoo_log_summary "$@"
        ;;
    cron)
        shift
        odoo_log_cron "$@"
        ;;
    slow)
        shift
        odoo_log_slow "$@"
        ;;
    databases)
        shift
        odoo_log_databases "$@"
        ;;
    *)
        odoo_logs "$@"
        ;;
esac
