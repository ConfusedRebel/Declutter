#!/usr/bin/env bash

set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
output_dir=$(mktemp -d)
trap 'rm -rf "$output_dir"' EXIT

test -x "$script_dir/storage-audit.sh"
test -x "$script_dir/system-audit.sh"

wrapper_output=$(cd "$output_dir" && "$script_dir/system-audit.sh")

storage_report=$(find "$output_dir" -maxdepth 1 -type f -name 'storage-audit-*.txt' -print -quit)
process_report=$(find "$output_dir" -maxdepth 1 -type f -name 'process-audit-*.txt' -print -quit)

test -n "$storage_report"
test -n "$process_report"
grep -q '^========== SYSTEM ==========' "$storage_report"
grep -q '^PROCESS AUDIT$' "$process_report"
grep -q 'storage report:' <<< "$wrapper_output"
grep -q 'process report:' <<< "$wrapper_output"

echo "system-audit smoke test passed"
