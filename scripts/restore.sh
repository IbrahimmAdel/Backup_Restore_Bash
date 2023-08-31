#!/bin/bash

# Import functions
source backup_restore_lib.sh

# Call the validate_restore_params and restore functions
validate_restore_params "$@"
restore

echo "Restore completed successfully."

