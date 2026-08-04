#!/bin/bash
# Copyright (C) 2023-2026 Polimex Holding Ltd. All rights reserved.
# Website: https://polimex.co
#
# PROPRIETARY AND CONFIDENTIAL
# Unauthorized copying, modification, distribution, or use is strictly prohibited.
#
# Author: Polimex Dev Team
# Description: Update Polimex modules (all tracked repos) from Git and restart Odoo.
#              Missing repos are cloned (private ones via the shared read-only
#              deploy key in vm_scripts/keys/) and their symlinks created.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/bash_odoo_utils"
parse_common_args "$@"
set -- "${REMAINING_ARGS[@]+"${REMAINING_ARGS[@]}"}"

# Tracked repos: "<dir under ODOO_CUSTOM_ADDONS>:<module to upgrade>:<clone URL>"
POLIMEX_REPOS=(
    "polimex-rfid:hr_rfid:https://github.com/polimex/polimex-rfid.git"
    "polimex-ws:polimex_ws:git@github.com:polimex/polimex-ws.git"
)

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "Usage: $0 [--dry-run] [--verbose] [-d DATABASE] [-m MODULE] [--force]"
    echo "Updates all tracked Polimex repos (cloning missing ones):"
    for pair in "${POLIMEX_REPOS[@]}"; do
        rest="${pair#*:}"
        echo "  - ${pair%%:*} (module ${rest%%:*})"
    done
    echo "With explicit -m MODULE (optionally -r REPO_PATH) only that module is"
    echo "updated (single mode; default repo: polimex-rfid)."
    exit 0
fi

# Single-module mode: explicit -m/-r narrows the run to one update call
single_mode=false
for arg in "$@"; do
    case "$arg" in
        -m|--module|-r|--repo) single_mode=true; break ;;
    esac
done
if [[ "$single_mode" == "true" ]]; then
    update_custom_module -m hr_rfid -r "${ODOO_CUSTOM_ADDONS}/polimex-rfid" "$@"
    exit $?
fi

# Shared deploy key must be in place before any git@ fetch/clone
ensure_odoo_ssh_key

rc=0
for pair in "${POLIMEX_REPOS[@]}"; do
    repo_dir="${pair%%:*}"
    rest="${pair#*:}"
    module="${rest%%:*}"
    git_url="${rest#*:}"
    repo_path="${ODOO_CUSTOM_ADDONS}/${repo_dir}"

    if [[ ! -d "$repo_path/.git" ]]; then
        print_warning "Repo not present: $repo_path — cloning"
        if ! clone_custom_repo "$repo_path" "$git_url"; then
            rc=1
            continue
        fi
        # Fresh clone: force so an already-installed module gets its -u run
        update_custom_module -m "$module" -r "$repo_path" --force "$@" || rc=1
    else
        update_custom_module -m "$module" -r "$repo_path" "$@" || rc=1
    fi
done
exit $rc
