# 🌐 Azure DNS Backup Script for Dell PPDM Generic Application Protection

This README provides a comprehensive overview and operational guidance for the **Azure DNS Backup Script**, designed for use with Dell PowerProtect Data Manager (PPDM) as a Generic Application Protection workflow. It enables automated backup of Azure DNS zones and records to a file system for secure, policy-driven data protection.

---

## 📘 Overview

This script automates the discovery and export of all DNS zones and DNS record sets in a specified Azure subscription. It uses Azure CLI and authenticates via a service principal. Each zone's data is exported as a JSON file, ideal for backup, compliance, and recovery.

---

## 🛡️ PPDM Generic Application Protection Context

PPDM’s Generic Application Protection supports custom workloads by executing scripts that export data to PPDM-managed storage.

This script:

- 📤 Exports Azure DNS configuration to a defined directory
- 🔐 Uses PPDM environment variables for credentials and paths
- 📋 Maintains structured logs for visibility and troubleshooting
- 📦 Supports `FULL` backup level only

---

## ✨ Features

- 🔍 Discovers all DNS zones in the Azure subscription
- 📄 Exports each zone’s DNS records to `.json` files
- 📁 Organizes output for PPDM workflows
- ✅ Validates prerequisites (CLI, credentials, variables)
- 🔁 Rotates logs for audit and troubleshooting
- 🔐 Secure service principal authentication
- 🔗 Tight integration with PPDM job lifecycle

---

## 🔑 Required Azure Permissions

Assign the built-in role `DNS Zone Reader` to the service principal.

| ⚙️ Action                        | 🔐 Role               | 📍 Scope        |
|--------------------------------|-----------------------|-----------------|
| List DNS zones & read records | DNS Zone Reader       | Subscription or narrower |

---

## ⚙️ Prerequisites

- 🧰 Azure CLI installed and accessible
- 🛡️ PPDM Generic Application Protection configured
- 🔐 Service principal with correct permissions
- 📦 Environment variables set by PPDM:

```bash
DD_TARGET_DIRECTORY="/path/to/output"
ASSET_USERNAME="client-id"
ASSET_PASSWORD="client-secret"
TENANT_ID="tenant-id"
SUBSCRIPTION_ID="subscription-id"
BACKUP_LEVEL="FULL"
```

---

## 🧪 Script Usage

### Required Environment Variables

| ⚙️ Variable            | 📌 Description                          |
|------------------------|-----------------------------------------|
| `DD_TARGET_DIRECTORY`  | Directory for backup output             |
| `ASSET_USERNAME`       | Service principal client ID             |
| `ASSET_PASSWORD`       | Service principal secret                |
| `TENANT_ID`            | Azure AD tenant ID                      |
| `SUBSCRIPTION_ID`      | Azure subscription ID                   |
| `BACKUP_LEVEL`         | Backup type (`FULL` supported)          |

### Optional Command-Line Options

| 🏷️ Option | 🧭 Description                          |
|----------|------------------------------------------|
| `-t`     | Override Azure Tenant ID                 |
| `-s`     | Override Azure Subscription ID           |

---

## 🔄 Operational Flow

1. ✅ **Validation**: Checks environment variables and Azure CLI
2. 🔐 **Authentication**: Logs in and sets subscription context
3. 📤 **Backup Execution**:
   - Lists DNS zones
   - Exports DNS records per zone to JSON
4. 📋 **Logging**: Logs to `/var/log/azure_dns_backup/` with rotation

---

## 📁 Output Structure

```
DD_TARGET_DIRECTORY/
├── myzone1.com_records.json
├── corpzone.net_records.json
└── ...
```

Each file contains all record sets for its respective DNS zone.

---

## 🏃 Scripted Installation Into PPDM using provided helper Function

```bash
source ./helper/ppdm_functions.sh
export PPDM_FQDN=<ppdm.examle.com>
export PPDM_TOKEN=$(get_ppdm_token 'your password')  
# param args: each line name [ e.g -n],Default Value,Alias [parameter description], type[STRING,INTEGER,BOOLEAN,DATE,CREDENTIAL]
PARAM_ARGS=(
  "-t,'',TENANT_ID,STRING"
  "-s,'',SUBSCRIPTION_ID,STRING"
)

# set ppdm_scripts "filepath" "script name" "description" "parameter arguments"
set_ppdm_scripts \
  "./scripts/azure_dns_backup/azure_dns_backup.sh" \
  "azure_dns_backup" \
  "Script to backup an array of GitHub urls provided by a web accessible file url" \
  "${PARAM_ARGS[@]}"
```  

---
## ⚠️ Limitations & Notes

- Only `FULL` backups supported
- No restore functionality included
- JSON files may contain sensitive data—secure accordingly
- Insufficient permissions will block zone discovery

---

## 🛠️ Troubleshooting

- Check logs in `/var/log/azure_dns_backup/`
- Confirm Azure CLI installation
- Verify environment variables
- Ensure service principal has required roles

---

## 📄 License

APACHE License – see script header for full terms.

---

## 🔗 References

- Azure DNS Documentation
- Dell PPDM User Guide – Generic Application Protection

