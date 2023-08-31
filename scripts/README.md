# BASH SCRIPTS
> This document provides an overview of the **backup.sh**, **restore.sh**, **backup_restore_lib.sh** scripts to automate backups and restore backup files to/from a remote server.
## Requirements
- Having a remote server.
- Changing the remote server variables in [backup_restore_lib.sh](https://github.com/IbrahimmAdel/Bash_Task/blob/master/scripts/backup_restore_lib.sh) with your server values.
```
# Variables for the remote server that will perform backup and restore on/from it. In this case, it is an EC2 instance on AWS
export server_username='ubuntu' 
export server_ip='16.171.21.57'
export server_key='/home/ibrahim/Downloads/key.pem'
```
- Generating a GPG Key Pair to encrypt and decrypt files
```
 gpg --gen-key
```
------
## [backup.sh](https://github.com/IbrahimmAdel/Bash_Task/blob/master/scripts/backup.sh) 
### calls 2 functions from **backup_restore_lib.sh** script 
1. ### `validate_backup_params`:
- #### validate the number of required parameters (4) to run **backup.sh** script.
- #### Then, check if source directory exist, which is the directory that will be backedup to the remote server.
- #### Then, check if backup directory exists by ssh on the remote server and search for the directory. if it dosen't exist, script will create it to store backup on it.
- #### Then, check if encryption key is valid by listing all GPG keys and serch for it.
- #### Finally, check if days_threshold is a valid positive integer.

2. ### `backup`:
- #### After validate the 4 parameters, it is time to perform backup.
- #### First, capture the current date to be used in naming the backup file.
- #### Then, create a backup directory to store all encrypted and compressed files from sub-directories in source directory. this backup directory will be copied to the remote server.
- #### Then, Loop over sub-directories in the source directory and compress and encrypt modified files within number of days that was entered in the 4th parameter in each sub-directory, and move them to the backup directory which created to store backups.
- #### Then, check if there are any files exist in the backup directory
- #### if exise, it means that there are modified files whithin provided number of days, So it will group all backup's files in a compressed and encrypted file and copy the backup_dir to the remote server
- #### if not exist, script will print "there are no modified files in $source_directory within the last $days_threshold day(s) to be backedup"
------

## [restore.sh](https://github.com/IbrahimmAdel/Bash_Task/blob/master/scripts/restore.sh)
### calls 2 functions from **backup_restore_lib.sh** script 
 1. ### `validate_restore_params`:
- #### First, validate the number of required parameters (3) to run **restore.sh** script
- #### Then, check if backup directory exists by ssh on the remote server and search for the directory. 
- #### Then, check if restore directory exist, which is the directory that will contain the restored files from the remote server, if it dosen't exist, script will create it.
- #### Then, check if decryption key is valid by listing all GPG keys and serch for it

2. ### `restore`:
- #### After validate the 3 parameters, it is time to perform restoration.
- #### First, create a temporary directory within the restored directory.
- #### Then, restore the files inside the backup directory on the remote server to the temporary directory.
- #### Then, decrypt and extract the main files that contains all the backedup files.
- #### Then, loop over the files and decrypt and extract them.
