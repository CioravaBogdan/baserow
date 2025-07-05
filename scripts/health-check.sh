#!/bin/bash

# Health Check Script for Baserow Viral Content Management
# This script performs comprehensive health checks on all services

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TIMEOUT=30

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✓ $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠ WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ✗ ERROR: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] ℹ INFO: $1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check HTTP endpoint
check_http() {
    local url="$1"
    local name="$2"
    local expected_status="${3:-200}"
    
    if command_exists curl; then
        if response=$(curl -s -w "%{http_code}" --max-time $TIMEOUT "$url" -o /dev/null); then
            if [[ "$response" == "$expected_status" ]]; then
                log "$name is responding (HTTP $response)"
                return 0
            else
                error "$name returned HTTP $response (expected $expected_status)"
                return 1
            fi
        else
            error "$name is not accessible"
            return 1
        fi
    else
        warn "curl not available, skipping HTTP check for $name"
        return 1
    fi
}

# Function to check TCP port
check_tcp() {
    local host="$1"
    local port="$2"
    local name="$3"
    
    if command_exists nc; then
        if nc -z -w$TIMEOUT "$host" "$port" 2>/dev/null; then
            log "$name port $port is open"
            return 0
        else
            error "$name port $port is not accessible"
            return 1
        fi
    elif command_exists telnet; then
        if echo "quit" | telnet "$host" "$port" 2>/dev/null | grep -q "Connected"; then
            log "$name port $port is open"
            return 0
        else
            error "$name port $port is not accessible"
            return 1
        fi
    else
        warn "Neither nc nor telnet available, skipping TCP check for $name"
        return 1
    fi
}

# Main health check function
main() {
    info "Starting Baserow Health Check..."
    echo ""
    
    # Change to project directory
    cd "$PROJECT_DIR"
    
    local exit_code=0
    
    # 1. Check Docker and Docker Compose
    info "=== Docker Environment ==="
    if command_exists docker; then
        if docker info >/dev/null 2>&1; then
            log "Docker is running"
            DOCKER_VERSION=$(docker --version)
            log "Docker version: $DOCKER_VERSION"
        else
            error "Docker is not running"
            exit_code=1
        fi
    else
        error "Docker is not installed"
        exit_code=1
    fi
    
    if command_exists docker-compose; then
        COMPOSE_VERSION=$(docker-compose --version)
        log "Docker Compose version: $COMPOSE_VERSION"
    else
        error "Docker Compose is not installed"
        exit_code=1
    fi
    echo ""
    
    # 2. Check Docker Compose services
    info "=== Docker Services Status ==="
    if docker-compose ps --format table; then
        echo ""
        
        # Check individual service health
        local services=("baserow-postgres" "baserow-redis" "baserow-app" "baserow-nginx")
        for service in "${services[@]}"; do
            if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "$service.*Up"; then
                log "$service is running"
            else
                error "$service is not running"
                exit_code=1
            fi
        done
    else
        error "Cannot get Docker Compose status"
        exit_code=1
    fi
    echo ""
    
    # 3. Check network connectivity
    info "=== Network Connectivity ==="
    check_tcp "localhost" "5432" "PostgreSQL" || exit_code=1
    check_tcp "localhost" "6379" "Redis" || exit_code=1
    check_tcp "localhost" "8000" "Baserow HTTP" || exit_code=1
    check_tcp "localhost" "3003" "MCP Server" || exit_code=1
    echo ""
    
    # 4. Check HTTP endpoints
    info "=== HTTP Endpoints ==="
    check_http "http://localhost:8000/api/health/" "Baserow API" || exit_code=1
    check_http "http://localhost:3003/health" "MCP Server" || exit_code=1
    check_http "http://localhost:3000" "Grafana" || exit_code=1
    check_http "http://localhost:3001" "Uptime Kuma" || exit_code=1
    echo ""
    
    # 5. Check database connectivity
    info "=== Database Health ==="
    if docker exec baserow-postgres pg_isready -U baserow -d baserow >/dev/null 2>&1; then
        log "PostgreSQL is accepting connections"
        
        # Check database size and connections
        if DB_INFO=$(docker exec baserow-postgres psql -U baserow -d baserow -t -c "SELECT pg_size_pretty(pg_database_size('baserow')), COUNT(*) FROM pg_stat_activity WHERE state = 'active';" 2>/dev/null); then
            DB_SIZE=$(echo "$DB_INFO" | awk '{print $1}')
            ACTIVE_CONN=$(echo "$DB_INFO" | awk '{print $3}')
            log "Database size: $DB_SIZE, Active connections: $ACTIVE_CONN"
        fi
    else
        error "PostgreSQL is not accepting connections"
        exit_code=1
    fi
    
    # Check Redis connectivity
    if docker exec baserow-redis redis-cli ping >/dev/null 2>&1; then
        log "Redis is responding to ping"
        
        # Check Redis memory usage
        if REDIS_INFO=$(docker exec baserow-redis redis-cli info memory | grep "used_memory_human" | cut -d: -f2 | tr -d '\r'); then
            log "Redis memory usage: $REDIS_INFO"
        fi
    else
        error "Redis is not responding"
        exit_code=1
    fi
    echo ""
    
    # 6. Check disk space
    info "=== System Resources ==="
    if command_exists df; then
        DISK_USAGE=$(df -h . | tail -1 | awk '{print $5}' | sed 's/%//')
        if [[ $DISK_USAGE -lt 90 ]]; then
            log "Disk usage: ${DISK_USAGE}% (healthy)"
        elif [[ $DISK_USAGE -lt 95 ]]; then
            warn "Disk usage: ${DISK_USAGE}% (warning)"
        else
            error "Disk usage: ${DISK_USAGE}% (critical)"
            exit_code=1
        fi
    fi
    
    # Check Docker system resources
    if docker system df >/dev/null 2>&1; then
        DOCKER_IMAGES_SIZE=$(docker system df | grep "Images" | awk '{print $3}')
        DOCKER_CONTAINERS_SIZE=$(docker system df | grep "Containers" | awk '{print $3}')
        log "Docker images size: $DOCKER_IMAGES_SIZE"
        log "Docker containers size: $DOCKER_CONTAINERS_SIZE"
    fi
    echo ""
    
    # 7. Check configuration files
    info "=== Configuration ==="
    if [[ -f ".env" ]]; then
        log ".env file exists"
        
        # Check required variables
        local required_vars=("DATABASE_PASSWORD" "SECRET_KEY" "DOMAIN_NAME")
        for var in "${required_vars[@]}"; do
            if grep -q "^${var}=" .env; then
                log "$var is configured"
            else
                error "$var is missing from .env"
                exit_code=1
            fi
        done
    else
        error ".env file is missing"
        exit_code=1
    fi
    
    if [[ -f "docker-compose.yml" ]]; then
        log "docker-compose.yml exists"
    else
        error "docker-compose.yml is missing"
        exit_code=1
    fi
    echo ""
    
    # 8. Check SSL certificates (if using HTTPS)
    info "=== SSL Certificates ==="
    if [[ -f "nginx/ssl/cert.pem" && -f "nginx/ssl/key.pem" ]]; then
        log "SSL certificate files found"
        
        # Check certificate expiry
        if command_exists openssl; then
            CERT_EXPIRY=$(openssl x509 -in nginx/ssl/cert.pem -noout -enddate 2>/dev/null | cut -d= -f2)
            if [[ -n "$CERT_EXPIRY" ]]; then
                log "Certificate expires: $CERT_EXPIRY"
                
                # Check if certificate expires in next 30 days
                if openssl x509 -in nginx/ssl/cert.pem -noout -checkend 2592000 >/dev/null 2>&1; then
                    log "Certificate is valid for next 30 days"
                else
                    warn "Certificate expires within 30 days!"
                fi
            fi
        fi
    else
        warn "SSL certificate files not found (OK for development)"
    fi
    echo ""
    
    # 9. Check backup system
    info "=== Backup System ==="
    if [[ -f "scripts/backup.sh" ]]; then
        log "Backup script exists"
        
        # Check if backups directory exists and has recent backups
        if [[ -d "backups" ]]; then
            BACKUP_COUNT=$(find backups -name "baserow_backup_*.tar.gz" -mtime -7 | wc -l)
            if [[ $BACKUP_COUNT -gt 0 ]]; then
                log "Found $BACKUP_COUNT recent backups (last 7 days)"
            else
                warn "No recent backups found"
            fi
        else
            warn "Backups directory not found"
        fi
    else
        error "Backup script is missing"
        exit_code=1
    fi
    echo ""
    
    # 10. Final summary
    info "=== Health Check Summary ==="
    if [[ $exit_code -eq 0 ]]; then
        log "All health checks passed! 🎉"
        log "System is healthy and ready for use."
    else
        error "Some health checks failed!"
        error "Please review the errors above and take corrective action."
    fi
    
    echo ""
    info "Health check completed at $(date)"
    
    # Return appropriate exit code
    exit $exit_code
}

# Run main function
main "$@"
