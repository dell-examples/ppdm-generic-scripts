# Dell PPDM Generic Scripts 🚀

## Overview 📚

Welcome to a **community-driven collection of scripts** for the Dell PowerProtect Data Manager (**PPDM**) Generic Application Agent!  
Maintained by Dell employees and the broader user community—including **customers and partners**—this repo shares practical, real-world examples to accelerate your PPDM integration for diverse applications and platforms.

These scripts demonstrate:

- 🔄 Workflows for backup, recovery, and data management
- 🤖 Automation of key operations
- 🎯 Best practices for reliable, efficient data protection

**Contributions from everyone are encouraged!** If you have a script that helped you, share it—others may benefit too.

---

## Purpose 🎯

- 🗂️ **Centralized Sharing:** Reusable, peer-validated scripts designed to simplify PPDM Generic Application Agent adoption and integration.
- 🌍 **Community Maintained:** Scripts are contributed, reviewed, and improved by the community, enabling collaboration and knowledge sharing.
- 🤝 **Inclusive Contributions:** We feature scripts from Dell employees, customers, and partners to maximize solution diversity.

---

## What is the PPDM Generic Application Agent? 🛠️

The **PPDM Generic Application Agent** lets you protect modern workloads—including Platform-as-a-Service (**PaaS**) and custom applications—that aren't natively supported by PPDM.

With **PPDM 19.20**, you gain the ability to write backup data *directly to* **BoostFS**—Dell's high-performance, distributed filesystem interface.

### Key Features for PaaS with BoostFS (PPDM 19.20) ⚡

- 🧩 **Custom Backup & Restore:** Build tailored workflows using scripts to quiesce your apps, export data, and manage recovery.
- 🚀 **Direct BoostFS Integration:** Quickly send your application backup data to BoostFS, leveraging deduplication, reliability, and scale.
- 🤖 **Flexible Scripting:** Any scriptable application can be managed by PPDM—just define the required backup, restore, and validation steps.

**Scripts in this repository show real working examples for capturing, protecting, and restoring PaaS application data, leveraging BoostFS as the target.**

---

## Repository Structure 📁

| Folder         | Purpose                                                     |
| -------------- | ---------------------------------------------------------- |
| `/scripts/`    | Example scripts for workloads and scenarios                |
| `/docs/`       | Technical notes & implementation guides                    |
| `/contrib/`    | Scripts contributed by customers/partners                  |
| `README.md`    | This documentation                                         |

---

## Contribution Guidelines 🤗

We welcome all contributions—whether automating a routine task, integrating a new app, or enhancing an existing script!

1. 🍴 **Fork the Repository**
2. ➕ **Add Your Script** in the relevant folder, follow naming conventions, and add helpful comments
3. 📝 **Document**: Update/add README notes in your script folder—describe usage, requirements, and parameters
4. 🔀 **Create a Pull Request** summarizing your script, use case, and environment
5. 👀 **Peer Review:** All contributions are reviewed for quality, security, and relevance

**If sharing as a customer or partner, please indicate your affiliation in the pull request.**

---

## Community Values 🏅

- 🌈 **Inclusivity:** All scripts and constructive feedback are welcome—collaboration is key!
- 🔍 **Transparency:** Provide clear documentation and versioning for each contribution.
- 🔒 **Security:** No sensitive data, credentials, or proprietary info should be included.

---

## Getting Started 🚦

To get going:

- 💬 Check commentary in each script for usage tips
- 📄 Visit the `/docs/` folder for step-by-step setup and configuration
- 🛡️ For detailed PPDM Generic Application Agent and BoostFS guides, refer to official Dell documentation

---

## Notices ⚠️

> This repo is **community-supported**: scripts are provided as-is and not formally supported by Dell.  
> **Use in production environments is at your own risk.**

---

🖊️ **Maintainers:** Karsten Bott & Jean Sturma  
💙 **Thanks to every contributor—customers, partners, and Dell employees—for sharing knowledge and tools!**
