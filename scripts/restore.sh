#!/bin/bash

# Restore Script for Baserow Viral Content Management
# This script restores Baserow from a backup created by backup.sh

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$PROJECT_DIR/backups"

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

# Function to display usage
usage() {
    echo "Usage: $0 <backup_file.tar.gz>"
    echo "       $0 --list    (to list available backups)"
    echo "       $0 --latest  (to restore from latest backup)"
    echo ""
    echo "Example: $0 baserow_backup_20231215_143022.tar.gz"
    exit 1
}

# Function to list available backups
list_backups() {
    log "Available backups in $BACKUP_DIR:"
    find "$BACKUP_DIR" -name "baserow_backup_*.tar.gz" -type f -printf "%f\t%TY-%Tm-%Td %TH:%TM\t%s bytes\n" | sort -r
    exit 0
}

# Function to get latest backup
get_latest_backup() {
    LATEST=$(find "$BACKUP_DIR" -name "baserow_backup_*.tar.gz" -type f -printf "%T@ %f\n" | sort -nr | head -1 | cut -d' ' -f2-)
    if [[ -n "$LATEST" ]]; then
        echo "$LATEST"
    else
        error "No backups found!"
        exit 1
    fi
}

# Parse arguments
if [[ $# -eq 0 ]]; then
    usage
fi

case "${1:-}" in
    "--list")
        list_backups
        ;;
    "--latest")
        BACKUP_FILE=$(get_latest_backup)
        ;;
    "--help"|"-h")
        usage
        ;;
    *)
        BACKUP_FILE="$1"
        ;;
esac

# Check if backup file exists
BACKUP_PATH="$BACKUP_DIR/$BACKUP_FILE"
if [[ ! -f "$BACKUP_PATH" ]]; then
    error "Backup file not found: $BACKUP_PATH"
    exit 1
fi

log "Starting restore process from: $BACKUP_FILE"

# Confirm with user
read -p "This will REPLACE all current data. Are you sure? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    log "Restore cancelled by user"
    exit 0
fi

# Load environment variables
if [ -f "$PROJECT_DIR/.env" ]; then
    source "$PROJECT_DIR/.env"
else
    error ".env file not found!"
    exit 1
fi

# Stop all services
log "Stopping all services..."
cd "$PROJECT_DIR"
docker-compose down

# Extract backup
RESTORE_DIR="/tmp/baserow_restore_$(date +%s)"
mkdir -p "$RESTORE_DIR"
log "Extracting backup to $RESTORE_DIR..."
tar -xzf "$BACKUP_PATH" -C "$RESTORE_DIR"

# Get the backup directory name
BACKUP_NAME=$(basename "$BACKUP_FILE" .tar.gz)
EXTRACTED_DIR="$RESTORE_DIR/$BACKUP_NAME"

if [[ ! -d "$EXTRACTED_DIR" ]]; then
    error "Extracted backup directory not found!"
    exit 1
fi

# Verify backup integrity
log "Verifying backup integrity..."
if [[ ! -f "$EXTRACTED_DIR/backup_metadata.json" ]]; then
    error "Backup metadata not found! This may not be a valid backup."
    exit 1
fi

# Display backup information
log "Backup information:"
cat "$EXTRACTED_DIR/backup_metadata.json" | jq . 2>/dev/null || cat "$EXTRACTED_DIR/backup_metadata.json"

# Restore configuration files
log "Restoring configuration files..."
if [[ -f "$EXTRACTED_DIR/config/docker-compose.yml" ]]; then
    cp "$EXTRACTED_DIR/config/docker-compose.yml" "$PROJECT_DIR/"
    log "docker-compose.yml restored"
fi

if [[ -f "$EXTRACTED_DIR/config/.env" ]]; then
    cp "$EXTRACTED_DIR/config/.env" "$PROJECT_DIR/"
    log ".env restored"
fi

if [[ -d "$EXTRACTED_DIR/config/nginx" ]]; then
    cp -r "$EXTRACTED_DIR/config/nginx" "$PROJECT_DIR/"
    log "nginx configuration restored"
fi

if [[ -d "$EXTRACTED_DIR/config/mcp-config" ]]; then
    cp -r "$EXTRACTED_DIR/config/mcp-config" "$PROJECT_DIR/"
    log "mcp-config restored"
fi

# Start PostgreSQL first
log "Starting PostgreSQL..."
docker-compose up -d postgres
sleep 10

# Wait for PostgreSQL to be ready
log "Waiting for PostgreSQL to be ready..."
until docker exec baserow-postgres pg_isready -U baserow -d baserow; do
    sleep 2
done

# Restore database
log "Restoring database..."
if [[ -f "$EXTRACTED_DIR/database/baserow_db.sql.gz" ]]; then
    # Drop existing database and recreate
    docker exec baserow-postgres psql -U baserow -c "DROP DATABASE IF EXISTS baserow;"
    docker exec baserow-postgres psql -U baserow -c "CREATE DATABASE baserow;"
    
    # Restore from backup
    gunzip -c "$EXTRACTED_DIR/database/baserow_db.sql.gz" | docker exec -i baserow-postgres psql -U baserow -d baserow
    log "Database restored successfully"
else
    error "Database backup file not found!"
    exit 1
fi

# Start Redis
log "Starting Redis..."
docker-compose up -d redis
sleep 5

# Restore media files
log "Restoring media files..."
if [[ -d "$EXTRACTED_DIR/media" ]]; then
    # Remove existing media volume and recreate
    docker volume rm baserow_baserow_media 2>/dev/null || true
    docker volume create baserow_baserow_media
    
    # Copy media files back
    docker run --rm \
        -v "$EXTRACTED_DIR/media":/source:ro \
        -v baserow_baserow_media:/destination \
        alpine:latest \
        sh -c "cp -r /source/* /destination/ 2>/dev/null || true"
    log "Media files restored"
else
    warn "No media files found in backup"
fi

# Start all services
log "Starting all services..."
docker-compose up -d

# Wait for services to be ready
log "Waiting for services to start..."
sleep 30

# Verify services are running
log "Verifying services..."
if docker-compose ps | grep -q "Up"; then
    log "Services are running"
else
    error "Some services failed to start!"
    docker-compose ps
fi

# Test database connection
if docker exec baserow-postgres pg_isready -U baserow -d baserow; then
    log "Database connection test passed"
else
    error "Database connection test failed!"
fi

# Test Baserow API
if curl -f http://localhost:8000/api/health/ > /dev/null 2>&1; then
    log "Baserow API test passed"
else
    warn "Baserow API test failed (may still be starting up)"
fi

# Cleanup temporary files
log "Cleaning up temporary files..."
rm -rf "$RESTORE_DIR"

log "Restore completed successfully!"
log "Services should be available at:"
log "  - Baserow UI: http://localhost:8000"
log "  - Database: localhost:5432"
log "  - Redis: localhost:6379"
log ""
log "Check service status with: docker-compose ps"
log "Check logs with: docker-compose logs -f"

exit 0
