# PowerShell aliases and helper functions for Baserow management
# Add these to your PowerShell profile for quick access

# Navigation aliases
function baserow { Set-Location "D:\Projects\Baserow" }
function br { Set-Location "D:\Projects\Baserow" }

# Docker Compose shortcuts
function bup { docker-compose up -d }
function bdown { docker-compose down }
function brestart { docker-compose restart }
function bstatus { docker-compose ps }
function blogs { docker-compose logs -f --tail=50 }
function bpull { docker-compose pull }

# Service-specific shortcuts
function blog-baserow { docker-compose logs -f baserow }
function blog-postgres { docker-compose logs -f postgres }
function blog-redis { docker-compose logs -f redis }
function blog-nginx { docker-compose logs -f nginx }

# Health check shortcuts
function bhealth { 
    wsl ./scripts/health-check.sh 
}

function bquick {
    Write-Host "Quick Status Check:" -ForegroundColor Yellow
    docker-compose ps
    Write-Host "`nAPI Health:" -ForegroundColor Yellow
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8000/api/health/" -TimeoutSec 5
        Write-Host "✓ Baserow API: OK" -ForegroundColor Green
    } catch {
        Write-Host "✗ Baserow API: FAILED" -ForegroundColor Red
    }
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3003/health" -TimeoutSec 5
        Write-Host "✓ MCP Server: OK" -ForegroundColor Green
    } catch {
        Write-Host "✗ MCP Server: FAILED" -ForegroundColor Red
    }
}

# Backup shortcuts
function bbackup { wsl ./scripts/backup.sh }
function bbackup-test { wsl ./scripts/backup.sh --test }
function brestore-list { wsl ./scripts/restore.sh --list }
function brestore-latest { wsl ./scripts/restore.sh --latest }

# Database shortcuts
function bdb {
    docker exec -it baserow-postgres psql -U baserow -d baserow
}

function bdb-size {
    docker exec baserow-postgres psql -U baserow -d baserow -c "SELECT pg_size_pretty(pg_database_size('baserow')) as database_size;"
}

function bdb-backup {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    docker exec baserow-postgres pg_dump -U baserow baserow > "manual_backup_$timestamp.sql"
    Write-Host "Database backed up to manual_backup_$timestamp.sql" -ForegroundColor Green
}

# Redis shortcuts
function bredis {
    docker exec -it baserow-redis redis-cli
}

function bredis-info {
    docker exec baserow-redis redis-cli info memory | Select-String "used_memory_human"
}

# Monitoring shortcuts
function bgrafana {
    Start-Process "http://localhost:3000"
}

function buptime {
    Start-Process "http://localhost:3001"
}

function bprometheus {
    Start-Process "http://localhost:9090"
}

# API testing shortcuts
function bapi-test {
    Write-Host "Testing API endpoints..." -ForegroundColor Yellow
    
    try {
        $health = Invoke-RestMethod -Uri "http://localhost:8000/api/health/"
        Write-Host "✓ Health endpoint: $($health.status)" -ForegroundColor Green
    } catch {
        Write-Host "✗ Health endpoint failed" -ForegroundColor Red
    }
}

function bmcp-test {
    Write-Host "Testing MCP endpoint..." -ForegroundColor Yellow
    
    try {
        $health = Invoke-RestMethod -Uri "http://localhost:3003/health"
        Write-Host "✓ MCP endpoint: OK" -ForegroundColor Green
    } catch {
        Write-Host "✗ MCP endpoint failed" -ForegroundColor Red
    }
}

# System resource checks
function bresources {
    Write-Host "Docker Resource Usage:" -ForegroundColor Yellow
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
    
    Write-Host "`nDisk Usage:" -ForegroundColor Yellow
    Get-PSDrive C | Select-Object Name, @{Name="Used(GB)";Expression={[math]::Round($_.Used/1GB,2)}}, @{Name="Free(GB)";Expression={[math]::Round($_.Free/1GB,2)}}, @{Name="UsedPercent";Expression={[math]::Round(($_.Used/($_.Used+$_.Free))*100,2)}}
}

# Update and maintenance shortcuts
function bupdate {
    Write-Host "Updating Baserow system..." -ForegroundColor Yellow
    
    # Backup first
    Write-Host "Creating backup..." -ForegroundColor Blue
    wsl ./scripts/backup.sh
    
    # Pull latest images
    Write-Host "Pulling latest images..." -ForegroundColor Blue
    docker-compose pull
    
    # Restart services
    Write-Host "Restarting services..." -ForegroundColor Blue
    docker-compose down
    docker-compose up -d
    
    # Wait and check health
    Write-Host "Waiting for services to start..." -ForegroundColor Blue
    Start-Sleep 30
    bhealth
}

function bcleanup {
    Write-Host "Cleaning up Docker resources..." -ForegroundColor Yellow
    
    # Remove unused images
    docker image prune -f
    
    # Remove unused volumes (be careful!)
    Read-Host "This will remove unused Docker volumes. Press Enter to continue or Ctrl+C to cancel"
    docker volume prune -f
    
    # Remove unused networks
    docker network prune -f
    
    Write-Host "Cleanup completed!" -ForegroundColor Green
}

# Security shortcuts
function bsecurity-check {
    Write-Host "Security Check:" -ForegroundColor Yellow
    
    # Check for default passwords
    Write-Host "`nChecking for default passwords..." -ForegroundColor Blue
    if (Select-String -Path ".env" -Pattern "password_here|secret_key_here|token_here" -Quiet) {
        Write-Host "⚠ Default passwords/tokens found in .env file!" -ForegroundColor Red
    } else {
        Write-Host "✓ No default passwords found" -ForegroundColor Green
    }
    
    # Check SSL certificate
    Write-Host "`nChecking SSL certificate..." -ForegroundColor Blue
    if (Test-Path "nginx\ssl\cert.pem") {
        Write-Host "✓ SSL certificate exists" -ForegroundColor Green
    } else {
        Write-Host "⚠ SSL certificate not found" -ForegroundColor Yellow
    }
    
    # Check firewall status
    Write-Host "`nChecking firewall..." -ForegroundColor Blue
    $firewall = Get-NetFirewallProfile | Select-Object Name, Enabled
    $firewall | ForEach-Object {
        if ($_.Enabled) {
            Write-Host "✓ $($_.Name) firewall: Enabled" -ForegroundColor Green
        } else {
            Write-Host "⚠ $($_.Name) firewall: Disabled" -ForegroundColor Yellow
        }
    }
}

# Development helpers
function bdev-setup {
    Write-Host "Setting up development environment..." -ForegroundColor Yellow
    
    # Copy environment template
    if (!(Test-Path ".env")) {
        Copy-Item ".env.example" ".env"
        Write-Host "✓ Created .env file from template" -ForegroundColor Green
        Write-Host "Please edit .env file with your configuration" -ForegroundColor Blue
    }
    
    # Generate self-signed SSL certificate
    if (!(Test-Path "nginx\ssl\cert.pem")) {
        Write-Host "Generating self-signed SSL certificate..." -ForegroundColor Blue
        New-Item -ItemType Directory -Force -Path "nginx\ssl"
        & openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout nginx\ssl\key.pem -out nginx\ssl\cert.pem -subj "/C=RO/ST=Bucharest/L=Bucharest/O=InfantViral/CN=baserow.infant-viral.com"
        Write-Host "✓ SSL certificate generated" -ForegroundColor Green
    }
    
    Write-Host "Development setup completed!" -ForegroundColor Green
    Write-Host "Next steps:" -ForegroundColor Blue
    Write-Host "1. Edit .env file with your configuration" -ForegroundColor White
    Write-Host "2. Run 'bup' to start services" -ForegroundColor White
    Write-Host "3. Run 'bhealth' to check status" -ForegroundColor White
}

# Help function
function bhelp {
    Write-Host "Baserow Management Commands:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Navigation:" -ForegroundColor Blue
    Write-Host "  baserow, br         - Navigate to Baserow directory"
    Write-Host ""
    Write-Host "Service Management:" -ForegroundColor Blue
    Write-Host "  bup                 - Start all services"
    Write-Host "  bdown               - Stop all services"
    Write-Host "  brestart            - Restart all services"
    Write-Host "  bstatus             - Show service status"
    Write-Host "  blogs               - Show recent logs from all services"
    Write-Host "  bpull               - Pull latest Docker images"
    Write-Host ""
    Write-Host "Health & Monitoring:" -ForegroundColor Blue
    Write-Host "  bhealth             - Run comprehensive health check"
    Write-Host "  bquick              - Quick status check"
    Write-Host "  bresources          - Show resource usage"
    Write-Host "  bgrafana            - Open Grafana dashboard"
    Write-Host "  buptime             - Open Uptime Kuma"
    Write-Host "  bprometheus         - Open Prometheus"
    Write-Host ""
    Write-Host "Database:" -ForegroundColor Blue
    Write-Host "  bdb                 - Connect to PostgreSQL"
    Write-Host "  bdb-size            - Show database size"
    Write-Host "  bdb-backup          - Manual database backup"
    Write-Host "  bredis              - Connect to Redis"
    Write-Host "  bredis-info         - Show Redis memory usage"
    Write-Host ""
    Write-Host "Backup & Restore:" -ForegroundColor Blue
    Write-Host "  bbackup             - Create full backup"
    Write-Host "  bbackup-test        - Test backup system"
    Write-Host "  brestore-list       - List available backups"
    Write-Host "  brestore-latest     - Restore from latest backup"
    Write-Host ""
    Write-Host "API Testing:" -ForegroundColor Blue
    Write-Host "  bapi-test           - Test Baserow API"
    Write-Host "  bmcp-test           - Test MCP endpoint"
    Write-Host ""
    Write-Host "Maintenance:" -ForegroundColor Blue
    Write-Host "  bupdate             - Update system (backup + pull + restart)"
    Write-Host "  bcleanup            - Clean up Docker resources"
    Write-Host "  bsecurity-check     - Security configuration check"
    Write-Host ""
    Write-Host "Development:" -ForegroundColor Blue
    Write-Host "  bdev-setup          - Setup development environment"
    Write-Host ""
    Write-Host "Logs (specific services):" -ForegroundColor Blue
    Write-Host "  blog-baserow        - Baserow application logs"
    Write-Host "  blog-postgres       - PostgreSQL logs"
    Write-Host "  blog-redis          - Redis logs"
    Write-Host "  blog-nginx          - Nginx logs"
    Write-Host ""
}

# Display welcome message
Write-Host "Baserow management commands loaded! Type 'bhelp' for available commands." -ForegroundColor Green
