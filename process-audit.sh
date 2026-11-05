#!/usr/bin/env bash

set -u

TOP_N=50
output_file=${1:-"process-audit-$(date +%Y%m%d-%H%M%S).txt"}
io_file=$(mktemp)
powertop_file=$(mktemp)

cleanup() {
    rm -f "$io_file" "$powertop_file"
}
trap cleanup EXIT

if ! : > "$output_file"; then
    printf 'Cannot write report: %s\n' "$output_file" >&2
    exit 1
fi
exec 3>&1
exec >> "$output_file"

section() {
    printf '\n%s\n' "$1"
}

section_end() {
    printf '==========\n'
}

section "PROCESS AUDIT"
printf 'Generated: %s\n' "$(date)"
host_name=$(cat /proc/sys/kernel/hostname 2>/dev/null || printf 'unknown')
printf 'Host: %s\n' "$host_name"
printf 'Note: Linux does not expose exact battery drain per process through standard tools. CPU, memory, and disk I/O are useful indicators; powertop data is included when available.\n'
section_end

section "SYSTEM LOAD AND MEMORY"
printf 'Uptime: '
uptime 2>&1 || true
printf '\nMemory:\n'
free -h 2>&1 || true
section_end

section "BATTERY / POWER DATA"
battery_found=0
for battery_dir in /sys/class/power_supply/BAT*; do
    [[ -d "$battery_dir" ]] || continue
    battery_found=1
    printf '\n%s\n' "$(basename "$battery_dir")"
    for field in status capacity energy_now energy_full power_now charge_now charge_full current_now voltage_now; do
        field_file="$battery_dir/$field"
        if [[ -r "$field_file" ]]; then
            printf '%-16s %s\n' "$field" "$(<"$field_file")"
        fi
    done
done
if (( battery_found == 0 )); then
    printf 'No battery was found under /sys/class/power_supply.\n'
fi

if command -v upower >/dev/null 2>&1; then
    printf '\nUpower summary:\n'
    upower_device=$(upower -e 2>/dev/null | sed -n '/battery/Ip' | head -n 1 || true)
    if [[ -n "$upower_device" ]]; then
        upower -i "$upower_device" 2>/dev/null || printf 'upower data is unavailable.\n'
    else
        printf 'No upower battery device is available.\n'
    fi
else
    printf '\nupower is not installed.\n'
fi

if command -v powertop >/dev/null 2>&1; then
    printf '\nPowertop:\n'
    if [[ $(id -u) -eq 0 ]] && timeout 8s powertop --time=1 --csv="$powertop_file" >/dev/null 2>&1; then
        sed -n '1,80p' "$powertop_file"
    else
        printf 'powertop is installed, but a readable sample requires root; run this script with sudo for power estimates.\n'
    fi
else
    printf '\npowertop is not installed. Install it for more detailed power estimates.\n'
fi
section_end

top_processes() {
    local title=$1
    local sort_key=$2

    section "$title"
    printf '%-8s %-16s %-24s %8s %8s %10s %10s\n' \
        PID USER COMMAND '%CPU' '%MEM' 'RSS(KiB)' ELAPSED
    ps -eo pid=,user=,comm=,%cpu=,%mem=,rss=,etime= \
        --sort="$sort_key" 2>/dev/null | head -n "$TOP_N" || true
    section_end
}

top_processes "TOP 50 BY CPU" '-%cpu'
top_processes "TOP 50 BY MEMORY" '-%mem'

for process_io in /proc/[0-9]*/io; do
    [[ -r "$process_io" ]] || continue
    pid=${process_io#/proc/}
    pid=${pid%/io}
    bytes=$(awk '/^(read_bytes|write_bytes):/ { total += $2 } END { print total + 0 }' \
        "$process_io" 2>/dev/null) || continue
    printf '%s %s\n' "$bytes" "$pid"
done > "$io_file"

section "TOP 50 BY DISK I/O"
printf '%-8s %-16s %-24s %8s %8s %10s %10s %14s\n' \
    PID USER COMMAND '%CPU' '%MEM' 'RSS(KiB)' ELAPSED 'IO(BYTES)'
while read -r total_io pid; do
    [[ -n "$pid" ]] || continue
    metadata=$(ps -p "$pid" -o user=,comm=,%cpu=,%mem=,rss=,etime= 2>/dev/null || true)
    if [[ -n "$metadata" ]]; then
        read -r user command cpu mem rss elapsed <<< "$metadata"
    else
        user=unknown
        command=exited
        cpu=unknown
        mem=unknown
        rss=unknown
        elapsed=unknown
    fi
    printf '%-8s %-16s %-24s %8s %8s %10s %10s %14s\n' \
        "$pid" "$user" "$command" "$cpu" "$mem" "$rss" "$elapsed" "$total_io"
done < <(sort -nr -k1,1 "$io_file" | head -n "$TOP_N")
section_end

section "POWER-RELATED NOTES"
printf '%s\n' \
    '- High CPU usage generally increases battery consumption.' \
    '- Disk I/O can prevent the disk and CPU from entering low-power states.' \
    '- For exact per-process power estimates, run: sudo powertop'
section_end

printf '\nReport saved to: %s\n' "$output_file" >&3
