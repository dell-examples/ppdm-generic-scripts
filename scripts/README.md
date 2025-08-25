
# PPDM Generic Application Agent Script Index

This repository contains example scripts for Dell PowerProtect Data Manager (PPDM) Generic Application Agent, supporting integration and protection for PaaS and cloud-native workloads.  
Each script entry includes a link to its documentation, the author, and the PPDM version it was tested with.

|   Workload    | Agent Type | Provider | CLOUD | Script                | Documentation Link                                              | Author           | Tested PPDM Version |
|---------------|------------|----------|-------|---------------------- |--------------------------------------------------------------- |----------------- |--------------------|
| Azure DNS     |    PAAS    |  DNS     | Azure | [azure_dns_backup](azure_dns_backup/)       | [azure_dns_backup.md](azure_dns_backup/azure_dns_backup.md)    | karsten.bott@dell.com    | 19.20      |
| Azure Keyvault|    PAAS    |  keyvault| Azure | [azure_keyvault_backup](azure_keyvault_backup/)| [azure_keyvault_backup.md](azure_keyvault_backup/azure_keyvault_backup.md) | karsten.bott@dell.com    | 19.20      |
| Entra ID      |    PAAS    |  Graph   | Azure | [entraID_backup](entraId_backup/)        | [entraID_backup.md](entraId_backup/entraID_backup.md)          | karsten.bott@dell.com     | 19.20      |
| GitHub        |    PAAS    |  git     |   --  | [git_backup_array](git_backup_array/)       | [git_backup_array.md](git_backup_array/git_backup_array.md)    | karsten.bott@dell.com     | 19.20      |
| S3 Backup     |    PAAS    |  rclone  | any   | [s3_backup_rclone.md](s3_backup_rclone/)      | [s3_backup_rclone.md](s3_backup_rclone/s3_backup_rclone.md)   | karsten.bott@dell.com     | 19.20      |

