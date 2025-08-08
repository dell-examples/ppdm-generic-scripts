# 🚀 Entra ID (Azure AD) Backup Script for Dell PPDM Generic Application Protection

This README provides technical documentation for **`entraid_backup.sh`**, a script designed for use with Dell PowerProtect Data Manager (PPDM) Generic Application Protection. It automates the export and backup of Microsoft Entra ID (formerly Azure Active Directory) configuration data using Microsoft Graph API, supporting compliant and auditable protection of cloud identity resources.

---

## 📘 Overview

`entraid_backup.sh` automates the discovery and export of a wide range of Entra ID resources—including users, groups, applications, directory roles, policies, B2C/B2B flows, and more—via the Microsoft Graph API. Authentication is handled using an Azure service principal, and all output is structured as JSON files for PPDM backup.

---

## 🛡️ PPDM Generic Application Protection Context

PPDM’s Generic Application Protection supports custom workloads via scripts that interact with application data and store it on DD BoostFS targets. This script:

- 🔐 Uses PPDM environment variables for authentication and context
- 📋 Logs operations for audit and troubleshooting
- 📦 Supports `FULL` backup level
- 🔁 Ensures repeatable, standardized protection

---

## ✨ Features

- 🌐 **Wide Coverage**: Users, groups, apps, service principals, roles, policies, B2C/B2B flows, and more
- ⚙️ **Modern API Usage**: Microsoft Graph API with pagination
- 🔒 **Secure Auth**: OAuth2 via service principal
- 📄 **Structured Logging**: Rotating logs at `/var/log/entra_backup/entra_backup.log`
- ✅ **Pre-flight Checks**: Validates `az`, `curl`, `jq`, and env vars
- 🔗 **PPDM Integration**: Follows PPDM conventions

---

## 🔑 Required Microsoft Entra ID Permissions

| 📁 Data             | 🔐 Microsoft Graph API Permissions         |
|--------------------|--------------------------------------------|
| Users, Groups      | `Directory.Read.All`, `User.Read.All`      |
| Applications       | `Application.Read.All`                     |
| Service Principals | `ServicePrincipal.Read.All`                |
| B2C/B2B, PIM       | As needed for relevant endpoints           |

> ⚠️ Use least privilege necessary for compliance and security.

---

## ⚙️ Prerequisites

- 🧰 Azure CLI, `curl`, and `jq` installed
- 🛡️ PPDM Generic Application Protection configured
- 🔐 Azure service principal with required permissions
- 📦 Environment variables set by PPDM:

```bash
DD_TARGET_DIRECTORY="/path/to/output"
ASSET_USERNAME="client-id"
ASSET_PASSWORD="client-secret"
TENANT_ID="tenant-id"
BACKUP_LEVEL="FULL"
```

---

## 🧪 Script Usage

### Required Environment Variables

| ⚙️ Variable            | 📌 Purpose                                |
|------------------------|-------------------------------------------|
| `DD_TARGET_DIRECTORY`  | Output directory for backup               |
| `ASSET_USERNAME`       | Service principal client ID               |
| `ASSET_PASSWORD`       | Service principal secret                  |
| `TENANT_ID`            | Azure tenant ID                           |
| `BACKUP_LEVEL`         | Must be `FULL`                            |

### Optional Argument

| 🏷️ Option | 🧭 Function                          |
|----------|--------------------------------------|
| `-t`     | Override tenant ID from env variable |

### ▶️ Example Run

```bash
export DD_TARGET_DIRECTORY="/tmp/entraid_backup"
export ASSET_USERNAME="sp-client-id"
export ASSET_PASSWORD="sp-client-secret"
export TENANT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export BACKUP_LEVEL="FULL"

./entraid_backup.sh
```

---

## 🔄 Operational Flow

1. ✅ **Validation**: Checks tools and env vars
2. 🔐 **Authentication**: Gets OAuth2 token
3. 📤 **Backup Execution**: Queries Graph API, exports JSON
4. 📊 **Logging**: Tracks counts, errors, and status

---

## 📦 Entra ID Objects Exported

Each object type is saved as a separate JSON file:

- 👥 Users
- 👪 Groups
- 🧩 Applications
- 🛠️ Service Principals
- 🛡️ Conditional Access Policies
- 🧾 Access Reviews
- 🧑‍⚖️ Entitlement Management
- 🔐 PIM Roles
- 🌐 App Proxy Profiles
- 🏢 Organization
- 🌍 Domains
- 📜 Policies
- 🗂️ Administrative Units
- 💳 Subscribed SKUs
- 🧬 Identity
- 🧑‍💼 Directory Roles
- 🧑‍🎓 B2C User Flows
- ✉️ B2B Invitations

---

## 📁 Output Directory Example

```
DD_TARGET_DIRECTORY/
├── Users.json
├── Groups.json
├── Applications.json
├── ServicePrincipals.json
├── ConditionalAccess.json
├── ...
```

---

## ⚠️ Limitations & Notes

- Only `FULL` backups supported
- No restore functionality included
- Requires sufficient Graph API permissions
- Backup files may contain sensitive data
- Microsoft Graph API changes may require updates

---

## 🛠️ Troubleshooting

- Check `/var/log/entra_backup/entra_backup.log`
- Validate environment variables
- Confirm service principal permissions
- Ensure required tools are installed
- Verify network access to Graph API

---

## 📄 License

Apache License – see script header for terms.

---

## 🔗 References

- Microsoft Graph API Docs
- Microsoft Entra ID Docs
- Dell PPDM User Guide: Generic Application Protection

