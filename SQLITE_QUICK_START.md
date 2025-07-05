# DraculAI SQLite Project Management - Quick Start

## Overview
Sistemul SQLite pentru managementul proiectului DraculAI oferă o alternativă funcțională și independentă la Baserow pentru tracking-ul task-urilor, milestone-urilor și progresului proiectului.

## Setup Instructions

### 1. Verifică instalarea
```powershell
cd "d:\Projects\Baserow"
# Verifică că ai toate dependențele
npm list better-sqlite3
```

### 2. Configurează Claude Desktop
Copiază conținutul din `claude-sqlite-config.json` în configurația ta Claude Desktop:

**Locația fișierului de configurare:**
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`

**Conținut de adăugat:**
```json
{
  "mcpServers": {
    "dragulai-sqlite": {
      "command": "node",
      "args": ["d:\\Projects\\Baserow\\mcp-sqlite-server.js"],
      "env": {}
    }
  }
}
```

### 3. Restart Claude Desktop
După actualizarea configurației, restartează Claude Desktop pentru a încărca MCP server-ul.

## Funcționalități Disponibile

### 📋 Task Management
- **create_task**: Creează task-uri noi cu prioritate, categorie și deadline
- **list_tasks**: Listează task-urile cu filtrare după status, prioritate, categorie
- **update_task**: Actualizează status, progres și alte detalii ale task-urilor

### 🎯 Milestone Tracking  
- **create_milestone**: Creează milestone-uri cu date țintă
- **list_milestones**: Vizualizează toate milestone-urile cu progresul asociat

### 📝 Notes & Documentation
- **add_note**: Adaugă note la task-uri sau milestone-uri pentru documentație

### ⏱️ Time Tracking
- **log_time**: Înregistrează timpul lucrat pe task-uri
- **get_project_status**: Raport complet cu statistici și progres

## Structura Bazei de Date

### Tables
- **tasks**: Task-uri cu status, prioritate, progres, timp estimat/actual
- **milestones**: Milestone-uri cu date țintă și status
- **task_milestone_relations**: Legături între task-uri și milestone-uri
- **notes**: Note asociate cu task-uri sau milestone-uri
- **time_logs**: Înregistrări de timp lucrat

### Statuses
- **Task Status**: pending, in_progress, completed, on_hold
- **Priority**: low, medium, high, urgent
- **Milestone Status**: active, completed, delayed

## Exemple de Utilizare

### Creează un task nou
```
Create a new task titled "Implement user authentication" with high priority in the "Development" category, due on 2024-01-20
```

### Verifică progresul proiectului
```
Show me the current project status with all statistics
```

### Actualizează un task
```
Update task ID 2 to "in_progress" status with 25% progress
```

### Creează un milestone
```
Create a milestone called "MVP Release" with target date 2024-02-15
```

## Beneficii vs Baserow

### ✅ Avantaje SQLite
- **Independență**: Nu depinde de servicii externe
- **Performanță**: Foarte rapid pentru operațiuni locale
- **Simplicitate**: Un singur fișier de bază de date
- **Backup**: Simplu - copiezi fișierul .db
- **Offline**: Funcționează complet offline

### ⚠️ Limitări
- **Colaborare**: Nu suportă colaborare în timp real
- **Interface Web**: Nu are interface grafic (doar prin Claude)
- **Scalabilitate**: Pentru echipe mari Baserow ar fi mai potrivit

## Troubleshooting

### MCP Server nu pornește
```powershell
# Verifică dependențele
cd "d:\Projects\Baserow"
npm install

# Testează manual
echo '{"jsonrpc": "2.0", "id": 1, "method": "tools/list", "params": {}}' | node mcp-sqlite-server.js
```

### Baza de date coruptă
```powershell
# Recreează baza de date
cd "d:\Projects\Baserow"
Remove-Item "dragulai_project.db" -ErrorAction SilentlyContinue
# Pornește server-ul din nou pentru a recrea schema
```

### Claude Desktop nu vede MCP tools
1. Verifică calea în configurație
2. Restartează Claude Desktop complet
3. Verifică log-urile în console

## Data Backup

### Backup simplu
```powershell
cd "d:\Projects\Baserow"
Copy-Item "dragulai_project.db" "backups\dragulai_$(Get-Date -Format 'yyyyMMdd_HHmm').db"
```

### Restore
```powershell
cd "d:\Projects\Baserow"
Copy-Item "backups\dragulai_YYYYMMDD_HHMM.db" "dragulai_project.db"
```

## Migration către Baserow (viitor)

Când Baserow va fi complet funcțional, datele pot fi migrate prin:
1. Export SQL din SQLite
2. Transform în format Baserow API calls
3. Import în Baserow prin MCP tools

---

**Status**: ✅ Gata de utilizare
**Database**: `d:\Projects\Baserow\dragulai_project.db`
**MCP Server**: `d:\Projects\Baserow\mcp-sqlite-server.js`
**Config**: `d:\Projects\Baserow\claude-sqlite-config.json`
