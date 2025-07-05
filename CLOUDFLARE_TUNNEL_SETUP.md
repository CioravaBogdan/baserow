# Configurare Cloudflare Tunnel pentru Baserow pe byinfant.com

## Pasii pentru configurarea tunelului

### 1. Accesează Cloudflare Dashboard
- Mergi la https://dash.cloudflare.com/
- Selectează domeniul `byinfant.com`

### 2. Configurează Zero Trust Tunnel
1. **Navigare:**
   - Zero Trust → Access → Tunnels
   - Click pe "Create a tunnel"

2. **Setări Tunnel:**
   - Name: `baserow-byinfant`
   - Save tunnel

3. **Install Connector:**
   - Alege "Docker"
   - Copiază token-ul generat

### 3. Configurează Public Hostname
1. **Public Hostnames Tab:**
   - Click "Add a public hostname"

2. **Setări Hostname:**
   - **Subdomain:** `baserow`
   - **Domain:** `byinfant.com`
   - **Type:** HTTP
   - **URL:** `nginx:80`

3. **Additional settings:**
   - **HTTP Host Header:** `baserow.byinfant.com`
   - **Origin Server Name:** `baserow.byinfant.com`

### 4. Configurează DNS Record
1. **DNS Tab în Cloudflare:**
   - Ar trebui să vezi automat un CNAME record pentru `baserow`
   - Dacă nu există, adaugă:
     - **Type:** CNAME
     - **Name:** baserow
     - **Target:** (generat automat de tunnel)
     - **Proxy status:** Proxied (orange cloud)

### 5. Actualizează .env cu token-ul
```bash
# Copiază token-ul din Cloudflare și adaugă în .env
CLOUDFLARE_TUNNEL_TOKEN=eyJhIjoiYourToken..."
```

### 6. Configurări SSL/TLS în Cloudflare
1. **SSL/TLS Tab:**
   - **SSL/TLS encryption mode:** Full (strict)
   - **Edge Certificates:** activează "Always Use HTTPS"

2. **Origin Server:**
   - Creează un Origin Certificate pentru nginx
   - Copiază certificatul în `nginx/ssl/cert.pem`
   - Copiază cheia privată în `nginx/ssl/key.pem`

### 7. Configurări de Securitate
1. **Security Tab:**
   - **Security Level:** Medium sau High
   - **Bot Fight Mode:** On
   - **Challenge Passage:** 30 minutes

2. **Speed Tab:**
   - **Auto Minify:** CSS, HTML, JavaScript
   - **Brotli:** On

### 8. Testare Configurare
```powershell
# Testează accesul local
curl http://localhost:8010/api/health/

# Testează accesul prin tunnel
curl https://baserow.byinfant.com/api/health/

# Verifică certificatul SSL
curl -I https://baserow.byinfant.com
```

## Comenzi Utile

### Verifică status tunnel
```powershell
docker-compose logs cloudflared
```

### Restart tunnel
```powershell
docker-compose restart cloudflared
```

### Verifică DNS propagare
```powershell
nslookup baserow.byinfant.com
```

## Configurare Finală în aplicație

După ce tunelul funcționează, actualizează:

1. **Baserow Settings:**
   - Public URL: `https://baserow.byinfant.com`

2. **MCP Configuration:**
   - API URL: `https://baserow.byinfant.com/api`

3. **Claude Desktop config:**
   ```json
   {
     "mcpServers": {
       "baserow-byinfant": {
         "command": "node",
         "args": ["./mcp-server.js"],
         "env": {
           "BASEROW_API_URL": "https://baserow.byinfant.com/api",
           "BASEROW_MCP_TOKEN": "your_token_here"
         }
       }
     }
   }
   ```

## Troubleshooting

### Tunnel nu se conectează
```powershell
# Verifică token-ul
docker-compose logs cloudflared | Select-String "token"

# Verifică conectivitatea
docker exec baserow-tunnel ping cloudflare.com
```

### SSL errors
- Verifică că ai Origin Certificate configurat corect
- Asigură-te că SSL mode este "Full (strict)"

### DNS issues
- Verifică că CNAME record-ul este proxied (orange cloud)
- Așteptă până la 24h pentru propagarea DNS globală

---

**Important:** După configurarea tunelului, vei putea accesa Baserow de oriunde în lume la adresa `https://baserow.byinfant.com`!
