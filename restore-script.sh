#!/bin/bash

# MongoDB Restore Script
# This script restores MongoDB databases using mongorestore

set -e

# Default values (can be overridden by environment variables)
MONGO_HOST=${MONGO_HOST:-"localhost"}
MONGO_PORT=${MONGO_PORT:-"27017"}
MONGO_DB=${MONGO_DB:-""}
MONGO_USER=${MONGO_USER:-""}
MONGO_PASSWORD=${MONGO_PASSWORD:-""}
MONGO_AUTH_DB=${MONGO_AUTH_DB:-"admin"}
BACKUP_DIR=${BACKUP_DIR:-"/backup"}
LOG_FILE=${LOG_FILE:-"/logs/restore.log"}
RESTORE_FILE=${RESTORE_FILE:-""}
DROP_EXISTING=${DROP_EXISTING:-"false"}

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to list available backups
list_backups() {
    log "Available backup files:"
    find "$BACKUP_DIR" -name "mongodb_backup_*.tar.gz" -type f -exec basename {} \; | sort
}

# Function to restore backup
restore_backup() {
    local restore_file="$1"
    local restore_path="$BACKUP_DIR/$restore_file"
    
    if [ ! -f "$restore_path" ]; then
        log "ERROR: Backup file not found: $restore_path"
        exit 1
    fi
    
    log "Starting MongoDB restore..."
    log "Restore file: $restore_file"
    
    # Extract backup archive
    local temp_dir="/tmp/restore_$(date +%s)"
    mkdir -p "$temp_dir"
    
    if tar -xzf "$restore_path" -C "$temp_dir" 2>&1 | tee -a "$LOG_FILE"; then
        log "Backup archive extracted to: $temp_dir"
    else
        log "ERROR: Failed to extract backup archive"
        exit 1
    fi
    
    # Find the backup directory
    local backup_data_dir=$(find "$temp_dir" -name "mongodb_backup_*" -type d | head -n 1)
    
    if [ -z "$backup_data_dir" ]; then
        log "ERROR: Could not find backup data in extracted archive"
        exit 1
    fi
    
    # Build mongorestore command
    local mongorestore_cmd="mongorestore --host $MONGO_HOST:$MONGO_PORT"
    
    # Add authentication if provided
    if [ -n "$MONGO_USER" ] && [ -n "$MONGO_PASSWORD" ]; then
        mongorestore_cmd="$mongorestore_cmd --username $MONGO_USER --password $MONGO_PASSWORD --authenticationDatabase $MONGO_AUTH_DB"
    fi
    
    # Add drop option if specified
    if [ "$DROP_EXISTING" = "true" ]; then
        mongorestore_cmd="$mongorestore_cmd --drop"
        log "Will drop existing collections before restore"
    fi
    
    # Add specific database if provided
    if [ -n "$MONGO_DB" ]; then
        # Check if specific database exists in backup
        local db_backup_dir="$backup_data_dir/$MONGO_DB"
        if [ -d "$db_backup_dir" ]; then
            mongorestore_cmd="$mongorestore_cmd --db $MONGO_DB $db_backup_dir"
        else
            log "ERROR: Database $MONGO_DB not found in backup"
            log "Available databases in backup:"
            ls -la "$backup_data_dir/"
            exit 1
        fi
    else
        # Restore all databases
        mongorestore_cmd="$mongorestore_cmd $backup_data_dir"
    fi
    
    # Execute restore
    if eval "$mongorestore_cmd" 2>&1 | tee -a "$LOG_FILE"; then
        log "Restore completed successfully"
    else
        log "ERROR: Restore failed"
        exit 1
    fi
    
    # Cleanup temporary directory
    rm -rf "$temp_dir"
    log "Temporary files cleaned up"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [backup_file.tar.gz]"
    echo ""
    echo "Environment variables:"
    echo "  MONGO_HOST        - MongoDB host (default: localhost)"
    echo "  MONGO_PORT        - MongoDB port (default: 27017)"
    echo "  MONGO_DB          - Specific database to restore (optional)"
    echo "  MONGO_USER        - MongoDB username (optional)"
    echo "  MONGO_PASSWORD    - MongoDB password (optional)"
    echo "  MONGO_AUTH_DB     - Authentication database (default: admin)"
    echo "  BACKUP_DIR        - Directory containing backups (default: /backup)"
    echo "  DROP_EXISTING     - Drop existing collections (default: false)"
    echo ""
    echo "If no backup file is specified, available backups will be listed."
}

# Main execution
main() {
    log "MongoDB Restore Script Started"
    
    # Check if MongoDB tools are available
    if ! command -v mongorestore &> /dev/null; then
        log "ERROR: mongorestore command not found"
        exit 1
    fi
    
    # Check if backup file is provided
    if [ $# -eq 0 ]; then
        if [ -n "$RESTORE_FILE" ]; then
            restore_backup "$RESTORE_FILE"
        else
            log "No backup file specified"
            list_backups
            echo ""
            show_usage
            exit 1
        fi
    else
        restore_backup "$1"
    fi
    
    log "MongoDB Restore Script Completed"
}

# Run main function
main "$@"