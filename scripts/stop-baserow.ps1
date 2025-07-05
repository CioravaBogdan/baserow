# Script pentru oprirea și curățarea stack-ului Baserow
param(
    [switch]$Cleanup = $false,
    [switch]$RemoveVolumes = $false,
    [switch]$Force = $false
)

Write-Host "=== Baserow Stack Shutdown Script ===" -ForegroundColor Cyan

# Funcție pentru oprirea serviciilor
function Stop-BaserowStack {
    Write-Host "`n🛑 Oprire servicii Baserow..." -ForegroundColor Yellow
    
    try {
        # Oprește toate serviciile
        docker-compose down
        
        Write-Host "✅ Serviciile au fost oprite" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Eroare la oprirea serviciilor: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Funcție pentru curățarea imaginilor
function Remove-Images {
    Write-Host "`n🧹 Curățare imagini Docker..." -ForegroundColor Yellow
    
    try {
        # Șterge imaginile pentru acest proiect
        $images = docker images --filter "label=com.docker.compose.project=baserow" -q
        if ($images) {
            docker rmi $images -f
            Write-Host "✅ Imaginile au fost șterse" -ForegroundColor Green
        } else {
            Write-Host "ℹ️  Nu sunt imagini de șters" -ForegroundColor Cyan
        }
    } catch {
        Write-Host "⚠️  Eroare la ștergerea imaginilor: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Funcție pentru curățarea volumelor
function Remove-Volumes {
    Write-Host "`n💾 Curățare volume Docker..." -ForegroundColor Yellow
    
    if (-not $Force) {
        Write-Host "⚠️  ATENȚIE: Această operație va șterge TOATE DATELE!" -ForegroundColor Red
        Write-Host "Aceasta include:" -ForegroundColor Yellow
        Write-Host "  - Baza de date Baserow cu toate tabelele și datele" -ForegroundColor White
        Write-Host "  - Configurările Grafana" -ForegroundColor White
        Write-Host "  - Datele Redis" -ForegroundColor White
        Write-Host "  - Logs-urile și metricile" -ForegroundColor White
        
        $response = Read-Host "`nEști sigur că vrei să continui? Scrie 'DELETE' pentru confirmare"
        if ($response -ne "DELETE") {
            Write-Host "Operația a fost anulată." -ForegroundColor Green
            return
        }
    }
    
    try {
        # Oprește tot înainte de a șterge volumele
        docker-compose down -v
        
        # Șterge volumele pentru acest proiect
        $volumes = docker volume ls --filter "label=com.docker.compose.project=baserow" -q
        if ($volumes) {
            docker volume rm $volumes -f
            Write-Host "✅ Volumele au fost șterse" -ForegroundColor Green
        } else {
            Write-Host "ℹ️  Nu sunt volume de șters" -ForegroundColor Cyan
        }
    } catch {
        Write-Host "❌ Eroare la ștergerea volumelor: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Funcție pentru curățarea completă
function Complete-Cleanup {
    Write-Host "`n🧽 Curățare completă sistem..." -ForegroundColor Yellow
    
    try {
        # Curățare generală Docker
        docker system prune -f
        
        # Curățare rețele nefolosite
        docker network prune -f
        
        Write-Host "✅ Curățare completă finalizată" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Eroare la curățarea completă: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Funcție pentru backup înainte de curățare
function Backup-Data {
    Write-Host "`n💾 Backup date înainte de curățare..." -ForegroundColor Yellow
    
    $backupDir = "backups\emergency-backup-$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss')"
    
    try {
        # Creează directorul de backup
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        
        # Backup baza de date dacă containerul rulează
        $dbContainer = docker ps --filter "name=baserow-postgres" --format "{{.Names}}"
        if ($dbContainer) {
            Write-Host "📦 Backup baza de date..." -ForegroundColor Cyan
            docker exec $dbContainer pg_dump -U baserow baserow > "$backupDir\database-backup.sql"
            Write-Host "✅ Backup baza de date salvat în $backupDir\database-backup.sql" -ForegroundColor Green
        }
        
        # Backup configurarea
        if (Test-Path ".env") {
            Copy-Item ".env" "$backupDir\.env.backup"
            Write-Host "✅ Backup .env salvat" -ForegroundColor Green
        }
        
        if (Test-Path "docker-compose.yml") {
            Copy-Item "docker-compose.yml" "$backupDir\docker-compose.yml.backup"
            Write-Host "✅ Backup docker-compose.yml salvat" -ForegroundColor Green
        }
        
        Write-Host "✅ Backup complet salvat în: $backupDir" -ForegroundColor Green
        return $backupDir
    } catch {
        Write-Host "⚠️  Eroare la backup: $($_.Exception.Message)" -ForegroundColor Yellow
        return $null
    }
}

# Funcție pentru afișarea statusului curent
function Show-CurrentStatus {
    Write-Host "`n📊 Status curent:" -ForegroundColor Cyan
    
    try {
        $containers = docker-compose ps
        if ($containers) {
            Write-Host "Containere active:"
            Write-Host $containers
        } else {
            Write-Host "Nu sunt containere active pentru acest proiect." -ForegroundColor Green
        }
        
        # Verifică volumele
        $volumes = docker volume ls --filter "label=com.docker.compose.project=baserow" --format "table {{.Name}}\t{{.Driver}}\t{{.Size}}"
        if ($volumes) {
            Write-Host "`nVolume existente:"
            Write-Host $volumes
        }
        
        # Verifică imaginile
        $images = docker images --filter "label=com.docker.compose.project=baserow" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
        if ($images) {
            Write-Host "`nImagini existente:"
            Write-Host $images
        }
    } catch {
        Write-Host "Nu s-a putut determina statusul Docker" -ForegroundColor Yellow
    }
}

# Main execution
Show-CurrentStatus

# Oprește serviciile
$stopSuccess = Stop-BaserowStack

if (-not $stopSuccess) {
    Write-Host "`n❌ Nu s-au putut opri serviciile." -ForegroundColor Red
    exit 1
}

# Backup dacă se face curățare
if ($Cleanup -or $RemoveVolumes) {
    $backupPath = Backup-Data
    if ($backupPath) {
        Write-Host "`n💾 Datele au fost salvate în backup: $backupPath" -ForegroundColor Green
    }
}

# Curățare opțională
if ($Cleanup) {
    Remove-Images
    Complete-Cleanup
}

# Ștergere volume opțională  
if ($RemoveVolumes) {
    Remove-Volumes
}

Write-Host "`n✅ OPRIRE COMPLETĂ!" -ForegroundColor Green

if ($Cleanup -or $RemoveVolumes) {
    Write-Host "`nPentru a reporni sistemul:" -ForegroundColor Cyan
    Write-Host ".\scripts\start-baserow.ps1" -ForegroundColor White
} else {
    Write-Host "`nPentru a reporni serviciile:" -ForegroundColor Cyan
    Write-Host "docker-compose up -d" -ForegroundColor White
    Write-Host "`nsau:" -ForegroundColor Cyan
    Write-Host ".\scripts\start-baserow.ps1" -ForegroundColor White
}

if ($backupPath) {
    Write-Host "`nBackup disponibil în: $backupPath" -ForegroundColor Green
}
