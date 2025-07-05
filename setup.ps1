#!/usr/bin/env powershell

# Baserow Viral Content Management - Windows Setup Script
# This script automates the initial setup process

param(
    [switch]$SkipSSL,
    [switch]$Development,
    [string]$Domain = "baserow.infant-viral.com"
)

$ErrorActionPreference = "Stop"

# Colors for output
function Write-Success { param($Message) Write-Host "✓ $Message" -ForegroundColor Green }
function Write-Error { param($Message) Write-Host "✗ $Message" -ForegroundColor Red }
function Write-Warning { param($Message) Write-Host "⚠ $Message" -ForegroundColor Yellow }
function Write-Info { param($Message) Write-Host "ℹ $Message" -ForegroundColor Blue }

function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    # Check Docker
    try {
        $dockerVersion = docker --version
        Write-Success "Docker found: $dockerVersion"
    } catch {
        Write-Error "Docker is not installed or not in PATH"
        Write-Info "Please install Docker Desktop from https://www.docker.com/products/docker-desktop/"
        exit 1
    }
    
    # Check Docker Compose
    try {
        $composeVersion = docker-compose --version
        Write-Success "Docker Compose found: $composeVersion"
    } catch {
        Write-Error "Docker Compose is not available"
        exit 1
    }
    
    # Check if Docker is running
    try {
        docker info | Out-Null
        Write-Success "Docker daemon is running"
    } catch {
        Write-Error "Docker daemon is not running. Please start Docker Desktop."
        exit 1
    }
    
    # Check available disk space (minimum 10GB)
    $drive = Get-PSDrive -Name (Split-Path -Qualifier $PWD)
    $freeSpaceGB = [math]::Round($drive.Free / 1GB, 2)
    if ($freeSpaceGB -lt 10) {
        Write-Warning "Low disk space: ${freeSpaceGB}GB free. Minimum 10GB recommended."
    } else {
        Write-Success "Disk space: ${freeSpaceGB}GB free"
    }
}

function Initialize-Environment {
    Write-Info "Setting up environment..."
    
    # Copy .env template if it doesn't exist
    if (!(Test-Path ".env")) {
        Copy-Item ".env.example" ".env"
        Write-Success "Created .env file from template"
        
        # Generate secure passwords
        $databasePassword = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})
        $secretKey = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 64 | ForEach-Object {[char]$_})
        $adminPassword = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 20 | ForEach-Object {[char]$_})
        $grafanaPassword = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 16 | ForEach-Object {[char]$_})
        
        # Update .env file
        (Get-Content ".env") -replace "your_secure_database_password_here", $databasePassword | Set-Content ".env"
        (Get-Content ".env") -replace "your_very_long_secret_key_minimum_50_characters_random_string", $secretKey | Set-Content ".env"
        (Get-Content ".env") -replace "very_secure_admin_password_here", $adminPassword | Set-Content ".env"
        (Get-Content ".env") -replace "secure_grafana_admin_password", $grafanaPassword | Set-Content ".env"
        (Get-Content ".env") -replace "baserow.infant-viral.com", $Domain | Set-Content ".env"
        
        Write-Success "Generated secure passwords and updated configuration"
        Write-Warning "IMPORTANT: Save these credentials securely!"
        Write-Host "Database Password: $databasePassword" -ForegroundColor Cyan
        Write-Host "Admin Password: $adminPassword" -ForegroundColor Cyan
        Write-Host "Grafana Password: $grafanaPassword" -ForegroundColor Cyan
        
        # Save credentials to file
        @"
Baserow Setup Credentials - $(Get-Date)
=====================================

Domain: $Domain
Admin Username: admin
Admin Password: $adminPassword
Grafana Password: $grafanaPassword
Database Password: $databasePassword

KEEP THIS FILE SECURE AND DELETE AFTER SAVING TO PASSWORD MANAGER!
"@ | Out-File -FilePath "CREDENTIALS.txt" -Encoding UTF8
        
        Write-Info "Credentials saved to CREDENTIALS.txt - please save securely and delete this file!"
    } else {
        Write-Info ".env file already exists, skipping generation"
    }
}

function Setup-SSL {
    if ($SkipSSL) {
        Write-Info "Skipping SSL setup as requested"
        return
    }
    
    Write-Info "Setting up SSL certificates..."
    
    # Create SSL directory
    New-Item -ItemType Directory -Force -Path "nginx\ssl" | Out-Null
    
    if (!(Test-Path "nginx\ssl\cert.pem") -or !(Test-Path "nginx\ssl\key.pem")) {
        try {
            # Generate self-signed certificate
            $opensslCmd = "openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout nginx\ssl\key.pem -out nginx\ssl\cert.pem -subj `"/C=RO/ST=Bucharest/L=Bucharest/O=InfantViral/CN=$Domain`""
            Invoke-Expression $opensslCmd
            Write-Success "Generated self-signed SSL certificate"
            
            if ($Development) {
                Write-Info "Development mode: Self-signed certificate is sufficient"
            } else {
                Write-Warning "For production, replace with proper SSL certificate from Cloudflare or Let's Encrypt"
            }
        } catch {
            Write-Warning "Could not generate SSL certificate. OpenSSL may not be installed."
            Write-Info "You can generate certificates later or use Cloudflare origin certificates"
        }
    } else {
        Write-Success "SSL certificates already exist"
    }
}

function Start-Services {
    Write-Info "Starting services..."
    
    # Start core services first
    Write-Info "Starting database and cache services..."
    docker-compose up -d postgres redis
    
    # Wait for database to be ready
    Write-Info "Waiting for database to initialize..."
    $timeout = 60
    $elapsed = 0
    
    do {
        Start-Sleep 5
        $elapsed += 5
        try {
            docker exec baserow-postgres pg_isready -U baserow -d baserow | Out-Null
            $dbReady = $true
            break
        } catch {
            $dbReady = $false
        }
        
        if ($elapsed -ge $timeout) {
            Write-Error "Database failed to start within $timeout seconds"
            docker-compose logs postgres
            exit 1
        }
    } while (-not $dbReady)
    
    Write-Success "Database is ready"
    
    # Start Baserow application
    Write-Info "Starting Baserow application..."
    docker-compose up -d baserow
    
    # Wait for Baserow to be ready
    Write-Info "Waiting for Baserow to initialize (this may take several minutes)..."
    $timeout = 300  # 5 minutes
    $elapsed = 0
    
    do {
        Start-Sleep 10
        $elapsed += 10
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8000/api/health/" -TimeoutSec 5
            $baserowReady = $response.StatusCode -eq 200
            break
        } catch {
            $baserowReady = $false
        }
        
        if ($elapsed -ge $timeout) {
            Write-Error "Baserow failed to start within $timeout seconds"
            docker-compose logs baserow
            exit 1
        }
        
        Write-Info "Still waiting... ($elapsed/$timeout seconds)"
    } while (-not $baserowReady)
    
    Write-Success "Baserow is ready"
    
    # Start remaining services
    Write-Info "Starting remaining services..."
    docker-compose up -d
    
    # Give other services time to start
    Start-Sleep 30
}

function Test-Installation {
    Write-Info "Testing installation..."
    
    # Test services
    $services = @(
        @{Name="Baserow API"; Url="http://localhost:8000/api/health/"},
        @{Name="MCP Server"; Url="http://localhost:3003/health"},
        @{Name="Grafana"; Url="http://localhost:3000"},
        @{Name="Uptime Kuma"; Url="http://localhost:3001"}
    )
    
    $allHealthy = $true
    
    foreach ($service in $services) {
        try {
            $response = Invoke-WebRequest -Uri $service.Url -TimeoutSec 10
            if ($response.StatusCode -eq 200) {
                Write-Success "$($service.Name) is responding"
            } else {
                Write-Warning "$($service.Name) returned status $($response.StatusCode)"
                $allHealthy = $false
            }
        } catch {
            Write-Error "$($service.Name) is not responding"
            $allHealthy = $false
        }
    }
    
    # Test database
    try {
        docker exec baserow-postgres pg_isready -U baserow -d baserow | Out-Null
        Write-Success "PostgreSQL is accepting connections"
    } catch {
        Write-Error "PostgreSQL connection failed"
        $allHealthy = $false
    }
    
    # Test Redis
    try {
        docker exec baserow-redis redis-cli ping | Out-Null
        Write-Success "Redis is responding"
    } catch {
        Write-Error "Redis connection failed"
        $allHealthy = $false
    }
    
    if ($allHealthy) {
        Write-Success "All services are healthy!"
    } else {
        Write-Warning "Some services have issues. Check the logs with: docker-compose logs"
    }
}

function Show-AccessInfo {
    Write-Info "Installation completed! Access information:"
    Write-Host ""
    Write-Host "🌐 Web Interfaces:" -ForegroundColor Yellow
    Write-Host "   Baserow:      http://localhost:8000" -ForegroundColor Cyan
    Write-Host "   Grafana:      http://localhost:3000" -ForegroundColor Cyan
    Write-Host "   Uptime Kuma:  http://localhost:3001" -ForegroundColor Cyan
    Write-Host "   Prometheus:   http://localhost:9090" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🔧 API Endpoints:" -ForegroundColor Yellow
    Write-Host "   Baserow API:  http://localhost:8000/api" -ForegroundColor Cyan
    Write-Host "   MCP Server:   http://localhost:3003" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🔑 Default Credentials:" -ForegroundColor Yellow
    Write-Host "   Check CREDENTIALS.txt file for passwords" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📚 Next Steps:" -ForegroundColor Yellow
    Write-Host "   1. Open Baserow and create your admin account" -ForegroundColor White
    Write-Host "   2. Create the viral content database schema" -ForegroundColor White
    Write-Host "   3. Generate API tokens for integrations" -ForegroundColor White
    Write-Host "   4. Configure Claude Desktop with MCP" -ForegroundColor White
    Write-Host "   5. Set up Cloudflare tunnel for remote access" -ForegroundColor White
    Write-Host ""
    Write-Host "📖 Documentation:" -ForegroundColor Yellow
    Write-Host "   README.md           - Complete documentation" -ForegroundColor White
    Write-Host "   SETUP_GUIDE.md      - Step-by-step setup guide" -ForegroundColor White
    Write-Host "   API_DOCUMENTATION.md - API reference" -ForegroundColor White
    Write-Host "   TROUBLESHOOTING.md  - Problem solving guide" -ForegroundColor White
    Write-Host ""
    Write-Host "🛠️ Management Commands:" -ForegroundColor Yellow
    Write-Host "   Load PowerShell aliases: . .\scripts\powershell-aliases.ps1" -ForegroundColor White
    Write-Host "   Then use commands like: bstatus, bhealth, blogs, etc." -ForegroundColor White
}

function Main {
    Write-Host "🚀 Baserow Viral Content Management Setup" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host ""
    
    # Check if we're in the right directory
    if (!(Test-Path "docker-compose.yml")) {
        Write-Error "docker-compose.yml not found. Please run this script from the Baserow project directory."
        exit 1
    }
    
    Test-Prerequisites
    Initialize-Environment
    Setup-SSL
    Start-Services
    Test-Installation
    Show-AccessInfo
    
    Write-Host ""
    Write-Success "Setup completed successfully! 🎉"
    
    if (Test-Path "CREDENTIALS.txt") {
        Write-Warning "Don't forget to save your credentials from CREDENTIALS.txt and delete the file!"
    }
}

# Run main function
Main
