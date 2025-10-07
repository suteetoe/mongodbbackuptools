#!/bin/bash

# Entrypoint Script
# This script handles different modes of operation for the MongoDB backup container

set -e

LOG_FILE=${LOG_FILE:-"/logs/entrypoint.log"}

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to show usage
show_usage() {
    echo "MongoDB Backup Container - Usage:"
    echo ""
    echo "Modes of operation:"
    echo "  cron              - Run scheduled backups (default)"
    echo "  backup            - Run one-time backup"
    echo "  restore [file]    - Restore from backup file"
    echo "  list              - List available backups"
    echo "  bash              - Interactive shell"
    echo ""
    echo "Environment Variables:"
    echo "  CRON_SCHEDULE     - Cron schedule (default: '5 0 * * *' - daily at 00:05)"
    echo "  MONGO_HOST        - MongoDB host"
    echo "  MONGO_PORT        - MongoDB port"
    echo "  MONGO_DB          - Database name (optional)"
    echo "  MONGO_USER        - Username (optional)"
    echo "  MONGO_PASSWORD    - Password (optional)"
    echo "  RETENTION_DAYS    - Backup retention in days"
    echo ""
    echo "Examples:"
    echo "  docker run mongodb-backup                           # Scheduled backups"
    echo "  docker run mongodb-backup backup                    # One-time backup"
    echo "  docker run mongodb-backup restore backup_file.tar.gz"
    echo "  docker run mongodb-backup list                      # List backups"
}

# Main execution
main() {
    log "MongoDB Backup Container started"
    log "Timezone: $(cat /etc/timezone 2>/dev/null || echo 'Not set')"
    log "Current time: $(date)"
    log "Command: ${1:-cron}"
    
    case "${1:-cron}" in
        "cron")
            log "Starting cron mode with schedule: ${CRON_SCHEDULE:-'5 0 * * *'}"
            exec /scripts/setup-cron.sh
            ;;
        "backup")
            log "Running one-time backup"
            exec /scripts/backup-script.sh
            ;;
        "restore")
            if [ -n "$2" ]; then
                log "Restoring from backup: $2"
                exec /scripts/restore-script.sh "$2"
            else
                log "Listing available backups for restore"
                exec /scripts/restore-script.sh
            fi
            ;;
        "list")
            log "Listing available backups"
            echo "Available backup files:"
            find /backup -name "mongodb_backup_*.tar.gz" -type f -exec basename {} \; | sort
            ;;
        "bash"|"sh")
            log "Starting interactive shell"
            exec /bin/bash
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        *)
            log "Unknown command: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"