# MongoDB Backup Docker Image
# Based on Debian with MongoDB Command Line Database Tools

FROM debian:bookworm-slim

# Build arguments
ARG TIMEZONE=Asia/Bangkok

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV MONGODB_TOOLS_VERSION=100.9.4
ENV TZ=$TIMEZONE

# Install required packages
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    gnupg \
    lsb-release \
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
RUN wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | apt-key add - \
    && echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/debian bookworm/mongodb-org/7.0 main" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list \
    && apt-get update \
    && apt-get install -y mongodb-database-tools \
    && rm -rf /var/lib/apt/lists/*

# Create backup directory and scripts directory
RUN mkdir -p /backup /scripts /logs

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