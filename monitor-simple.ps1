# Baserow Monitor - Simple Version
Write-Host "MONITORIZEZ BASEROW..." -ForegroundColor Yellow
Write-Host "URL: http://localhost:8010" -ForegroundColor Gray

$maxAttempts = 25
$attempt = 1

while ($attempt -le $maxAttempts) {
    Write-Host "[$attempt/$maxAttempts] Verificare $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Cyan
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8010/api/health/" -Method GET -TimeoutSec 5 -ErrorAction Stop
        
        if ($response.StatusCode -eq 200) {
            Write-Host ""
            Write-Host "=====================================" -ForegroundColor Green
            Write-Host "SUCCESS! BASEROW ESTE FUNCTIONAL!" -ForegroundColor Green
            Write-Host "=====================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "Interface Web: http://localhost:8010" -ForegroundColor Green
            Write-Host "API Health: FUNCTIONAL" -ForegroundColor Green
            Write-Host "MCP Servers: GATA DE TESTARE" -ForegroundColor Yellow
            Write-Host ""
            break
        }
    } catch {
        $errorMsg = $_.Exception.Message
        if ($errorMsg -like "*404*") {
            Write-Host "   Frontend se incarca..." -ForegroundColor Gray
        } elseif ($errorMsg -like "*connection*") {
            Write-Host "   Serviciile pornesc..." -ForegroundColor Gray
        } else {
            Write-Host "   Status: Inca se incarca..." -ForegroundColor Gray
        }
    }
    
    if ($attempt -lt $maxAttempts) {
        Start-Sleep 15
    }
    $attempt++
}

if ($attempt -gt $maxAttempts) {
    Write-Host ""
    Write-Host "ATENTIE: Baserow nu s-a incarcat complet" -ForegroundColor Red
    Write-Host "SQLite MCP Server ramane disponibil!" -ForegroundColor Yellow
}
