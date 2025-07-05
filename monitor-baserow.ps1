# Baserow Monitor Script
# Verifică când Baserow devine complet funcțional

param(
    [int]$MaxAttempts = 30,
    [int]$IntervalSeconds = 20
)

$attempt = 1
$startTime = Get-Date

Write-Host "🔍 MONITORIZEZ BASEROW..." -ForegroundColor Yellow
Write-Host "📍 URL: http://localhost:8010" -ForegroundColor Gray
Write-Host "⏰ Început: $($startTime.ToString('HH:mm:ss'))" -ForegroundColor Gray
Write-Host "" 

while ($attempt -le $MaxAttempts) {
    $currentTime = Get-Date
    $elapsed = $currentTime - $startTime
    
    Write-Host "[$attempt/$MaxAttempts] Verificare $(Get-Date -Format 'HH:mm:ss') (Elapsed: $($elapsed.ToString('mm\:ss')))" -ForegroundColor Cyan
    
    try {
        # Verifică health check API
        $healthResponse = Invoke-WebRequest -Uri "http://localhost:8010/api/health/" -Method GET -TimeoutSec 8 -ErrorAction Stop
        
        if ($healthResponse.StatusCode -eq 200) {
            Write-Host ""
            Write-Host "🎉 =================================" -ForegroundColor Green
            Write-Host "✅ BASEROW ESTE COMPLET FUNCȚIONAL!" -ForegroundColor Green
            Write-Host "🎉 =================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "📱 Interface Web: http://localhost:8010" -ForegroundColor Green
            Write-Host "🔗 API Health: http://localhost:8010/api/health/" -ForegroundColor Green
            Write-Host "⏱️  Timp încărcare: $($elapsed.ToString('mm\:ss'))" -ForegroundColor Green
            Write-Host ""
            Write-Host "🚀 POȚI ACUM TESTA MCP SERVER-URILE!" -ForegroundColor Yellow
            Write-Host "   • SQLite MCP: Gata de utilizare" -ForegroundColor White
            Write-Host "   • Baserow MCP: Acum disponibil" -ForegroundColor White
            
            # Test rapid API pentru a confirma
            try {
                $apiTest = Invoke-WebRequest -Uri "http://localhost:8010/api/workspaces/" -Method GET -TimeoutSec 5
                Write-Host "✅ API Workspaces: Funcțional" -ForegroundColor Green
            } catch {
                Write-Host "⚠️  API necesită autentificare (normal)" -ForegroundColor Yellow
            }
            
            exit 0
        }
    } catch {
        $errorMsg = $_.Exception.Message
        
        if ($errorMsg -like "*404*") {
            Write-Host "   📋 Frontend se încarcă..." -ForegroundColor Gray
        } elseif ($errorMsg -like "*connection*" -or $errorMsg -like "*timeout*") {
            Write-Host "   🔄 Serviciile pornesc..." -ForegroundColor Gray
        } elseif ($errorMsg -like "*502*" -or $errorMsg -like "*503*") {
            Write-Host "   ⚙️  Backend se inițializează..." -ForegroundColor Gray
        } else {
            Write-Host "   ❓ Status: $($errorMsg.Split('.')[0])" -ForegroundColor Gray
        }
    }
    
    if ($attempt -lt $MaxAttempts) {
        Write-Host "   ⏳ Următoarea verificare în $IntervalSeconds secunde..." -ForegroundColor DarkGray
        Start-Sleep $IntervalSeconds
    }
    
    $attempt++
}

Write-Host ""
Write-Host "⚠️ ATENȚIE: Baserow nu s-a încărcat în $($MaxAttempts * $IntervalSeconds / 60) minute" -ForegroundColor Red
Write-Host "🔍 Verific log-urile pentru probleme..." -ForegroundColor Yellow

# Verifică statusul containerului
try {
    $containerStatus = docker ps --filter "name=baserow-app" --format "{{.Status}}"
    Write-Host "📦 Container Status: $containerStatus" -ForegroundColor White
    
    # Afișează ultimele log-uri
    Write-Host ""
    Write-Host "📋 Ultimele log-uri:" -ForegroundColor Yellow
    docker logs baserow-app --tail 15 | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
    
} catch {
    Write-Host "❌ Nu pot verifica containerul: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "💡 SOLUTIE ALTERNATIVA:" -ForegroundColor Cyan
Write-Host "   SQLite MCP Server este complet functional!" -ForegroundColor White
Write-Host "   Poti incepe imediat managementul proiectului." -ForegroundColor White
