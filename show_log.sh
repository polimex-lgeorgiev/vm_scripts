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

# Interactive menu when no arguments and connected to a terminal
interactive_menu() {
    echo ""
    echo -e "${_BOLD}${_CYAN}  Odoo Log Analysis${_NC}  ($ODOO_LOG_PATH)"
    echo ""
    echo -e "  ${_BOLD}1)${_NC}  Live tail            — Follow log in real time"
    echo -e "  ${_BOLD}2)${_NC}  Summary              — Statistics overview"
    echo -e "  ${_BOLD}3)${_NC}  Last errors           — Recent ERROR entries"
    echo -e "  ${_BOLD}4)${_NC}  Last warnings         — Recent WARNING entries"
    echo -e "  ${_BOLD}5)${_NC}  Search                — Find pattern in log"
    echo -e "  ${_BOLD}6)${_NC}  Cron jobs             — Scheduled action activity"
    echo -e "  ${_BOLD}7)${_NC}  Slow requests         — HTTP requests above threshold"
    echo -e "  ${_BOLD}8)${_NC}  Databases             — List databases in log"
    echo -e "  ${_BOLD}q)${_NC}  Quit"
    echo ""
    echo -en "  ${_BOLD}Choose [1-8, q]:${_NC} "
    read -r choice

    case "$choice" in
        1)
            odoo_logs
            ;;
        2)
            odoo_log_summary
            ;;
        3)
            echo -en "  How many entries? [20]: "
            read -r n
            n="${n:-20}"
            odoo_errors -n "$n"
            ;;
        4)
            echo -en "  How many entries? [20]: "
            read -r n
            n="${n:-20}"
            odoo_warnings -n "$n"
            ;;
        5)
            echo -en "  Search pattern: "
            read -r pattern
            if [[ -z "$pattern" ]]; then
                print_error "Pattern is required"
                return 1
            fi
            echo -en "  How many results? [50]: "
            read -r n
            n="${n:-50}"
            odoo_log_search -p "$pattern" -n "$n"
            ;;
        6)
            echo -en "  How many entries? [20]: "
            read -r n
            n="${n:-20}"
            odoo_log_cron -n "$n"
            ;;
        7)
            echo -en "  Threshold in seconds? [5.0]: "
            read -r t
            t="${t:-5.0}"
            odoo_log_slow -t "$t"
            ;;
        8)
            odoo_log_databases
            ;;
        q|Q|"")
            exit 0
            ;;
        *)
            print_error "Invalid choice: $choice"
            exit 1
            ;;
    esac
}

# If no arguments and interactive terminal → show menu
if [[ $# -eq 0 && -t 0 ]]; then
    interactive_menu
    exit 0
fi

# Non-interactive / with arguments
case "${1:-}" in
    -h|--help)
        echo "Usage: $0 [command] [options]"
        echo ""
        echo "Without arguments: interactive menu (when in terminal)"
        echo ""
        echo "Commands:"
        echo "  errors          Show last errors"
        echo "  warnings        Show last warnings"
        echo "  search          Search for pattern in logs"
        echo "  summary         Log statistics (counts, top modules)"
        echo "  cron            Show cron job activity"
        echo "  slow            Show slow HTTP requests"
        echo "  databases       List databases in log"
        echo "  tail            Live follow (also: -f)"
        echo ""
        echo "Common options:"
        echo "  -n COUNT        Number of entries"
        echo "  --since DATE    Start time (e.g., '2026-03-16')"
        echo "  --until DATE    End time"
        echo "  --module MOD    Filter by Odoo module"
        echo "  --traceback     Include traceback lines"
        echo "  --count         Only show count (errors/warnings)"
        exit 0
        ;;
    errors)     shift; odoo_errors "$@" ;;
    warnings)   shift; odoo_warnings "$@" ;;
    search)     shift; odoo_log_search "$@" ;;
    summary)    shift; odoo_log_summary "$@" ;;
    cron)       shift; odoo_log_cron "$@" ;;
    slow)       shift; odoo_log_slow "$@" ;;
    databases)  shift; odoo_log_databases "$@" ;;
    tail|-f)    shift; odoo_logs "$@" ;;
    *)          odoo_logs "$@" ;;
esac
