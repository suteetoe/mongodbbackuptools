#!/bin/bash

# MongoDB Backup Script
# This script creates backups of MongoDB databases using mongodump

set -e

# Default values (can be overridden by environment variables)
MONGODB_URI=${MONGODB_URI:-"mongodb://localhost:27017"}
MONGO_DB=${MONGO_DB:-""}
BACKUP_DIR=${BACKUP_DIR:-"/backup"}
LOG_FILE=${LOG_FILE:-"/logs/backup.log"}
DATE_FORMAT=${DATE_FORMAT:-"%A"}
RETENTION_DAYS=${RETENTION_DAYS:-"7"}

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to create backup
create_backup() {
    local timestamp=$(date +"$DATE_FORMAT")
    local backup_name="mongodb_backup_${timestamp}"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    log "Starting MongoDB backup..."
    log "Backup name: $backup_name"
    log "Backup path: $backup_path"
    
    # Build mongodump command
    local mongodump_cmd="mongodump --uri=\"$MONGODB_URI\""
    
    # Add specific database if provided
    if [ -n "$MONGO_DB" ]; then
        mongodump_cmd="$mongodump_cmd --db=\"$MONGO_DB\""
    fi
    
    # Add output directory
    mongodump_cmd="$mongodump_cmd --out=\"$backup_path\""
    
    log "Mongodump command: $mongodump_cmd"

    # Execute backup
    if eval "$mongodump_cmd" 2>&1 | tee -a "$LOG_FILE"; then
        log "Backup completed successfully"
        
        # Create compressed archive
        local archive_name="${backup_name}.tar.gz"
        local archive_path="$BACKUP_DIR/$archive_name"
        
        if tar -czf "$archive_path" -C "$BACKUP_DIR" "$backup_name" 2>&1 | tee -a "$LOG_FILE"; then
            log "Archive created: $archive_path"
            # Remove uncompressed backup directory
            rm -rf "$backup_path"
            log "Uncompressed backup directory removed"
        else
            log "ERROR: Failed to create archive"
            exit 1
        fi
    else
        log "ERROR: Backup failed"
        exit 1
    fi
}

# Function to cleanup old backups
cleanup_old_backups() {
    log "Cleaning up backups older than $RETENTION_DAYS days..."
    
    if [ "$RETENTION_DAYS" -gt 0 ]; then
        find "$BACKUP_DIR" -name "mongodb_backup_*.tar.gz" -type f -mtime +${RETENTION_DAYS} -delete 2>&1 | tee -a "$LOG_FILE"
        log "Old backups cleanup completed"
    else
        log "Retention disabled (RETENTION_DAYS=0)"
    fi
}

# Main execution
main() {
    log "MongoDB Backup Script Started"
    log "Timezone: $(cat /etc/timezone 2>/dev/null || echo 'Not set')"
    log "Current time: $(date)"
    log "Configuration:"
    log "  MongoDB URI: $MONGODB_URI"
    log "  Database: ${MONGO_DB:-'All databases'}"
    log "  Backup Directory: $BACKUP_DIR"
    log "  Retention Days: $RETENTION_DAYS"
    
    # Check if MongoDB tools are available
    if ! command -v mongodump &> /dev/null; then
        log "ERROR: mongodump command not found"
        exit 1
    fi
    
    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"
    
    # Create backup
    create_backup
    
    # Cleanup old backups
    cleanup_old_backups
    
    log "MongoDB Backup Script Completed"
}

# Run main function
main "$@"