#!/bin/bash

# Variables for the remote server that will perform backup and restore on/from it. In this case, it is an EC2 instance on AWS
export server_username='ubuntu' 
export server_ip='16.171.21.57'
export server_key='/home/ibrahim/Downloads/key.pem'

# Function to validate the 4 parameter of backup.sh script
validate_backup_params() {
    if [ $# -ne 4 ]; then
        echo "Usage: $0 source_directory backup_directory encryption_key days_threshold"
        echo "1- source_directory: Path of the directory to be backed up."
        echo "2- backup_directory: Path of the directory in the remote server that should store the backup."
        echo "3- encryption_key: Key that will be used to encrypt the backup directory."
        echo "4- days_threshold: Number of days (n) to backup changed files during the last n days."
        exit 1    
    fi

    # Store the 4 parameters in variables
    source_directory="$1"    
    backup_directory="$2"
    encryption_key="$3"
    days_threshold="$4"

    # Check if source directory exist
    if [ ! -d "$source_directory" ]; then
        echo "Error: $source_directory does not exist, Please make to enter the correct directory."
        exit 1
    fi

    # Check if backup directory exists on the remote server. if not, create it
    ssh_check_result=$(ssh -i $server_key $server_username@$server_ip "[ -d '$backup_directory' ] && echo 'exists' || echo 'notexists'")

    if [ "$ssh_check_result" = "notexists" ]; then
        echo "$backup_directory does not exist on the remote server. Creating it..."

        # Create backup directory in the remote server to store the backup files
        ssh -i $server_key $server_username@$server_ip "sudo mkdir -p '$backup_directory' && sudo chown ubuntu:ubuntu '$backup_directory' && sudo chmod 775 '$backup_directory'"
        echo "$backup_directory is successfully created on the remote server."
    fi

    # Check if encryption key is valid
    if ! gpg --list-keys | grep -q "$encryption_key"; then
        echo "Error: GPG key '$encryption_key' not found. Please make sure to enter the correct key"
        exit 1
    fi

    # Check if days_threshold is a valid positive integer
    if ! [[ "$days_threshold" =~ ^[1-9][0-9]*$ ]]; then
        echo "Error: Invalid number of days."
        exit 1
    fi   
}

# function to perform backup
backup() {

    # Capture the current date
    snapshot_date=$(date +"%d_%m_%Y")        # %d:day, %m:month, %Y:year , example: snapshot_date: 24_8_2023

    # Create a directory to store all modified files within the source directory to be backedup
    backup_dir="${snapshot_date}"
    mkdir -p $backup_dir


    # Loop over all sub-directories in the source directory to capture all modified files within each sub-directory
    for subdir in "$source_directory"/*/; do
        if [ -d "$subdir" ]; then
            dir_name=$(basename "$subdir")
            modified_files=0

            # Create a list of modified files in the sub-directory
            modified_file_list=()

            # Loop over all files in the subdirectory and add modified files to the list
            for file in "$subdir"/*; do
                if [ -f "$file" ]; then
                    if [ $(stat -c %Y "$file") -ge $(date -d "-$days_threshold days" +%s) ]; then
                        modified_files=1
                        modified_file_list+=("$(basename "$file")")
                    fi
                fi
            done

            # If there is modified files in the list, put them in tar file & encrypt them, then remove the tar file after generate an encrypted one 
            if [ "$modified_files" -eq 1 ]; then
                # Create a .tgz archive for modified files in the sub-directories
                tar -czf "${backup_dir}/${dir_name}_${snapshot_date}.tgz" -C "$subdir" "${modified_file_list[@]}"
                # Encrypt the .tgz file
                gpg --encrypt --recipient "$encryption_key" "${backup_dir}/${dir_name}_${snapshot_date}.tgz"
                # Remove the .tgz files after encrypting them
                rm "${backup_dir}/${dir_name}_${snapshot_date}.tgz"
            fi
        fi
    done


    # Check if there are encrypted .tgz files in backup_dir
    if [ -n "$(ls -A ${backup_dir}/*.tgz.gpg 2>/dev/null)" ]; then

        # Initialize the combined tar archive
        combined_tar="${backup_dir}/all_files_${snapshot_date}.tar"

        # Flag to track whether it's the first encrypted file
        first_encrypted=0

        # Loop over all encrypted files in backup_dir and append them to the combined tar archive one by one
        for encrypted_file in "${backup_dir}"/*.tgz.gpg; do

            # Extract the file name without the extension
            file_name=$(basename "${encrypted_file%.tgz.gpg}")

            # If it is the first file, create a new tar file, if not, append this file to the first created tar file
            if [ $first_encrypted -eq 0 ]; then  

                # Create a new tar file and add the first encrypted file
                tar -cf "$combined_tar" -C "$backup_dir" "$file_name.tgz.gpg"
                first_encrypted=1  # Set first_encrypted to 1 after creating the first tar
            else
                # Append the encrypted file to the combined tar archive using the update switch
                tar -rf "$combined_tar" -C "$backup_dir" "$file_name.tgz.gpg"
            fi
        done

        # Compress the combined tar file
        gzip "$combined_tar"

        # Encrypt the compressed combined tar file
        gpg --encrypt --recipient "$encryption_key" "${combined_tar}.gz"

        # Remove the original compressed combined tar file
        rm "${combined_tar}.gz"

        # Remove the individual encrypted .tgz files in backup directory after put them all in one tar file
        rm "${backup_dir}"/*.tgz.gpg

        # Copy the backup_dir to the remote server
        scp -i $server_key -r ${backup_dir} $server_username@$server_ip:"$backup_directory"

        # Clean up - remove the backup_dir locally after copying it to the remote server
        rm -r "${backup_dir}"

    # If there is no encrypted .tgz files in backup_dir, that means there is no modified file within the days_threshold
    else
        echo "there are no modified files in $source_directory within the last $days_threshold day(s) to be backedup"
        rmdir $backup_dir
    fi

}

# function to validate the 3 parameter of restore.sh script
validate_restore_params () {

    # Check if the script received the correct number of parameters
    if [ $# -ne 3 ]; then
        echo "Usage: $0  backup_directory restored_directory decryption_key"
        echo " 1- backup_directory: Path of the directory on the remote server that contains the file you want to restore."
        echo " 2- restored_directory: Path of the directory that the backup should be restored to."
        echo " 3- decryption_key: Key that will be used to decrypt the backup directory."
        exit 1
    fi

    # Store the 3 parameters in variables
    backup_directory="$1"
    restored_directory="$2"    
    decryption_key="$3"


    # Check if backup directory exist on the remote server
    ssh_check_result=$(ssh -i $server_key $server_username@$server_ip "[ -d '$backup_directory' ] && echo 'exists' || echo 'notexists'")

    if [ "$ssh_check_result" = "notexists" ]; then
        echo "Error: Backup directory does not exist on the remote server, please make sure to enter the correct directory "
        exit 1
    fi

    # Check if restored directory exist. if not, create it
    if [ ! -d "$restored_directory" ]; then
        echo "Restored directory does not exist. Creating it..."
        mkdir -p $restored_directory
        echo "$restored_directory is successfully created"
        exit 1
    fi

    # Check if decryption key is valid
    if ! gpg --list-keys | grep -q "$decryption_key"; then
        echo "Error: GPG key '$decryption_key' not found. Please make sure to enter the correct key."
        exit 1
    fi
}

# Function to restore
restore () {   

    # Create a temporary directory within the restored directory
    mkdir -p "$restored_directory/temp_restore"     

    # Restore the files inside the backup_directory on the remote server to the temp_dir
    scp -i $server_key -r $server_username@$server_ip:$backup_directory/* $restored_directory/temp_restore

    # Check and decrypt the encrypted backup files inside temp_restore
    encrypted_files=("$restored_directory/temp_restore"/*.tar.gz.gpg)
    if [ ${#encrypted_files[@]} -gt 0 ]; then

        # Loop over the encrypted files
        for encrypted_file in "${encrypted_files[@]}"; do

            # Decrypt the file using the provided decryption_key
            decrypted_file="${encrypted_file%.gpg}"
            gpg --output "$decrypted_file" --decrypt --recipient "$decryption_key" "$encrypted_file"

            # Extract the decrypted tar file
            tar -xzf "$decrypted_file" -C "${decrypted_file%/*}"

            # Remove the decrypted tar file and the encrypted file
            rm "$decrypted_file" "$encrypted_file"
        done
    fi

    # Loop over the extracted files
    for content in "$restored_directory/temp_restore"/*; do
        if [ -f "$content" ]; then

            # Decrypt the file using the provided decryption_key
            decrypted_file="${content%.gpg}"
            gpg --output "$decrypted_file" --decrypt --recipient "$decryption_key" "$content"
            
            # Check if the decrypted file is a tar.gz file
            if [[ "$decrypted_file" == *.tgz ]]; then

                # Create a directory with the same name as the decrypted file
                extraction_dir="${decrypted_file%.tgz}"
                mkdir "$extraction_dir"

                # Extract the decrypted tar file into the extraction directory
                tar -xzf "$decrypted_file" -C "$extraction_dir"
                
                # Remove the decrypted tar file and the encrypted file
                rm "$decrypted_file" "$content"
            fi
        fi
    done
}
