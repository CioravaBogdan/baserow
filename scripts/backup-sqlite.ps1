# DraculAI SQLite Backup Script
# Run this script to create a timestamped backup of your project database

param(
    [string]$BackupDir = "backups",
    [switch]$ShowReport
)

# Setup paths
$ProjectDir = "d:\Projects\Baserow"
$DatabaseFile = Join-Path $ProjectDir "dragulai_project.db"
$BackupPath = Join-Path $ProjectDir $BackupDir

# Create backup directory if it doesn't exist
if (!(Test-Path $BackupPath)) {
    New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
    Write-Host "Created backup directory: $BackupPath" -ForegroundColor Green
}

# Check if database exists
if (!(Test-Path $DatabaseFile)) {
    Write-Host "Database file not found: $DatabaseFile" -ForegroundColor Red
    Write-Host "Make sure the SQLite MCP server has been run at least once to create the database." -ForegroundColor Yellow
    exit 1
}

# Create timestamped backup filename
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupFileName = "dragulai_project_$Timestamp.db"
$BackupFilePath = Join-Path $BackupPath $BackupFileName

try {
    # Copy database file
    Copy-Item $DatabaseFile $BackupFilePath -Force
    
    # Get file size for confirmation
    $FileSize = [math]::Round((Get-Item $BackupFilePath).Length / 1KB, 2)
    
    Write-Host "✅ Backup created successfully!" -ForegroundColor Green
    Write-Host "   File: $BackupFileName" -ForegroundColor Cyan
    Write-Host "   Size: $FileSize KB" -ForegroundColor Cyan
    Write-Host "   Path: $BackupFilePath" -ForegroundColor Gray
    
    # Show report if requested
    if ($ShowReport) {
        Write-Host "`n📊 Database Statistics:" -ForegroundColor Yellow
        
        # Quick database stats using better-sqlite3 if available
        $StatsScript = @"
import Database from 'better-sqlite3';
const db = new Database('$($DatabaseFile.Replace('\', '\\'))');

try {
    const tables = ['tasks', 'milestones', 'notes', 'time_logs'];
    const stats = {};
    
    tables.forEach(table => {
        const count = db.prepare(`SELECT COUNT(*) as count FROM `).get().count;
        stats[table] = count;
    });
    
    console.log(JSON.stringify(stats, null, 2));
} catch (error) {
    console.log('Error reading database stats:', error.message);
} finally {
    db.close();
}
"@
        
        $TempStatsFile = Join-Path $env:TEMP "db_stats.mjs"
        $StatsScript | Out-File -FilePath $TempStatsFile -Encoding UTF8
        
        try {
            $StatsOutput = node $TempStatsFile 2>$null
            if ($StatsOutput) {
                $Stats = $StatsOutput | ConvertFrom-Json
                Write-Host "   Tasks: $($Stats.tasks)" -ForegroundColor White
                Write-Host "   Milestones: $($Stats.milestones)" -ForegroundColor White
                Write-Host "   Notes: $($Stats.notes)" -ForegroundColor White
                Write-Host "   Time Logs: $($Stats.time_logs)" -ForegroundColor White
            }
        } catch {
            Write-Host "   (Statistics unavailable - database may be in use)" -ForegroundColor Gray
        } finally {
            Remove-Item $TempStatsFile -ErrorAction SilentlyContinue
        }
    }
    
    # Cleanup old backups (keep last 10)
    $OldBackups = Get-ChildItem $BackupPath -Filter "dragulai_project_*.db" | 
                  Sort-Object CreationTime -Descending | 
                  Select-Object -Skip 10
    
    if ($OldBackups) {
        Write-Host "`n🧹 Cleaning up old backups..." -ForegroundColor Yellow
        $OldBackups | ForEach-Object {
            Remove-Item $_.FullName -Force
            Write-Host "   Removed: $($_.Name)" -ForegroundColor Gray
        }
    }
    
} catch {
    Write-Host "❌ Backup failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n💡 Tip: Use '-ShowReport' parameter to see database statistics" -ForegroundColor DarkGray
