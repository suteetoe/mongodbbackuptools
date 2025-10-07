#!/bin/bash

# Cron Setup Script
# This script configures the cron job for MongoDB backups

set -e

# Default cron schedule - 00:05 daily (5 minutes past midnight)
CRON_SCHEDULE=${CRON_SCHEDULE:-"5 0 * * *"}
BACKUP_SCRIPT=${BACKUP_SCRIPT:-"/scripts/backup-script.sh"}
LOG_FILE=${LOG_FILE:-"/logs/cron.log"}

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to setup cron job
setup_cron() {
    log "Setting up cron job for MongoDB backup..."
    log "Timezone: $(cat /etc/timezone 2>/dev/null || echo 'Not set')"
    log "Current time: $(date)"
    log "Schedule: $CRON_SCHEDULE"
    log "Script: $BACKUP_SCRIPT"
    
    # Create cron job entry
    # Redirect output to log file and ensure environment variables are available
    local cron_entry="$CRON_SCHEDULE cd /backup && $BACKUP_SCRIPT >> $LOG_FILE 2>&1"
    
    # Write cron job to crontab
    echo "$cron_entry" | crontab -
    
    log "Cron job configured successfully"
    
    # Display current crontab
    log "Current crontab:"
    crontab -l | tee -a "$LOG_FILE"
}

# Function to start cron daemon
start_cron() {
    log "Starting cron daemon..."
    
    # Start cron in foreground mode
    exec cron -f
}

# Main execution
main() {
    log "Cron Setup Script Started"
    
    # Setup cron job
    setup_cron
    
    # Start cron daemon
    start_cron
}

# Run main function
main "$@"