# Baserow Setup Guide - Step by Step

This guide will walk you through setting up the complete Baserow viral content management system with MCP support.

## Prerequisites

### System Requirements
- Windows 10/11 or Windows Server
- Docker Desktop for Windows
- PowerShell 5.1 or later
- At least 8GB RAM
- 50GB free disk space
- Internet connection for initial setup

### Required Accounts
- Cloudflare account (for tunnel and DNS)
- Email provider (Gmail, Outlook, etc.)
- Cloud storage account (optional, for backups)

## Step 1: Install Docker Desktop

1. **Download Docker Desktop**
   - Go to https://www.docker.com/products/docker-desktop/
   - Download Docker Desktop for Windows
   - Run the installer

2. **Configure Docker**
   - Enable WSL 2 backend if prompted
   - Allocate at least 6GB RAM to Docker
   - Start Docker Desktop

3. **Verify Installation**
   ```powershell
   docker --version
   docker-compose --version
   ```

## Step 2: Prepare Environment

1. **Navigate to Project Directory**
   ```powershell
   cd D:\Projects\Baserow
   ```

2. **Copy Environment Template**
   ```powershell
   Copy-Item .env.example .env
   ```

3. **Edit Environment Variables**
   Open `.env` in your text editor and configure:

   ```bash
   # Generate a secure database password
   DATABASE_PASSWORD=your_secure_database_password_here_minimum_20_chars

   # Generate a secret key (minimum 50 characters)
   SECRET_KEY=your_very_long_secret_key_minimum_50_characters_random_string_here

   # Configure email settings
   EMAIL_SMTP_HOST=smtp.gmail.com
   EMAIL_SMTP_PORT=587
   EMAIL_SMTP_USER=your-email@gmail.com
   EMAIL_SMTP_PASSWORD=your-gmail-app-password
   FROM_EMAIL=noreply@byinfant.com   # Set your domain
   DOMAIN_NAME=baserow.byinfant.com

   # Admin credentials
   ADMIN_USERNAME=admin
   ADMIN_PASSWORD=very_secure_admin_password_here

   # Monitoring
   GRAFANA_PASSWORD=secure_grafana_admin_password
   ```

## Step 3: Generate SSL Certificates

### Option A: Self-Signed (Development/Testing)
```powershell
# Create SSL directory if it doesn't exist
mkdir nginx\ssl -Force

# Generate self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout nginx\ssl\key.pem -out nginx\ssl\cert.pem -subj "/C=RO/ST=Bucharest/L=Bucharest/O=ByInfant/CN=baserow.byinfant.com"
```

### Option B: Cloudflare Origin Certificate (Production)
1. Log into Cloudflare Dashboard
2. Go to SSL/TLS > Origin Server
3. Create Certificate
4. Copy certificate to `nginx\ssl\cert.pem`
5. Copy private key to `nginx\ssl\key.pem`

## Step 4: Setup Cloudflare Tunnel

1. **Install Cloudflare CLI** (optional)
   ```powershell
   # Download from https://github.com/cloudflare/cloudflared/releases
   # Or use the Docker method below
   ```

2. **Create Tunnel via Dashboard**
   - Go to Cloudflare Dashboard
   - Zero Trust > Access > Tunnels
   - Create a tunnel named "baserow-byinfant"
   - Configure public hostname:
     - Subdomain: `baserow`
     - Domain: `byinfant.com`
     - Service: `http://nginx:80`
   - Copy the tunnel token

3. **Add Tunnel Token to Environment**
   ```bash
   # Add to .env file
   CLOUDFLARE_TUNNEL_TOKEN=your_cloudflare_tunnel_token_here
   ```

## Step 5: System Startup

### Automated Startup (Recommended)
Use our smart startup script that checks everything:
```powershell
# Verify configuration and ports only
.\scripts\start-baserow.ps1 -CheckOnly

# Full startup with automatic checks
.\scripts\start-baserow.ps1

# Force startup even with port conflicts (not recommended)
.\scripts\start-baserow.ps1 -Force
```

### Manual Port Verification
If you prefer to check manually:
```powershell
.\scripts\check-ports.ps1
```

### Manual Startup Process
1. **Start Core Services**
   ```powershell
   # Start database first
   docker-compose up -d postgres redis

   # Wait for database to initialize
   Start-Sleep 30

   # Check database status
   docker exec baserow-postgres pg_isready -U baserow -d baserow
   ```

2. **Start Baserow Application**
   ```powershell
   docker-compose up -d baserow
   
   # Wait for Baserow to initialize (this may take 5-10 minutes the first time)
   Start-Sleep 300
   ```

3. **Start Remaining Services**
   ```powershell
   docker-compose up -d
   ```

4. **Verify All Services**
   ```powershell
   docker-compose ps
   ```

## Step 6: Initial Configuration

1. **Access Baserow**
   - Open browser to http://localhost:8010
   - Or https://baserow.byinfant.com (if tunnel configured)

2. **Create Admin Account**
   - Username: Use value from `ADMIN_USERNAME` in .env
   - Password: Use value from `ADMIN_PASSWORD` in .env
   - Email: Your email address

3. **Create Database**
   - Click "Create database"
   - Name: "Viral Content Management"
   - Description: "YouTube/TikTok parenting content production"

## Step 7: Create Database Schema

### Create Tables in Order:

#### 1. Content_Ideas Table
- Click "Create table" → Name: "Content_Ideas"
- Add fields:
  - `title` (Text) - Required
  - `hook` (Long text) - Content hook
  - `content_type` (Single select) - Options: milestone, struggle, educational, gentle_parenting, humor
  - `target_age` (Single select) - Options: 0-1, 1-2, 2-3, 3-4, 4-5
  - `viral_score` (Number) - Min: 1, Max: 10
  - `status` (Single select) - Options: idea, approved, in_production, published
  - `created_date` (Date) - Default: today
  - `notes` (Long text)

#### 2. Video_Production Table
- Create table "Video_Production"
- Add fields:
  - `content_idea` (Link to table) - Link to Content_Ideas
  - `script_english` (Long text)
  - `veo3_prompt` (Long text)
  - `video_segments` (Number) - Number of 8-sec clips
  - `voice_over_text` (Long text)
  - `production_status` (Single select) - Options: scripting, veo3_generation, editing, ready
  - `veo3_job_ids` (Long text)
  - `file_paths` (Long text)
  - `duration_seconds` (Number)
  - `created_date` (Date) - Default: today

#### 3. Publishing_Schedule Table
- Create table "Publishing_Schedule"  
- Add fields:
  - `video` (Link to table) - Link to Video_Production
  - `platform` (Multiple select) - Options: YouTube, TikTok, Instagram, Facebook
  - `scheduled_date` (Date)
  - `scheduled_time` (Text)
  - `title_variations` (Long text) - JSON format
  - `hashtags` (Long text)
  - `thumbnail_url` (URL)
  - `published` (Checkbox)
  - `publish_urls` (Long text)

#### 4. Performance_Analytics Table
- Create table "Performance_Analytics"
- Add fields:
  - `video` (Link to table) - Link to Video_Production
  - `platform` (Single select) - Options: YouTube, TikTok, Instagram, Facebook
  - `views` (Number)
  - `likes` (Number)
  - `comments` (Number)
  - `shares` (Number)
  - `watch_time_avg` (Number)
  - `revenue` (Number) - Currency: EUR
  - `checked_date` (Date)
  - `viral_velocity` (Formula) - Calculate views in first 24h

#### 5. Content_Calendar Table
- Create table "Content_Calendar"
- Add fields:
  - `week_start` (Date)
  - `monday` (Link to table) - Link to Publishing_Schedule
  - `tuesday` (Link to table) - Link to Publishing_Schedule
  - `wednesday` (Link to table) - Link to Publishing_Schedule
  - `thursday` (Link to table) - Link to Publishing_Schedule
  - `friday` (Link to table) - Link to Publishing_Schedule
  - `saturday` (Link to table) - Link to Publishing_Schedule
  - `sunday` (Link to table) - Link to Publishing_Schedule
  - `theme` (Text)
  - `notes` (Long text)

## Step 8: Generate API Tokens

1. **Go to Settings** (click your avatar → Settings)
2. **Generate Tokens**:
   - "N8N Workflows" - Full access
   - "Analytics Dashboard" - Read-only access  
   - "Claude MCP" - Full access

3. **Update Environment Variables**
   ```bash
   # Add to .env file
   N8N_API_TOKEN=generated_token_for_n8n
   ANALYTICS_API_TOKEN=generated_token_for_analytics
   CLAUDE_MCP_TOKEN=generated_token_for_claude
   MCP_API_TOKEN=generated_token_for_claude
   ```

4. **Restart Services**
   ```powershell
   docker-compose down
   docker-compose up -d
   ```

## Step 9: Configure MCP for Claude

1. **Test MCP Endpoint**
   ```powershell
   # Test MCP server
   curl http://localhost:3003/health
   ```

2. **Configure Claude Desktop**
   Add to your Claude Desktop config file:
   ```json
   {
     "mcpServers": {
       "baserow-viral": {
         "command": "node",
         "args": ["./mcp-server.js"],         "env": {
           "BASEROW_API_URL": "https://baserow.byinfant.com/api",
           "BASEROW_MCP_TOKEN": "your_claude_mcp_token_here"
         }
       }
     }
   }
   ```

## Step 10: Setup Monitoring

1. **Access Grafana**
   - URL: http://localhost:3000
   - Username: admin
   - Password: Value from `GRAFANA_PASSWORD` in .env

2. **Access Uptime Kuma**
   - URL: http://localhost:3001
   - Create admin account
   - Add monitors for:
     - Baserow (http://baserow:80)
     - PostgreSQL (tcp://postgres:5432)
     - Redis (tcp://redis:6379)

## Step 11: Setup Automated Backups

1. **Test Backup System**
   ```powershell
   # Make backup script executable (if on Linux/WSL)
   chmod +x scripts/backup.sh scripts/restore.sh

   # Test backup (Windows PowerShell with WSL)
   wsl ./scripts/backup.sh --test
   ```

2. **Schedule Regular Backups**
   The backup runs automatically at 2 AM daily via the scheduler service.

## Step 12: Final Verification

Run these commands to verify everything works:

```powershell
# Check all services are running
docker-compose ps

# Test database connection
docker exec baserow-postgres pg_isready -U baserow -d baserow

# Test Baserow API
curl http://localhost:8010/api/health/

# Test MCP endpoint
curl http://localhost:3013/health

# Test remote access (if tunnel configured)
curl https://baserow.byinfant.com/api/health/

# Check backup system
wsl ./scripts/backup.sh --test

# View logs for any errors
docker-compose logs --tail=50
```

## Step 13: Security Hardening

1. **Change Default Passwords**
   - Update all passwords in .env
   - Restart services: `docker-compose down && docker-compose up -d`

2. **Enable 2FA** (in Baserow settings)

3. **Review Firewall Rules**
   - Only expose necessary ports
   - Consider IP whitelisting for admin access

4. **SSL Certificate Monitoring**
   - Set up alerts for certificate expiry
   - Test certificate renewal process

## Troubleshooting Common Issues

### Services Won't Start
```powershell
# Check Docker Desktop is running
docker info

# Check available disk space
Get-PSDrive

# View detailed logs
docker-compose logs
```

### Database Connection Issues
```powershell
# Check PostgreSQL logs
docker-compose logs postgres

# Reset database (⚠️ This will delete all data)
docker-compose down -v
docker-compose up -d postgres
```

### MCP Not Working
```powershell
# Check MCP configuration
docker exec baserow-app cat /baserow/mcp-config/baserow-mcp-config.json

# Check MCP logs
docker-compose logs baserow | Select-String "MCP"
```

### Remote Access Issues
- Verify Cloudflare tunnel configuration
- Check DNS propagation
- Verify SSL certificates
- Test from different networks

## Next Steps

1. **Create Sample Content**
   - Add a few content ideas to test the workflow
   - Test the complete production pipeline

2. **Setup Webhooks**
   - Configure n8n or other automation tools
   - Set up notifications for status changes

3. **Performance Optimization**
   - Monitor resource usage
   - Adjust PostgreSQL settings if needed
   - Consider caching strategies

4. **Backup Strategy**
   - Test restore procedures
   - Configure cloud backup storage
   - Document disaster recovery procedures

## Maintenance Schedule

- **Daily**: Automated backups
- **Weekly**: Check disk space, review logs
- **Monthly**: Update Docker images, test restore
- **Quarterly**: Security review, performance optimization

---

Your Baserow viral content management system is now ready! 🚀

Access your system at:
- **Baserow**: https://baserow.byinfant.com
- **Monitoring**: http://localhost:3010 (Grafana)
- **Uptime**: http://localhost:3011 (Uptime Kuma)
