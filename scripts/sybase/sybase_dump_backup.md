# Sybase ASE Dump Backup Script for Dell PPDM Generic Application Protection

This README provides a comprehensive overview and operational guidance for the **Sybase ASE Dump Backup Script**, designed for use with Dell PowerProtect Data Manager (PPDM) as a Generic Application Protection workflow. It enables automated full database and transaction log backups for SAP/Sybase ASE databases.

---

## Overview

This script automates backup of SAP Sybase ASE databases using `isql` to execute `dump database` (full) or `dump transaction` (log) commands. Backup files are written to the PPDM-managed target directory (BoostFS or NFS mount).

---

## PPDM Generic Application Protection Context

PPDM's Generic Application Protection supports custom workloads by executing scripts that export data to PPDM-managed storage.

This script:

- Exports Sybase ASE database backups to a defined directory
- Uses PPDM environment variables for credentials, paths, and backup level
- Supports `FULL` and `LOG` backup levels
- Accepts the database name via script argument (`-d`)

---

## Features

- Full database backup via `dump database`
- Transaction log backup via `dump transaction`
- Automatic timestamped dump file naming
- Sources Sybase environment (`SYBASE.sh`) for proper library paths
- Uses the interfaces file (`-I`) for reliable server connectivity
- Sets locale to `en_US.UTF-8` to prevent localization errors

---

## Prerequisites

### Sybase ASE Server

- SAP Sybase ASE 16.x installed and running
- Backup Server (`SYB_BACKUP`) must be running
  - **Important:** Start the Backup Server with the `-M` flag pointing to the `sybmultbuf` binary, not the ASE directory:
    ```bash
    /opt/sap/ASE-16_0/bin/backupserver \
      -SSYB_BACKUP \
      -e/opt/sap/ASE-16_0/install/SYBASE_BS.log \
      -I/opt/sap/interfaces \
      -M/opt/sap/ASE-16_0/bin/sybmultbuf &
    ```
- The `interfaces` file must exist with entries for both the ASE server and Backup Server
  - **Important:** Lines must use TAB indentation (not spaces)
- For transaction log backups (`LOG`), the database must have a separate log device/segment

### Interfaces File Format

```
SYBASE_SERVER
	master tcp ether <hostname> <port>
	query tcp ether <hostname> <port>

SYB_BACKUP
	master tcp ether <hostname> <backup_server_port>
	query tcp ether <hostname> <backup_server_port>
```

> The indentation before `master` and `query` must be a TAB character.

### PPDM Environment

- PPDM Generic Application Protection configured
- Environment variables set by PPDM agent:

```bash
DD_TARGET_DIRECTORY="/path/to/output"
ASSET_USERNAME="sa"
ASSET_PASSWORD="password"
BACKUP_LEVEL="FULL"   # or "LOG"
```

---

## Script Configuration

Update these variables in the script to match your Sybase installation:

| Variable | Default Value | Description |
|----------|---------------|-------------|
| `SYBASE_HOME` | `/opt/sap` | Sybase installation directory |
| `SYBASE_SERVER` | `SYBASE_SERVER` | ASE server name (as in interfaces file) |
| `ISQL` | `${SYBASE_HOME}/OCS-16_0/bin/isql` | Path to `isql` binary (check your OCS version) |
| `INTERFACES` | `${SYBASE_HOME}/interfaces` | Path to interfaces file |

---

## Script Usage

### Required Environment Variables

| Variable | Description |
|----------|-------------|
| `DD_TARGET_DIRECTORY` | Directory for backup output (set by PPDM agent) |
| `ASSET_USERNAME` | Sybase ASE username (set by PPDM agent) |
| `ASSET_PASSWORD` | Sybase ASE password (set by PPDM agent) |
| `BACKUP_LEVEL` | Backup type: `FULL` or `LOG` (set by PPDM agent) |

### Command-Line Options

| Option | Description |
|--------|-------------|
| `-d` | Database name to back up |

### Example

```bash
export DD_TARGET_DIRECTORY="/mnt/boostfs/backup"
export ASSET_USERNAME="sa"
export ASSET_PASSWORD="YourPassword"
export BACKUP_LEVEL="FULL"

./sybase_dump_backup_sample_script.sh -d mydb
```

---

## Operational Flow

1. **Configuration**: Reads script variables and environment variables
2. **Environment Setup**: Sources `SYBASE.sh` and sets locale
3. **Backup Execution**:
   - `FULL`: Executes `dump database <dbname> to '<dump_file>'`
   - `LOG`: Executes `dump transaction <dbname> to '<dump_file>'`
4. **Output**: Writes dump file to `DD_TARGET_DIRECTORY` with timestamped filename

---

## Output Structure

```
DD_TARGET_DIRECTORY/
├── mydb_FULL_20260330_120000.dmp
├── mydb_LOG_20260330_130000.dmp
└── ...
```

Each file is a Sybase native dump file that can be restored using `load database` or `load transaction`.

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `ct_connect(): network packet layer` error | Add `-I` flag to `isql` command pointing to the interfaces file |
| `locale name "POSIX" doesn't exist` | Set `LANG=en_US.UTF-8` and `LC_ALL=en_US.UTF-8` before running `isql` |
| `Can't open a connection to site 'SYB_BACKUP'` | Ensure Backup Server is running and has an entry in the interfaces file |
| `execve call failed... Permission denied` for sybmultbuf | Start Backup Server with `-M /path/to/bin/sybmultbuf` (full path to binary, not directory) |
| `Syslogs does not exist in its own segment` for LOG backup | Database needs a separate log device; use `FULL` backup or recreate DB with `log on` clause |
| Interfaces file parse errors | Ensure TAB indentation (not spaces) for `master` and `query` lines |

---

## Limitations and Notes

- Transaction log backups require the database to have a separate log segment
- No restore functionality included in this script
- Backup Server must be running before executing dump commands
- The script does not currently support compression or multi-stripe dumps

---

## License

MIT License -- see script header for full terms.

---

## References

- SAP Sybase ASE Administration Guide
- Dell PPDM User Guide -- Generic Application Protection
