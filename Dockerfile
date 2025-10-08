# MongoDB Backup Docker Image
# Based on Debian with MongoDB Command Line Database Tools

FROM debian:bookworm-slim

# Build arguments
ARG TIMEZONE=Asia/Bangkok

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV MONGODB_TOOLS_VERSION=100.13.0
ENV TZ=$TIMEZONE

# Install required packages
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    iputils-ping \
    ca-certificates \
    cron \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Set timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Verify timezone installation
RUN echo "Timezone set to: $(cat /etc/timezone)" && \
    echo "Current time: $(date)" && \
    echo "Timezone verification complete"

# Download and install MongoDB Command Line Database Tools
RUN wget -O /tmp/mongodb-database-tools.tgz https://fastdl.mongodb.org/tools/db/mongodb-database-tools-debian11-x86_64-100.13.0.tgz \
    && tar -xzf /tmp/mongodb-database-tools.tgz -C /tmp \
    && cp /tmp/mongodb-database-tools-debian11-x86_64-100.13.0/bin/* /usr/local/bin/ \
    && rm -rf /tmp/mongodb-database-tools* \
    && chmod +x /usr/local/bin/mongodump /usr/local/bin/mongorestore /usr/local/bin/mongoexport /usr/local/bin/mongoimport

# Create backup directory and scripts directory
RUN mkdir -p /backup /scripts /logs /cert

# Copy MongoDB CA certificate
COPY cert/mongodb-ca-certificate.crt /cert/mongodb-ca-certificate.crt

# Create backup script
COPY backup-script.sh /scripts/backup-script.sh
RUN chmod +x /scripts/backup-script.sh

# Create restore script
COPY restore-script.sh /scripts/restore-script.sh
RUN chmod +x /scripts/restore-script.sh

# Create cron setup script
COPY setup-cron.sh /scripts/setup-cron.sh
RUN chmod +x /scripts/setup-cron.sh

# Create entrypoint script
COPY entrypoint.sh /scripts/entrypoint.sh
RUN chmod +x /scripts/entrypoint.sh

# Set working directory
WORKDIR /backup

# Expose volume for backups
VOLUME ["/backup", "/logs"]

# Set entrypoint
ENTRYPOINT ["/scripts/entrypoint.sh"]

# Default command (can be overridden)
CMD ["cron"]