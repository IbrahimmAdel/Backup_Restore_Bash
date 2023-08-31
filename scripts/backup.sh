#!/bin/bash

# Import functions
source backup_restore_lib.sh

# Call the validate_backup_params and backup functions
validate_backup_params "$@"
backup

echo "Backup completed successfully."







