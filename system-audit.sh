#!/usr/bin/env bash

set -u

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
output_dir=${1:-.}
timestamp=$(date +%Y%m%d-%H%M%S)
storage_report="$output_dir/storage-audit-$timestamp.txt"
process_report="$output_dir/process-audit-$timestamp.txt"

storage_status=0
"$script_dir/storage-audit.sh" > "$storage_report" 2>&1 || storage_status=$?

process_status=0
"$script_dir/process-audit.sh" "$process_report" >/dev/null || process_status=$?

printf 'storage report: %s\n' "$storage_report"
printf 'process report: %s\n' "$process_report"

if (( storage_status != 0 || process_status != 0 )); then
    printf 'One or more audits failed (storage=%s, process=%s).\n' \
        "$storage_status" "$process_status" >&2
    exit 1
fi
