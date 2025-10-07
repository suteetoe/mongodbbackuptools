# MongoDB Backup Docker Container

A Docker container for backing up and restoring MongoDB databases using MongoDB Command Line Database Tools on Debian.

## Features

- ✅ Built on Debian (bookworm-slim)
- ✅ MongoDB Command Line Database Tools (mongodump, mongorestore)
- ✅ Automated backup with compression
- ✅ Configurable retention policy
- ✅ Comprehensive logging
- ✅ Support for authentication
- ✅ Backup and restore scripts
- ✅ Docker Compose ready

## Quick Start

### 1. Build the Docker image

```bash
docker build -t mongodb-backup .
```

### 2. Run a one-time backup

```bash
docker run --rm \
  -e MONGO_HOST=your-mongodb-host \
  -e MONGO_PORT=27017 \
  -v $(pwd)/backups:/backup \
  -v $(pwd)/logs:/logs \
  mongodb-backup
```

### 3. Using Docker Compose

```bash
# Start the services
docker-compose up -d

# Run a manual backup
docker-compose exec mongodb-backup /scripts/backup-script.sh

# Restore from a backup
docker-compose exec mongodb-backup /scripts/restore-script.sh mongodb_backup_20241007_120000.tar.gz
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MONGO_HOST` | localhost | MongoDB host |
| `MONGO_PORT` | 27017 | MongoDB port |
| `MONGO_DB` | "" | Specific database (empty = all databases) |
| `MONGO_USER` | "" | MongoDB username |
| `MONGO_PASSWORD` | "" | MongoDB password |
| `MONGO_AUTH_DB` | admin | Authentication database |
| `BACKUP_DIR` | /backup | Backup directory |
| `LOG_FILE` | /logs/backup.log | Log file path |
| `RETENTION_DAYS` | 7 | Days to keep backups |
| `DATE_FORMAT` | %Y%m%d_%H%M%S | Timestamp format |
| `CRON_SCHEDULE` | 5 0 * * * | Cron schedule (daily at 00:05) |

### Volumes

- `/backup` - Directory to store backup files
- `/logs` - Directory to store log files

## Usage Examples

### Backup Specific Database

```bash
docker run --rm \
  -e MONGO_HOST=mongodb.example.com \
  -e MONGO_DB=myapp \
  -e MONGO_USER=backup_user \
  -e MONGO_PASSWORD=backup_password \
  -v $(pwd)/backups:/backup \
  -v $(pwd)/logs:/logs \
  mongodb-backup
```

### Backup with Authentication

```bash
docker run --rm \
  -e MONGO_HOST=mongodb.example.com \
  -e MONGO_USER=admin \
  -e MONGO_PASSWORD=secret \
  -e MONGO_AUTH_DB=admin \
  -v $(pwd)/backups:/backup \
  -v $(pwd)/logs:/logs \
  mongodb-backup
```

### Restore from Backup

```bash
# List available backups
docker run --rm \
  -v $(pwd)/backups:/backup \
  -v $(pwd)/logs:/logs \
  mongodb-backup /scripts/restore-script.sh

# Restore specific backup
docker run --rm \
  -e MONGO_HOST=mongodb.example.com \
  -e RESTORE_FILE=mongodb_backup_20241007_120000.tar.gz \
  -v $(pwd)/backups:/backup \
  -v $(pwd)/logs:/logs \
  mongodb-backup /scripts/restore-script.sh
```

### Scheduled Backups with Cron

The container now supports automatic scheduled backups using cron:

```bash
# Default: Run backups daily at 00:05
docker-compose up -d

# Custom schedule: Run every 6 hours
docker run -d \
  -e CRON_SCHEDULE="0 */6 * * *" \
  -e MONGO_HOST=mongodb.example.com \
  -v $(pwd)/backups:/backup \
  -v $(pwd)/logs:/logs \
  mongodb-backup

# Check cron logs
docker-compose logs mongodb-backup
```

### Container Modes

The container supports different operation modes:

```bash
# Scheduled backups (default)
docker run mongodb-backup

# One-time backup
docker run mongodb-backup backup

# Restore from backup
docker run mongodb-backup restore mongodb_backup_20241007_120000.tar.gz

# List available backups
docker run mongodb-backup list

# Interactive shell
docker run -it mongodb-backup bash
```

## Scripts

### backup-script.sh

- Creates compressed backups using `mongodump`
- Supports authentication and specific database selection
- Automatic cleanup of old backups based on retention policy
- Comprehensive logging

### restore-script.sh

- Restores from compressed backup files using `mongorestore`
- Supports selective database restoration
- Option to drop existing collections before restore
- Lists available backups if no file specified

## File Structure

```
.
├── Dockerfile
├── docker-compose.yml
├── backup-script.sh
├── restore-script.sh
├── README.md
├── backups/          # Created when running
└── logs/             # Created when running
```

## Backup File Format

Backups are stored as compressed tar.gz files with the naming convention:
```
mongodb_backup_YYYYMMDD_HHMMSS.tar.gz
```

## Security Considerations

- Use environment files or Docker secrets for passwords
- Ensure backup volumes have appropriate permissions
- Consider encrypting backup files for sensitive data
- Use strong authentication for MongoDB connections

## Troubleshooting

### Check logs
```bash
docker-compose exec mongodb-backup tail -f /logs/backup.log
```

### Test MongoDB connection
```bash
docker-compose exec mongodb-backup mongosh --host $MONGO_HOST:$MONGO_PORT
```

### List backup contents
```bash
tar -tzf backups/mongodb_backup_20241007_120000.tar.gz
```

## License

This project is open source and available under the MIT License.