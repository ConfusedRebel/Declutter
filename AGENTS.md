# Repository Guidelines

## Project Structure & Module Organization

This project contains Linux audit utilities written in Bash. Files live at the repository root:

- `process-audit.sh`: reports CPU, memory, disk I/O, and battery/power information.
- `storage-audit.sh`: reports system details, packages, services, and storage usage; package inspection targets Arch Linux through `pacman`.
- `system-audit.sh`: runs both audits and writes timestamped reports.
- `test-process-audit.sh` and `test-system-audit.sh`: executable smoke tests.
- `README.md`: usage instructions. `*-audit-YYYYMMDD-HHMMSS.txt` files are generated reports, not source code.

There are no separate source, asset, or build directories.

## Build, Test, and Development Commands

No compilation or dependency installation step is configured. Run scripts with Bash on Linux.

- `./system-audit.sh`: generate both reports in the current directory.
- `./system-audit.sh /tmp`: write both reports to an existing output directory.
- `./process-audit.sh /tmp/process-report.txt`: generate a process report at a chosen path.
- `./storage-audit.sh > /tmp/storage-report.txt`: capture storage audit output.
- `bash -n *.sh`: check shell syntax.
- `./test-process-audit.sh` and `./test-system-audit.sh`: run the smoke tests.

## Coding Style & Naming Conventions

Follow existing Bash style: `#!/usr/bin/env bash`, four-space indentation, snake_case functions and variables, and uppercase constants such as `TOP_N`. Use hyphenated script names and preserve executable permissions. Quote path and variable expansions, use `mktemp` for temporary files, and clean up with `trap`. Preserve graceful handling of unavailable system tools. No formatter or linter configuration is included.

## Testing Guidelines

Tests use Bash assertions, `grep`, and `awk`; no external test framework or coverage threshold is configured. Name tests `test-<utility>.sh`. Extend assertions when changing report headings, ranking limits, output paths, or failure behavior. Use temporary output locations and cleanup traps. Run both smoke tests before submitting changes.

## Commit & Pull Request Guidelines

Git metadata is unavailable in this checkout, so existing commit conventions cannot be verified. Use concise, imperative commit subjects, such as `Handle unavailable battery data`. Describe the change, relevant issue, and validation commands in pull requests. Include sanitized report excerpts when output changes.

## Report Privacy

Audit reports can expose hostnames, usernames, processes, and installed software. Review and redact reports before sharing them or adding new report artifacts to version control.
