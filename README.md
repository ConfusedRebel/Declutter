# Declutter

Bash utilities for inspecting an Arch Linux system before deciding what to
clean up. They generate text reports about storage, installed software,
services, and running processes. They do not remove packages or files.

## Requirements

Use Bash on Linux with standard GNU utilities and procps tools (`ps`, `free`,
and `uptime`). The storage audit targets Arch Linux and uses `pacman`,
`systemctl`, and `journalctl`. Flatpak, UPower, and PowerTOP are optional.
No build step is needed.

## Quick start

Clone the repository and generate both reports:

```bash
git clone https://github.com/ConfusedRebel/Declutter.git
cd Declutter
./system-audit.sh
```

The command prints the paths of two files in your current directory:

- `storage-audit-YYYYMMDD-HHMMSS.txt`
- `process-audit-YYYYMMDD-HHMMSS.txt`

To use another output directory, create it first:

```bash
mkdir -p reports
./system-audit.sh reports
```

Run as your normal user to inspect your own home directory. Storage scans can
take several minutes on large home directories or package collections.

## What each report contains

| Report | Contents |
| --- | --- |
| Storage | Installed and orphaned packages, package/cache sizes, large home directories, services, development tools, broken symlinks, and leftover package configuration files. |
| Processes | Up to 50 processes ranked separately by CPU, memory, and cumulative disk I/O bytes, plus system load and available battery/power data. |

Disk I/O totals are accumulated per process, not a live transfer rate. Power
data depends on hardware, installed tools, and permissions; these rankings do
not measure exact per-process battery drain. Missing tools or inaccessible
data can leave sections incomplete, so inspect the report before acting on it.

## Run just one audit

The storage script writes to standard output; the process script accepts an
output filename (or creates a timestamped file when no filename is given):

```bash
./storage-audit.sh > storage-report.txt
./process-audit.sh process-report.txt
```

Explicit output filenames are overwritten. Reports can contain hostnames,
usernames, paths, and installed software; review them before sharing.

## Development

`system-audit.sh` coordinates the two focused audit scripts. One smoke test
checks both report files, required process sections, and the 1–50 row limits:

```bash
for script in *.sh; do bash -n "$script" || exit; done
./test-system-audit.sh
```

The test runs the real audits and removes its temporary reports on exit. It
can take as long as a full audit. The former `test-process-audit.sh` checks are
included in this single test command.
