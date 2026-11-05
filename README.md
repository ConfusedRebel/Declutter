# System Audits

- `process-audit.sh` generates a text report showing up to 50 Linux processes ranked by CPU, memory, and disk I/O usage, along with available battery and power information.
- `storage-audit.sh` generates a text report of system details, installed packages, services, storage usage, and development components.
- `system-audit.sh` runs the storage and process audits and creates a separate text report for each.
- `test-process-audit.sh` checks that `process-audit.sh` produces the expected report sections and process rankings.
- `test-system-audit.sh` checks that `system-audit.sh` creates both audit reports.

## Usage

Run the complete audit suite:

```bash
./system-audit.sh
```

This creates timestamped `storage-audit-*.txt` and `process-audit-*.txt` reports in the current directory.

Run an individual audit:

```bash
./storage-audit.sh > storage-report.txt
./process-audit.sh process-report.txt
```

Run the checks:

```bash
./test-process-audit.sh
./test-system-audit.sh
```
