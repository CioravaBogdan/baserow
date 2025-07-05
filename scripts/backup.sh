#!/bin/bash

# Automated Backup Script for Baserow Viral Content Management
# This script performs comprehensive backups of database, files, and configuration

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$PROJECT_DIR/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="baserow_backup_$DATE"

# Load environment variables
if [ -f "$PROJECT_DIR/.env" ]; then
    source "$PROJECT_DIR/.env"
else
    echo "Error: .env file not found!"
    exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

# Check if running in test mode
TEST_MODE=false
if [[ "${1:-}" == "--test" ]]; then
    TEST_MODE=true
    log "Running in TEST mode"
fi

# Create backup directory structure
mkdir -p "$BACKUP_DIR/$BACKUP_NAME"/{database,media,config,logs}

log "Starting backup process: $BACKUP_NAME"

# 1. Database backup
log "Backing up PostgreSQL database..."
if docker exec baserow-postgres pg_dump -U baserow -d baserow -f "/backups/$BACKUP_NAME/database/baserow_db.sql"; then
    log "Database backup completed successfully"
else
    error "Database backup failed!"
    exit 1
fi

# Compress database backup
gzip "$BACKUP_DIR/$BACKUP_NAME/database/baserow_db.sql"
log "Database backup compressed"

# 2. Media files backup
log "Backing up media files..."
if docker run --rm \
    -v baserow_baserow_media:/source:ro \
    -v "$BACKUP_DIR/$BACKUP_NAME/media":/destination \
    alpine:latest \
    sh -c "cp -r /source/* /destination/ 2>/dev/null || true"; then
    log "Media files backup completed"
else
    warn "Media files backup had issues (may be empty)"
fi

# 3. Configuration backup
log "Backing up configuration files..."
cp "$PROJECT_DIR/docker-compose.yml" "$BACKUP_DIR/$BACKUP_NAME/config/"
cp "$PROJECT_DIR/.env" "$BACKUP_DIR/$BACKUP_NAME/config/" 2>/dev/null || warn ".env file not found"
cp -r "$PROJECT_DIR/nginx" "$BACKUP_DIR/$BACKUP_NAME/config/" 2>/dev/null || warn "nginx config not found"
cp -r "$PROJECT_DIR/mcp-config" "$BACKUP_DIR/$BACKUP_NAME/config/" 2>/dev/null || warn "mcp-config not found"

# 4. Export Baserow application data via API
log "Exporting Baserow application data..."
if command -v curl &> /dev/null; then
    # Get auth token (this would need to be set up after initial installation)
    if [[ -n "${N8N_API_TOKEN:-}" ]]; then
        curl -H "Authorization: Token $N8N_API_TOKEN" \
             "http://localhost:8000/api/applications/export/" \
             -o "$BACKUP_DIR/$BACKUP_NAME/config/baserow_export.json" || warn "API export failed"
    else
        warn "N8N_API_TOKEN not set, skipping API export"
    fi
else
    warn "curl not available, skipping API export"
fi

# 5. Save container logs
log "Saving container logs..."
docker-compose -f "$PROJECT_DIR/docker-compose.yml" logs --no-color > "$BACKUP_DIR/$BACKUP_NAME/logs/docker_logs.txt" 2>/dev/null || warn "Failed to save logs"

# 6. Create backup metadata
cat > "$BACKUP_DIR/$BACKUP_NAME/backup_metadata.json" << EOF
{
    "backup_name": "$BACKUP_NAME",
    "backup_date": "$(date -Iseconds)",
    "baserow_version": "$(docker exec baserow-app cat /baserow/VERSION 2>/dev/null || echo 'unknown')",
    "database_size": "$(du -sh $BACKUP_DIR/$BACKUP_NAME/database/ | cut -f1)",
    "media_size": "$(du -sh $BACKUP_DIR/$BACKUP_NAME/media/ | cut -f1)",
    "total_size": "$(du -sh $BACKUP_DIR/$BACKUP_NAME/ | cut -f1)",
    "hostname": "$(hostname)",
    "backup_type": "$([ "$TEST_MODE" = true ] && echo 'test' || echo 'full')"
}
EOF

# 7. Create compressed archive
log "Creating compressed archive..."
cd "$BACKUP_DIR"
tar -czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME/"

if [[ "$TEST_MODE" == "false" ]]; then
    # Remove uncompressed directory
    rm -rf "$BACKUP_NAME/"
    
    # 8. Upload to cloud storage (if configured)
    if [[ -n "${BACKUP_CLOUD_PROVIDER:-}" && -n "${BACKUP_BUCKET_NAME:-}" ]]; then
        log "Uploading backup to cloud storage..."
        case "$BACKUP_CLOUD_PROVIDER" in
            "aws_s3")
                if command -v aws &> /dev/null; then
                    aws s3 cp "${BACKUP_NAME}.tar.gz" "s3://$BACKUP_BUCKET_NAME/baserow-backups/" || warn "Cloud upload failed"
                else
                    warn "AWS CLI not installed, skipping cloud upload"
                fi
                ;;
            "cloudflare_r2")
                if command -v rclone &> /dev/null; then
                    rclone copy "${BACKUP_NAME}.tar.gz" "cloudflare:$BACKUP_BUCKET_NAME/baserow-backups/" || warn "Cloud upload failed"
                else
                    warn "rclone not installed, skipping cloud upload"
                fi
                ;;
            *)
                warn "Unknown cloud provider: $BACKUP_CLOUD_PROVIDER"
                ;;
        esac
    fi
    
    # 9. Cleanup old backups (keep last 30 days locally)
    log "Cleaning up old backups..."
    find "$BACKUP_DIR" -name "baserow_backup_*.tar.gz" -type f -mtime +30 -delete || warn "Cleanup failed"
fi

# 10. Verify backup integrity
log "Verifying backup integrity..."
if tar -tzf "${BACKUP_NAME}.tar.gz" > /dev/null 2>&1; then
    log "Backup integrity check passed"
else
    error "Backup integrity check failed!"
    exit 1
fi

# Calculate and display backup size
BACKUP_SIZE=$(du -sh "${BACKUP_NAME}.tar.gz" | cut -f1)
log "Backup completed successfully!"
log "Backup location: $BACKUP_DIR/${BACKUP_NAME}.tar.gz"
log "Backup size: $BACKUP_SIZE"

# Send notification (if configured)
if [[ -n "${WEBHOOK_URL:-}" ]]; then
    curl -X POST "$WEBHOOK_URL" \
         -H "Content-Type: application/json" \
         -d "{\"text\":\"Baserow backup completed: $BACKUP_NAME ($BACKUP_SIZE)\"}" \
         2>/dev/null || warn "Notification failed"
fi

log "Backup process completed successfully!"
exit 0
