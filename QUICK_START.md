# 🚀 Baserow Stack - Ghid Rapid de Utilizare

## Comenzi Rapide

### 🔍 Verificare și Pornire
```powershell
# Verifică configurarea și porturile
.\scripts\start-baserow.ps1 -CheckOnly

# Pornește tot automat cu verificări
.\scripts\start-baserow.ps1

# Verifică doar porturile
.\scripts\check-ports.ps1
```

### 🛑 Oprire și Curățare
```powershell
# Oprește serviciile
.\scripts\stop-baserow.ps1

# Oprește și curăță imagini Docker
.\scripts\stop-baserow.ps1 -Cleanup

# Oprește și șterge TOATE datele (cu backup automat)
.\scripts\stop-baserow.ps1 -RemoveVolumes

# Ștergere forțată fără confirmare
.\scripts\stop-baserow.ps1 -RemoveVolumes -Force
```

### 📊 Monitorizare
```powershell
# Vezi statusul containerelor
docker-compose ps

# Vezi logs-urile în timp real
docker-compose logs -f

# Vezi logs pentru un serviciu specific
docker-compose logs -f baserow
docker-compose logs -f postgres
docker-compose logs -f cloudflared
```

## 🌐 URL-uri Importante

### Locale (pentru dezvoltare)
- **Baserow UI**: http://localhost:8010
- **Baserow API**: http://localhost:8010/api
- **Grafana**: http://localhost:3010 (admin/admin)
- **Uptime Kuma**: http://localhost:3011
- **Prometheus**: http://localhost:9090
- **MCP Server**: http://localhost:3013

### Remote (prin Cloudflare Tunnel)
- **Baserow UI**: https://baserow.byinfant.com
- **Baserow API**: https://baserow.byinfant.com/api

## 🔧 Configurare Cloudflare Tunnel

1. **Citește ghidul complet**: `CLOUDFLARE_TUNNEL_SETUP.md`
2. **Configurează tunelul** în Cloudflare Dashboard
3. **Adaugă token-ul** în `.env`:
   ```
   CLOUDFLARE_TUNNEL_TOKEN=eyJhIjoiYourTokenHere..."
   ```
4. **Restart serviciile**:
   ```powershell
   docker-compose restart cloudflared
   ```

## 🗂️ Structura Proiectului

```
D:\Projects\Baserow\
├── 📁 scripts/
│   ├── start-baserow.ps1      # Pornire inteligentă cu verificări
│   ├── stop-baserow.ps1       # Oprire și curățare
│   ├── check-ports.ps1        # Verificare porturi
│   ├── backup.sh              # Backup baza de date
│   └── restore.sh             # Restore baza de date
├── 📁 nginx/
│   ├── nginx.conf             # Configurare Nginx
│   └── ssl/                   # Certificate SSL
├── 📁 backups/                # Backup-uri automate
├── 📁 mcp-config/             # Configurare Model Context Protocol
├── docker-compose.yml         # Configurare servicii
├── .env                       # Variabile de mediu (SECRET!)
├── .env.example               # Template pentru .env
├── SETUP_GUIDE.md             # Ghid complet de instalare
├── CLOUDFLARE_TUNNEL_SETUP.md # Ghid Cloudflare Tunnel
├── README.md                  # Documentație generală
├── API_DOCUMENTATION.md       # Documentație API
└── TROUBLESHOOTING.md         # Soluții probleme comune
```

## 🚨 Troubleshooting Rapid

### Serviciile nu pornesc
```powershell
# Verifică porturile ocupate
.\scripts\check-ports.ps1

# Verifică logs-urile pentru erori
docker-compose logs

# Restart complet
docker-compose down && docker-compose up -d
```

### Baserow nu se încarcă
```powershell
# Verifică dacă baza de date este gata
docker exec baserow-postgres pg_isready -U baserow -d baserow

# Verifică logs Baserow
docker-compose logs baserow

# Restart doar Baserow
docker-compose restart baserow
```

### Cloudflare Tunnel nu funcționează
```powershell
# Verifică token-ul în .env
Get-Content .env | Select-String "CLOUDFLARE_TUNNEL_TOKEN"

# Verifică logs tunnel
docker-compose logs cloudflared

# Restart tunnel
docker-compose restart cloudflared
```

### Probleme cu porturile
```powershell
# Găsește ce folosește un port specific
Get-NetTCPConnection -LocalPort 8010

# Oprește proces care blochează portul
Stop-Process -Id <PID> -Force

# Sau modifică porturile în docker-compose.yml
```

## 🔐 Informații de Securitate

### Credențiale Implicite
- **Grafana**: admin/admin (schimbă la prima conectare)
- **Postgres**: baserow/baserow_password
- **Baserow**: Configurează admin la prima accesare

### Fișiere Importante de Protejat
- `.env` - Conține token-uri și parole
- `backups/` - Backup-uri baza de date
- `nginx/ssl/` - Certificate SSL

### Recomandări
1. **Schimbă toate parolele** din `.env`
2. **Configurează HTTPS** obligatoriu pentru producție
3. **Activează backup-uri** automate periodice
4. **Monitorizează logs-urile** pentru activități suspecte

## 📱 Acces Mobil

Baserow funcționează perfect pe mobile prin:
- **Browser mobile**: https://baserow.byinfant.com
- **Aplicația Baserow** (conectează-te la instanța ta)

## 🔄 Backup și Restore

### Backup Manual
```powershell
# Backup complet
.\scripts\backup.sh

# Backup doar baza de date
docker exec baserow-postgres pg_dump -U baserow baserow > backup.sql
```

### Restore
```powershell
# Restore din backup
.\scripts\restore.sh backup_file.sql
```

### Backup Automat
Sistemul face backup automat:
- **Zilnic** la 02:00 (păstrează 7 zile)
- **Săptămânal** duminica (păstrează 4 săptămâni)
- **Lunar** prima zi (păstrează 6 luni)

## 🏃‍♂️ Quick Start pentru Primul Utilizator

1. **Pornește sistemul**:
   ```powershell
   .\scripts\start-baserow.ps1
   ```

2. **Deschide Baserow**: http://localhost:8010

3. **Creează primul admin user**

4. **Configurează tunelul Cloudflare** (vezi `CLOUDFLARE_TUNNEL_SETUP.md`)

5. **Testează accesul remote**: https://baserow.byinfant.com

6. **Configurează backup-urile** și monitorizarea

Succes! 🎉
