# Script pentru pornirea completă a stack-ului Baserow
# Acest script verifică tot și pornește toate serviciile

param(
    [switch]$Force = $false,
    [switch]$CheckOnly = $false
)

Write-Host "=== Baserow Stack Startup Script ===" -ForegroundColor Cyan
Write-Host "Domeniu: baserow.byinfant.com" -ForegroundColor Green

# Funcție pentru verificarea prerequisitelor
function Test-Prerequisites {
    Write-Host "`n🔍 Verificare prerequisite..." -ForegroundColor Yellow
    
    $errors = @()
    
    # Verifică Docker
    try {
        $dockerVersion = docker --version 2>$null
        if ($dockerVersion) {
            Write-Host "✅ Docker: $dockerVersion" -ForegroundColor Green
        } else {
            $errors += "Docker nu este instalat sau nu este în PATH"
        }
    } catch {
        $errors += "Docker nu este disponibil"
    }
    
    # Verifică Docker Compose
    try {
        $composeVersion = docker-compose --version 2>$null
        if ($composeVersion) {
            Write-Host "✅ Docker Compose: $composeVersion" -ForegroundColor Green
        } else {
            $errors += "Docker Compose nu este instalat"
        }
    } catch {
        $errors += "Docker Compose nu este disponibil"
    }
    
    # Verifică fișierele de configurare
    $requiredFiles = @("docker-compose.yml", ".env")
    foreach ($file in $requiredFiles) {
        if (Test-Path $file) {
            Write-Host "✅ Fișier $file există" -ForegroundColor Green
        } else {
            $errors += "Fișierul $file lipsește"
        }
    }
    
    return $errors
}

# Funcție pentru verificarea porturilor
function Test-Ports {
    Write-Host "`n🔍 Verificare porturi..." -ForegroundColor Yellow
    
    $ports = @{
        "8010" = "Baserow UI"
        "8000" = "Baserow Backend" 
        "5434" = "PostgreSQL"
        "6380" = "Redis"
        "3013" = "MCP Server"
        "3010" = "Grafana"
        "3011" = "Uptime Kuma"
        "9090" = "Prometheus"
    }
    
    $conflicts = @()
    
    foreach ($port in $ports.Keys) {
        $service = $ports[$port]
        $processes = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
        
        if ($processes) {
            $conflicts += "Port $port ($service)"
            Write-Host "❌ Port $port ($service) ocupat" -ForegroundColor Red
        } else {
            Write-Host "✅ Port $port ($service) disponibil" -ForegroundColor Green
        }
    }
    
    return $conflicts
}

# Funcție pentru verificarea configurării
function Test-Configuration {
    Write-Host "`n🔍 Verificare configurare..." -ForegroundColor Yellow
    
    $warnings = @()
    
    if (Test-Path ".env") {
        $envContent = Get-Content ".env" -Raw
        
        # Verifică token Cloudflare
        if ($envContent -match "CLOUDFLARE_TUNNEL_TOKEN=eyJ") {
            Write-Host "✅ Token Cloudflare configurat" -ForegroundColor Green
        } else {
            $warnings += "Token Cloudflare nu este configurat sau invalid"
            Write-Host "⚠️  Token Cloudflare lipsă" -ForegroundColor Yellow
        }
        
        # Verifică domeniu
        if ($envContent -match "DOMAIN_NAME=byinfant\.com") {
            Write-Host "✅ Domeniu configurat: byinfant.com" -ForegroundColor Green
        } else {
            $warnings += "Domeniul nu este configurat corect"
        }
        
        # Verifică email
        if ($envContent -match "FROM_EMAIL=.+@byinfant\.com") {
            Write-Host "✅ Email configurat pentru domeniu" -ForegroundColor Green
        } else {
            $warnings += "Email-ul nu este configurat pentru domeniu"
        }
    }
    
    return $warnings
}

# Funcție pentru pornirea serviciilor
function Start-BaserowStack {
    Write-Host "`n🚀 Pornire stack Baserow..." -ForegroundColor Yellow
    
    try {
        # Pull la imaginile noi
        Write-Host "📦 Download imagini Docker..." -ForegroundColor Cyan
        docker-compose pull
        
        # Pornește în background
        Write-Host "🔄 Pornire servicii..." -ForegroundColor Cyan
        docker-compose up -d
        
        # Așteaptă să se inițializeze
        Write-Host "⏳ Așteptare inițializare servicii..." -ForegroundColor Cyan
        Start-Sleep -Seconds 30
        
        # Verifică statusul
        Write-Host "`n📊 Status servicii:" -ForegroundColor Cyan
        docker-compose ps
        
        return $true
    } catch {
        Write-Host "❌ Eroare la pornirea serviciilor: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Funcție pentru testarea serviciilor
function Test-Services {
    Write-Host "`n🧪 Testare servicii..." -ForegroundColor Yellow
    
    $services = @{
        "http://localhost:8010/api/health/" = "Baserow Health"
        "http://localhost:8010" = "Baserow UI"
        "http://localhost:3010" = "Grafana"
        "http://localhost:3011" = "Uptime Kuma"
        "http://localhost:9090" = "Prometheus"
    }
    
    foreach ($url in $services.Keys) {
        $serviceName = $services[$url]
        try {
            $response = Invoke-WebRequest -Uri $url -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Write-Host "✅ $serviceName - OK" -ForegroundColor Green
            } else {
                Write-Host "⚠️  $serviceName - Status: $($response.StatusCode)" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "❌ $serviceName - Nu răspunde" -ForegroundColor Red
        }
    }
}

# Main execution
$prerequisiteErrors = Test-Prerequisites

if ($prerequisiteErrors.Count -gt 0) {
    Write-Host "`n❌ ERORI PREREQUISITE:" -ForegroundColor Red
    $prerequisiteErrors | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
    exit 1
}

$portConflicts = Test-Ports

if ($portConflicts.Count -gt 0 -and -not $Force) {
    Write-Host "`n❌ CONFLICTE DE PORTURI:" -ForegroundColor Red
    $portConflicts | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
    Write-Host "`nFolosește -Force pentru a continua oricum" -ForegroundColor Yellow
    exit 1
}

$configWarnings = Test-Configuration

if ($configWarnings.Count -gt 0) {
    Write-Host "`n⚠️  AVERTISMENTE CONFIGURARE:" -ForegroundColor Yellow
    $configWarnings | ForEach-Object { Write-Host "   - $_" -ForegroundColor Yellow }
}

if ($CheckOnly) {
    Write-Host "`n✅ Verificare completă. Folosește fără -CheckOnly pentru a porni serviciile." -ForegroundColor Green
    exit 0
}

if (-not $Force -and $configWarnings.Count -gt 0) {
    $response = Read-Host "`nContinui cu avertismentele de mai sus? (y/N)"
    if ($response -ne "y" -and $response -ne "Y") {
        Write-Host "Oprire la cererea utilizatorului." -ForegroundColor Yellow
        exit 0
    }
}

$startSuccess = Start-BaserowStack

if ($startSuccess) {
    Test-Services
    
    Write-Host "`n🎉 BASEROW STACK PORNIT!" -ForegroundColor Green
    Write-Host "`nURL-uri importante:" -ForegroundColor Cyan
    Write-Host "• Baserow UI: http://localhost:8010" -ForegroundColor White
    Write-Host "• Baserow UI (Public): https://baserow.byinfant.com" -ForegroundColor White
    Write-Host "• Grafana: http://localhost:3010 (admin/admin)" -ForegroundColor White
    Write-Host "• Uptime Kuma: http://localhost:3011" -ForegroundColor White
    Write-Host "• Prometheus: http://localhost:9090" -ForegroundColor White
    
    Write-Host "`nComanda pentru logs:" -ForegroundColor Cyan
    Write-Host "docker-compose logs -f" -ForegroundColor White
    
    Write-Host "`nComanda pentru stop:" -ForegroundColor Cyan
    Write-Host "docker-compose down" -ForegroundColor White
} else {
    Write-Host "`n❌ Pornirea a eșuat. Verifică logs-urile:" -ForegroundColor Red
    Write-Host "docker-compose logs" -ForegroundColor White
    exit 1
}
