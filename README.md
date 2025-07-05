# Baserow Docker Deployment - WORKING SETUP ✅

Complete Docker-based setup for Baserow with all network errors resolved and MCP (Model Context Protocol) support.

## 🚀 Quick Start - FULLY TESTED & WORKING

1. **Clone Repository**
   ```bash
   git clone https://github.com/CioravaBogdan/baserow.git
   cd baserow
   ```

2. **Start Services** (Simple - No SSL/Cloudflare needed)
   ```bash
   docker-compose up -d
   ```

3. **Access Baserow**
   - **Baserow UI: http://localhost:8088** ✅ WORKING
   - All containers healthy and API connectivity verified

## ✅ Problem Resolution Summary

This repository contains the **FINAL WORKING SOLUTION** for Baserow Docker deployment after resolving:

- ❌ **Blank white screen** → ✅ Fixed with proper Nginx config
- ❌ **400 Bad Request** → ✅ Fixed with increased header buffers  
- ❌ **502 Bad Gateway** → ✅ Fixed with correct upstream port (baserow:80)
- ❌ **Network Error - Could not connect to API** → ✅ Fixed with environment variable propagation

### Key Fix: Environment Variables + Full Container Restart
The critical solution was setting proper environment variables AND doing a full container recreation:

```bash
# REQUIRED: Full restart for environment variables to take effect
docker-compose down
docker-compose up -d
```

## 📁 Project Structure

```
baserow-viral-content/
├── docker-compose.yml          # Main orchestration file
├── .env.example               # Environment variables template
├── .env                       # Your actual environment (create from .example)
├── data/                      # Persistent data storage
│   ├── postgres/             # PostgreSQL data
│   ├── redis/                # Redis data
│   └── media/                # Baserow media files
├── backups/                  # Automated backups storage
├── scripts/                  # Utility scripts
│   ├── backup.sh            # Automated backup script
│   ├── restore.sh           # Restore from backup
│   └── postgres-init.sql    # Database initialization
├── mcp-config/              # MCP server configuration
│   └── baserow-mcp-config.json
├── nginx/                   # Reverse proxy configuration
│   ├── nginx.conf          # Main nginx config
│   └── ssl/                # SSL certificates
└── monitoring/             # Monitoring stack
    ├── prometheus.yml      # Metrics collection
    └── grafana/           # Visualization dashboards
```

## 🔧 Configuration

### Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
# Essential configuration
DATABASE_PASSWORD=your_secure_password
SECRET_KEY=your_very_long_secret_key_50_characters_minimum
CLOUDFLARE_TUNNEL_TOKEN=your_tunnel_token

# Email settings (for notifications)
EMAIL_SMTP_HOST=smtp.gmail.com
EMAIL_SMTP_USER=your-email@gmail.com
EMAIL_SMTP_PASSWORD=your-app-password

# Domain configuration
DOMAIN_NAME=baserow.infant-viral.com
```

### Cloudflare Tunnel Setup (Recommended for Remote Access)

1. **Install Cloudflare Tunnel**
   - Log into Cloudflare Dashboard
   - Go to Zero Trust > Access > Tunnels
   - Create a new tunnel named "baserow-viral"

2. **Configure Public Hostname**
   - Subdomain: `baserow`
   - Domain: `infant-viral.com`
   - Service: `http://nginx:443`

3. **Get Tunnel Token**
   - Copy the tunnel token from Cloudflare
   - Add it to `.env` as `CLOUDFLARE_TUNNEL_TOKEN`

## 📊 Database Schema

The system includes pre-configured tables for viral content management:

### Content_Ideas
- Video concept tracking with viral scoring
- Target age groups and content types
- Hook development and status tracking

### Video_Production
- Production workflow management
- AI prompt tracking (Veo3, scripts)
- File path management and status

### Publishing_Schedule
- Multi-platform publishing calendar
- Platform-specific optimizations
- Title variations and hashtags

### Performance_Analytics
- Cross-platform metrics tracking
- Revenue and engagement analytics
- Viral velocity calculations

### Content_Calendar
- Weekly content planning
- Theme organization
- Production scheduling

## 🤖 MCP Integration

### Claude Desktop Configuration

Add to your Claude Desktop config:

```json
{
  "mcpServers": {
    "baserow-viral": {
      "command": "node",
      "args": ["./mcp-server.js"],
      "env": {
        "BASEROW_API_URL": "https://baserow.infant-viral.com/api",
        "BASEROW_MCP_TOKEN": "your_mcp_token_here"
      }
    }
  }
}
```

### Available MCP Features
- Natural language database queries
- Bulk operations (import/export)
- Schema modifications
- Real-time notifications
- Content generation assistance

## 🔄 Backup & Restore

### Automated Backups
Backups run automatically at 2 AM daily:
- Full PostgreSQL dump
- Media files sync
- Configuration backup
- 30-day local retention
- Cloud storage upload (optional)

### Manual Backup
```bash
./scripts/backup.sh
```

### Test Backup System
```bash
./scripts/backup.sh --test
```

### Restore from Backup
```bash
# List available backups
./scripts/restore.sh --list

# Restore latest backup
./scripts/restore.sh --latest

# Restore specific backup
./scripts/restore.sh baserow_backup_20231215_143022.tar.gz
```

## 📈 Monitoring

### Grafana Dashboards
- System metrics (CPU, Memory, Disk)
- Database performance
- API response times
- MCP server metrics
- Content production KPIs

### Prometheus Metrics
- Application health checks
- Custom business metrics
- Infrastructure monitoring
- Alert conditions

### Uptime Monitoring
- Service availability
- Response time tracking
- Downtime alerts
- SLA monitoring

## 🔒 Security Features

### Network Security
- Rate limiting (API: 10req/s, MCP: 5req/s)
- IP-based connection limits
- CORS protection
- SSL/TLS encryption

### Application Security
- Token-based authentication
- Role-based permissions
- Request validation
- Audit logging

### Infrastructure Security
- Container isolation
- Non-root processes
- Secret management
- Regular security updates

## 🚀 Performance Optimization

### Database Tuning
- Connection pooling
- Query optimization
- Index management
- Cache strategies

### Application Performance
- Redis caching layer
- CDN integration (Cloudflare)
- Gzip compression
- Static file optimization

### Infrastructure Scaling
- Horizontal scaling ready
- Load balancing configuration
- Resource limits and reservations
- Auto-restart policies

## 🔧 Management Commands

### Service Management
```bash
# View service status
docker-compose ps

# View logs
docker-compose logs -f baserow

# Restart specific service
docker-compose restart baserow

# Update services
docker-compose pull
docker-compose up -d
```

### Database Management
```bash
# Database backup
docker exec baserow-postgres pg_dump -U baserow baserow > backup.sql

# Database restore
cat backup.sql | docker exec -i baserow-postgres psql -U baserow -d baserow

# Database connection test
docker exec baserow-postgres pg_isready -U baserow -d baserow
```

### API Testing
```bash
# Health check
curl http://localhost:8000/api/health/

# MCP status
curl http://localhost:3003/health

# API authentication test
curl -H "Authorization: Token YOUR_TOKEN" http://localhost:8000/api/database/tables/
```

## 🆘 Troubleshooting

### Common Issues

**Services won't start:**
```bash
# Check logs
docker-compose logs

# Check disk space
df -h

# Verify environment
cat .env
```

**Database connection errors:**
```bash
# Check PostgreSQL status
docker exec baserow-postgres pg_isready

# View database logs
docker-compose logs postgres

# Reset database (⚠️ DESTRUCTIVE)
docker-compose down -v
docker-compose up -d
```

**MCP connection issues:**
```bash
# Check MCP server status
curl http://localhost:3003/health

# View MCP logs
docker-compose logs baserow | grep MCP

# Restart MCP server
docker-compose restart baserow
```

### Performance Issues

**High memory usage:**
```bash
# Check resource usage
docker stats

# Optimize PostgreSQL settings in .env
POSTGRES_SHARED_BUFFERS=256MB
POSTGRES_EFFECTIVE_CACHE_SIZE=1GB
```

**Slow API responses:**
```bash
# Check database performance
docker exec baserow-postgres psql -U baserow -d baserow -c "SELECT * FROM pg_stat_activity;"

# View slow queries
docker exec baserow-postgres psql -U baserow -d baserow -c "SELECT query, total_exec_time, calls FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 10;"
```

## 📝 API Endpoints

### Baserow API
- Base URL: `https://baserow.infant-viral.com/api`
- Authentication: `Token YOUR_API_TOKEN`
- Documentation: `/api/redoc/`

### MCP Server API  
- Base URL: `https://baserow.infant-viral.com/mcp`
- WebSocket: `wss://baserow.infant-viral.com/mcp/ws`
- Health Check: `/mcp/health`

### Monitoring APIs
- Prometheus: `/metrics`
- Grafana: `http://localhost:3000`
- Uptime Kuma: `http://localhost:3001`

## 🔄 Updates & Maintenance

### Regular Maintenance Tasks
- [ ] Check disk space weekly
- [ ] Review backup integrity monthly
- [ ] Update SSL certificates before expiry
- [ ] Monitor security advisories
- [ ] Performance review quarterly

### Update Procedure
```bash
# 1. Backup current state
./scripts/backup.sh

# 2. Pull latest images
docker-compose pull

# 3. Update services
docker-compose up -d

# 4. Verify functionality
./scripts/health-check.sh
```

## 📞 Support & Contacts

For issues and improvements:
- Check logs: `docker-compose logs`
- Review configuration: Check `.env` and `docker-compose.yml`
- Test connectivity: Use provided test commands
- Monitor resources: Use Grafana dashboards

## 📄 License

This configuration is designed for the Infant Viral content management system. Baserow itself is licensed under the MIT License.

---

**⚠️ Important Notes:**
- Always backup before making changes
- Test in development before production deployment
- Monitor resource usage regularly
- Keep credentials secure and rotate regularly
- Review and update security settings periodically
