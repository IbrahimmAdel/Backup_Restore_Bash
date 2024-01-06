# Backup and Restore 

This repository contains scripts for automating the backup and restore process of your data using a remote server. The scripts are designed to simplify the task of securely backing up and restoring files, even across different machines. The process involves encryption and decryption using GPG (GNU Privacy Guard) for data security.

## Table of Contents

- Overview
- Prerequisites
- Getting Started
  - Backup
  - Restore
  - Backup_restore_lib

## Overview

The repository includes three main scripts and a supporting library:

1. `backup.sh`: This script performs the backup process. It scans the source directory for modified files within a specified timeframe and creates encrypted tar archives of those files. These archives are then combined into a single encrypted tarball, ready for secure storage on a remote server.

2. `restore.sh`: This script handles the restoration process. It retrieves the encrypted tarball from the remote server, decrypts it, and extracts its contents. If the extracted files contain additional encrypted tar archives, these are decrypted and extracted in a recursive manner, effectively restoring the entire file structure.

3. `backup_restore_lib.sh`: This library contains shared functions and variables for the main scripts, improving modularity and code organization.

## Prerequisites

- Unix-like environment (Linux, macOS, etc.)
- Bash shell
- GnuPG (GPG) installed and configured with valid keys
- SSH access to the remote server with key-based authentication

## Getting Started 

###  Clone the Repository
```
git clone https://github.com/IbrahimmAdel/Bash_Task.git
cd scripts
```

### Set Permissions
```
chmod +x backup.sh restore.sh
```
----
## [backup_restore_lib.sh](https://github.com/IbrahimmAdel/Secure_Backup_Restore_Bash/blob/master/scripts/backup_restore_lib.sh)
----
First you need to edit remote server variables
1. `server_username`: The username for the remote server.
2. `server_ip`: The IP address or hostname of the remote server.
3. `server_key`: The path to the SSH key for authentication.
----
### [backup](https://github.com/IbrahimmAdel/Secure_Backup_Restore_Bash/blob/master/scripts/backup.sh)
----
To perform a backup, use the `backup.sh` script. This script takes four parameters:
1. `source_directory`: The directory containing files to be backed up.
2. `backup_directory`: The directory on the remote server where backups will be stored.
3. `encryption_key`: The GPG key ID used for encrypting backups.
4. `days_threshold`: The number of days to include modified files from.

Example:

```
./backup.sh /path/to/source_directory /path/to/remote/backup_directory <encryption_key> <days_threshold>
```
![](https://github.com/IbrahimmAdel/Secure_Backup_Restore_Bash/blob/master/videos/backup.gif)

----
### [restore.sh](https://github.com/IbrahimmAdel/Secure_Backup_Restore_Bash/blob/master/scripts/restore.sh)
----
The `restore.sh` script is used for the restoration process. It requires three parameters:
1. `backup_directory`: The directory on the remote server containing the backup.
2. `restored_directory`: The directory where the backup will be restored.
3. `decryption_key`: The GPG key ID used for decrypting the backup.
   
Example:

```bash
./restore.sh /path/to/remote/backup_directory /path/to/restored_directory <decryption_key>
```
![](https://github.com/IbrahimmAdel/Secure_Backup_Restore_Bash/blob/master/videos/restore.gif)
----
* ## **For more details: [Scripts](https://github.com/IbrahimmAdel/Secure_Backup_Restore_Bash/tree/master/scripts), [Screenshots](https://github.com/IbrahimmAdel/Secure_Backup_Restore_Bash/tree/master/Screenshots)** 
