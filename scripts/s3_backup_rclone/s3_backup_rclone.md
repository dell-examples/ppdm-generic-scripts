# 🛡️ S3 Backup Rclone Script for Dell PPDM Generic Application Protection

This README provides technical documentation and operational guidance for **`s3_backup_rclone.sh`**, a Bash script designed for **Dell PowerProtect Data Manager (PPDM)** Generic Application Protection.  
It enables automated, policy-driven backup of S3 object storage using rclone, supporting both full and incremental workflows for compliant enterprise data protection.

---

## 📘 Overview

`s3_backup_rclone.sh` automates the copying of object storage data from an S3-compatible bucket to a local PPDM-managed backup directory.

✨ **Key Features:**
- ⚡ Efficient parallel transfer streams for large datasets
- 🧾 Timestamped logging with rotation
- ✅ Input validation & error handling
- 🗂️ S3 versioning support via rclone
- 🔗 Tight PPDM integration via environment variables & job status reporting

---

## 🧩 PPDM Generic Application Protection Context

Dell PPDM’s **Generic Application Protection** allows backup of custom/third-party apps not natively supported.  
This script fits into that ecosystem by:

🔧 **Integration Highlights:**
- Uses PPDM-injected environment variables
- Logs operations for audit & troubleshooting
- Supports PPDM backup levels: `FULL` & `LOG`
- Enables repeatable protection for S3 object data

---

## 🌟 Features

- 🪣 **S3 Bucket Backup** via named rclone cloud profile
- 🔄 **Backup Levels:**
  - 🧱 `FULL`: All objects (optionally filtered by age)
  - 🧮 `LOG`: Only changed/created objects within a time window
- 🚀 **Parallel Transfers** via `--transfers`
- 🧬 **Versioning Support** with `-v` flag
- 📂 **Log Handling**: `/var/log/rclone/rclone.log` with rotation (5 × 1MB)
- 🧪 **Preflight Validation** of required variables and config paths

---

## 🧰 Prerequisites

- ✅ `rclone` installed and in `PATH`
- 🛡️ PPDM Generic Application Protection deployed
- 🔐 Rclone configured with named S3 remote profiles
- 🧬 Environment variables (typically set by PPDM):

| 🧪 Variable              | 📝 Purpose                                         |
|-------------------------|---------------------------------------------------|
| `DD_TARGET_DIRECTORY`   | Path for writing backup copies                    |
| `BACKUP_LEVEL`          | `FULL` or `LOG`                                   |
| `LAST_BACKUP_TIME`      | *(optional, for incremental backups)*             |

---

## 🚀 Script Usage

### 🔧 Required Environment Variables

| Variable             | Description                                 |
|----------------------|---------------------------------------------|
| `DD_TARGET_DIRECTORY`| Path for backup target directory            |
| `BACKUP_LEVEL`       | Must be `FULL` or `LOG`                     |

### 🛠️ Command-line Options

| Option | Description                                         |
|--------|-----------------------------------------------------|
| `-b`   | S3 bucket name *(required)*                         |
| `-c`   | rclone cloud profile/remote *(required)*            |
| `-p`   | Prefix (subdirectory) in bucket *(optional)*        |
| `-s`   | Parallel transfer streams *(optional)*              |
| `-i`   | Max age for incremental backup *(LOG mode)*         |
| `-f`   | Max age for full backup *(FULL mode)*               |
| `-v`   | Enable S3 versioning support *(optional)*           |

#### 🧪 Example: Manual Invocation

```bash
export DD_TARGET_DIRECTORY="/mnt/ppdm/s3-backup"
export BACKUP_LEVEL="FULL"
rclone config # Set up at least one S3 remote profile

./s3_backup_rclone.sh -c myremote -b my-bucket -p /data -s 8 -f 48
```

---

## 🔄 Operational Flow

1. 🧾 **Logging Setup**  
   - Ensures `/var/log/rclone/` exists  
   - Rotates log at 1MB, keeps 5 histories

2. ✅ **Validation**  
   - Checks required variables: `DD_TARGET_DIRECTORY`, `BACKUP_LEVEL`

3. 📦 **Backup Execution**  
   - `FULL`: Copies all objects (optionally filtered by age)  
   - `LOG`: Copies only changed objects since last backup  
   - Uses rclone options for parallelism and versioning

4. 📋 **Logging & Status**  
   - Logs to `/var/log/rclone/rclone.log`  
   - Exit code reflects job status for PPDM monitoring

---

## 📁 Output Structure

```
DD_TARGET_DIRECTORY/
├── (copied S3 object paths, preserving prefix and hierarchy)
└── ...
```

🗂️ Files and folders are mirrored from the S3 bucket/prefix to the target directory.

---

## 🏃 Scripted Installation Into PPDM using provided helper Function
Requires jq installed on the host

```bash
source ./helper/ppdm_functions.sh
export PPDM_FQDN=<ppdm.examle.com>
export PPDM_TOKEN=$(get_ppdm_token 'your password')  
# param args: each line name [ e.g -n],Default Value,Alias [parameter description], type[STRING,INTEGER,BOOLEAN,DATE,CREDENTIAL]

PARAM_ARGS=(
  '-b,,BUCKET,STRING'
  '-c,,CLOUD_PROFILE,STRING'
  '-p,,PREFIX,STRING'
  '-s,4,STREAMS,STRING'
  '-i,off,Incremental Max Age ms|s|m|h|d|w|M|y (default off),STRING'
  '-f,off,Full Max Age ms|s|m|h|d|w|M|y (default off),STRING'
  '-v,,VERSIONING enabled when -v is present,STRING'
)



# set ppdm_scripts "filepath" "script name" "description" "parameter arguments"
set_ppdm_scripts \
  "https://raw.githubusercontent.com/dell-examples/ppdm-generic-scripts/refs/heads/main/scripts/s3_backup_rclone/s3_backup_rclone.sh" \
  "s3_backup_rclone" \
  "Script to backup S3 and other Object Storage" \
  "${PARAM_ARGS[@]}"
```  
---

## ⚠️ Limitations & Notes

- 🔄 **Restore**: Use rclone or S3 tools to re-upload; this script is for export only
- 🧬 **Versioning**: Requires S3 versioning enabled and configured in rclone
- ⏱️ **Incremental Backup**: Needs accurate `INCREMENTAL_MAX_AGE` or `LAST_BACKUP_TIME`
- 🔐 **Security**: Secure local backup path per org standards
- 🌐 **Network**: Host must reach S3 endpoint and have valid IAM credentials
- 🎯 **Scope**: Only objects in specified bucket/prefix are backed up

---

## 🛠️ Troubleshooting

- 📄 Check `/var/log/rclone/rclone.log` for errors and stats
- 🔐 Confirm S3 credentials and rclone config
- ✅ Validate required environment variables and CLI args
- 🌐 Verify network access to S3 endpoint

---

## 📜 License

MIT License – see script header for details.

---

## 📚 References

- 📘 rclone documentation
- 📘 Dell PowerProtect Data Manager User Guide: Generic Application Protection

---

💡 This script enables automated, auditable backup of S3 buckets and objects as part of Dell PPDM workflows, supporting compliance, operational continuity, and cloud data protection best practices.
