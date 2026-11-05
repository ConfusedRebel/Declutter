#!/usr/bin/env bash

set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
output_file=$(mktemp)
trap 'rm -f "$output_file"' EXIT

"$script_dir/process-audit.sh" "$output_file"

grep -q '^PROCESS AUDIT$' "$output_file"
grep -q '^TOP 50 BY CPU$' "$output_file"
grep -q '^TOP 50 BY MEMORY$' "$output_file"
grep -q '^TOP 50 BY DISK I/O$' "$output_file"
grep -q '^BATTERY / POWER DATA$' "$output_file"
! grep -q 'command not found' "$output_file"
! grep -q 'UPower-WARNING' "$output_file"

section_rows() {
    awk -v section="$1" '
        $0 == section { in_section=1; next }
        in_section && /^==========/ { exit }
        in_section && /^[[:space:]]*[0-9]+[[:space:]]/ { count++ }
        END { print count + 0 }
    ' "$output_file"
}

for section in 'TOP 50 BY CPU' 'TOP 50 BY MEMORY' 'TOP 50 BY DISK I/O'; do
    rows=$(section_rows "$section")
    (( rows > 0 && rows <= 50 ))
done

echo "process-audit smoke test passed"
