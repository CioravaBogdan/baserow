# Troubleshooting Guide - Baserow Viral Content Management

This guide helps you diagnose and resolve common issues with your Baserow setup.

## Quick Diagnostics

### System Health Check
```powershell
# Check all services status
docker-compose ps

# Check system resources
docker stats --no-stream

# Check disk space
Get-PSDrive C | Select-Object Used,Free,@{Name="UsedPercent";Expression={($_.Used/($_.Used+$_.Free))*100}}
```

### Service Status Check
```powershell
# Individual service health
docker exec baserow-app curl -f http://localhost/api/health/ || echo "Baserow API: FAILED"
docker exec baserow-postgres pg_isready -U baserow -d baserow || echo "PostgreSQL: FAILED"
docker exec baserow-redis redis-cli ping || echo "Redis: FAILED"
curl -f http://localhost:3003/health || echo "MCP Server: FAILED"
```

## Common Issues & Solutions

### 🔴 Services Won't Start

#### Issue: Docker containers fail to start
**Symptoms:**
- `docker-compose up` shows errors
- Containers exit immediately
- "Port already in use" errors

**Diagnosis:**
```powershell
# Check Docker status
docker info

# Check port conflicts
netstat -an | findstr "8000 5432 6379 3003"

# Check Docker logs
docker-compose logs
```

**Solutions:**

1. **Port Conflicts:**
   ```powershell
   # Find process using port
   netstat -ano | findstr ":8000"
   # Kill process or change port in docker-compose.yml
   ```

2. **Insufficient Resources:**
   ```powershell
   # Increase Docker memory limit in Docker Desktop settings
   # Minimum 6GB recommended
   ```

3. **Permission Issues:**
   ```powershell
   # Run as administrator
   # Check file permissions on project directory
   ```

4. **Environment File Issues:**
   ```powershell
   # Verify .env file exists and has correct format
   Get-Content .env | Select-String "DATABASE_PASSWORD"
   ```

### 🔴 Database Connection Issues

#### Issue: Cannot connect to PostgreSQL
**Symptoms:**
- "Connection refused" errors
- Baserow shows database errors
- Backup scripts fail

**Diagnosis:**
```powershell
# Check PostgreSQL status
docker exec baserow-postgres pg_isready -U baserow -d baserow

# Check PostgreSQL logs
docker-compose logs postgres

# Test connection manually
docker exec -it baserow-postgres psql -U baserow -d baserow -c "\l"
```

**Solutions:**

1. **PostgreSQL Not Ready:**
   ```powershell
   # Wait for initialization (can take 2-5 minutes)
   Start-Sleep 300
   docker exec baserow-postgres pg_isready -U baserow -d baserow
   ```

2. **Wrong Credentials:**
   ```powershell
   # Verify .env file
   Get-Content .env | Select-String "DATABASE_PASSWORD"
   
   # Reset database if needed (⚠️ DESTRUCTIVE)
   docker-compose down -v
   docker-compose up -d postgres
   ```

3. **Corrupted Data:**
   ```powershell
   # Check database logs for corruption
   docker-compose logs postgres | Select-String "corruption\|error\|fatal"
   
   # Restore from backup if available
   .\scripts\restore.sh --latest
   ```

### 🔴 MCP Server Issues

#### Issue: MCP endpoint not responding
**Symptoms:**
- Claude can't connect to MCP server
- `/mcp/health` returns 404 or 500
- MCP features not working

**Diagnosis:**
```powershell
# Test MCP endpoint
curl http://localhost:3003/health

# Check MCP configuration
docker exec baserow-app cat /baserow/mcp-config/baserow-mcp-config.json

# Check MCP logs
docker-compose logs baserow | Select-String "MCP"
```

**Solutions:**

1. **MCP Not Enabled:**
   ```bash
   # Add to .env file
   BASEROW_ENABLE_MCP=true
   BASEROW_MCP_PORT=3003
   ```

2. **Configuration Issues:**
   ```powershell
   # Verify MCP config file
   Get-Content mcp-config\baserow-mcp-config.json | ConvertFrom-Json
   
   # Restart services
   docker-compose restart baserow
   ```

3. **Token Issues:**
   ```powershell
   # Generate new MCP token in Baserow
   # Update .env file
   # Restart services
   ```

### 🔴 SSL/TLS Certificate Issues

#### Issue: HTTPS not working or certificate errors
**Symptoms:**
- Browser shows "Not secure" or certificate warnings
- Remote access fails
- SSL handshake errors

**Diagnosis:**
```powershell
# Check certificate files
dir nginx\ssl\

# Test certificate validity
openssl x509 -in nginx\ssl\cert.pem -text -noout

# Check nginx configuration
docker exec baserow-nginx nginx -t
```

**Solutions:**

1. **Missing Certificates:**
   ```powershell
   # Generate self-signed certificate for testing
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout nginx\ssl\key.pem -out nginx\ssl\cert.pem -subj "/C=RO/ST=Bucharest/L=Bucharest/O=InfantViral/CN=baserow.infant-viral.com"
   ```

2. **Expired Certificates:**
   ```powershell
   # Check expiry date
   openssl x509 -in nginx\ssl\cert.pem -noout -enddate
   
   # Renew certificate (Cloudflare or Let's Encrypt)
   ```

3. **Wrong Certificate:**
   ```powershell
   # Verify certificate matches domain
   openssl x509 -in nginx\ssl\cert.pem -noout -subject
   ```

### 🔴 Remote Access Issues

#### Issue: Cannot access Baserow from remote locations
**Symptoms:**
- Local access works, remote doesn't
- Cloudflare tunnel not working
- DNS resolution issues

**Diagnosis:**
```powershell
# Test local access
curl http://localhost:8000/api/health/

# Test domain resolution
nslookup baserow.infant-viral.com

# Check Cloudflare tunnel
docker-compose logs cloudflared
```

**Solutions:**

1. **Cloudflare Tunnel Issues:**
   ```powershell
   # Check tunnel token
   Get-Content .env | Select-String "CLOUDFLARE_TUNNEL_TOKEN"
   
   # Restart tunnel
   docker-compose restart cloudflared
   
   # Check tunnel status in Cloudflare dashboard
   ```

2. **DNS Issues:**
   ```powershell
   # Verify DNS records in Cloudflare
   # Check if domain points to tunnel
   ```

3. **Firewall Issues:**
   ```powershell
   # Check Windows Firewall
   Get-NetFirewallRule -DisplayName "*Docker*" | Select-Object DisplayName,Enabled,Direction
   
   # Check router/ISP firewall settings
   ```

### 🔴 Performance Issues

#### Issue: Slow response times or high resource usage
**Symptoms:**
- Pages load slowly
- High CPU/memory usage
- Timeout errors

**Diagnosis:**
```powershell
# Check resource usage
docker stats

# Check database performance
docker exec baserow-postgres psql -U baserow -d baserow -c "SELECT query, total_exec_time, calls FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 10;"

# Check logs for slow queries
docker-compose logs postgres | Select-String "slow"
```

**Solutions:**

1. **Insufficient Resources:**
   ```powershell
   # Increase Docker resources in Docker Desktop
   # Add resource limits to docker-compose.yml
   ```

2. **Database Optimization:**
   ```sql
   -- Run in PostgreSQL
   VACUUM ANALYZE;
   REINDEX DATABASE baserow;
   ```

3. **Cache Issues:**
   ```powershell
   # Clear Redis cache
   docker exec baserow-redis redis-cli FLUSHALL
   
   # Restart services
   docker-compose restart
   ```

### 🔴 Backup/Restore Issues

#### Issue: Backup scripts fail or restores don't work
**Symptoms:**
- Backup script exits with errors
- Restore fails with "file not found"
- Corrupted backup files

**Diagnosis:**
```powershell
# Test backup script
wsl ./scripts/backup.sh --test

# Check backup directory
dir backups\

# Verify backup file integrity
# (For WSL/Linux environments)
wsl tar -tzf backups/latest_backup.tar.gz
```

**Solutions:**

1. **Permission Issues:**
   ```powershell
   # Ensure scripts are executable
   wsl chmod +x scripts/*.sh
   ```

2. **Disk Space Issues:**
   ```powershell
   # Check free space
   Get-PSDrive C
   
   # Clean old backups
   dir backups\ | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-30)} | Remove-Item
   ```

3. **Environment Issues:**
   ```powershell
   # Verify .env file is properly loaded
   wsl bash -c "source .env && echo \$DATABASE_PASSWORD"
   ```

## Error Code Reference

### HTTP Status Codes

| Code | Meaning | Common Causes | Solution |
|------|---------|---------------|----------|
| 401 | Unauthorized | Invalid API token | Regenerate token |
| 403 | Forbidden | Insufficient permissions | Check token permissions |
| 404 | Not Found | Wrong endpoint/resource | Verify URL and resource ID |
| 429 | Rate Limited | Too many requests | Implement rate limiting |
| 500 | Server Error | Internal application error | Check application logs |
| 502 | Bad Gateway | Nginx can't reach backend | Check service connectivity |
| 503 | Service Unavailable | Service temporarily down | Wait and retry |

### Docker Compose Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `port is already allocated` | Port conflict | Change port or stop conflicting service |
| `no space left on device` | Disk full | Clean up disk space |
| `network not found` | Network issues | Run `docker network prune` |
| `volume in use` | Volume conflict | Stop containers using volume |

### PostgreSQL Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `connection refused` | Service not ready | Wait for startup |
| `authentication failed` | Wrong credentials | Check .env file |
| `database does not exist` | Missing database | Recreate database |
| `out of memory` | Insufficient RAM | Increase memory allocation |

## Advanced Troubleshooting

### Enable Debug Mode

1. **Add to .env:**
   ```bash
   DEBUG=true
   LOG_LEVEL=debug
   ```

2. **Restart services:**
   ```powershell
   docker-compose down && docker-compose up -d
   ```

3. **View detailed logs:**
   ```powershell
   docker-compose logs -f --tail=100
   ```

### Database Deep Dive

```sql
-- Connect to database
docker exec -it baserow-postgres psql -U baserow -d baserow

-- Check database size
SELECT pg_size_pretty(pg_database_size('baserow'));

-- Check table sizes
SELECT schemaname,tablename,pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY pg_relation_size(schemaname||'.'||tablename) DESC;

-- Check active connections
SELECT * FROM pg_stat_activity WHERE state = 'active';

-- Check slow queries
SELECT query, total_exec_time, calls, mean_exec_time 
FROM pg_stat_statements 
ORDER BY total_exec_time DESC 
LIMIT 10;
```

### Network Diagnostics

```powershell
# Test internal network connectivity
docker exec baserow-app ping postgres
docker exec baserow-app ping redis
docker exec baserow-app curl http://nginx/health

# Check port accessibility
Test-NetConnection -ComputerName localhost -Port 8000
Test-NetConnection -ComputerName localhost -Port 5432
Test-NetConnection -ComputerName localhost -Port 6379
Test-NetConnection -ComputerName localhost -Port 3003
```

### Log Analysis

```powershell
# Search for specific errors
docker-compose logs | Select-String "error\|ERROR\|fatal\|FATAL"

# Check startup sequence
docker-compose logs --timestamps | Sort-Object

# Monitor real-time logs
docker-compose logs -f | Tee-Object -FilePath "debug.log"
```

## Recovery Procedures

### Complete System Reset

⚠️ **WARNING: This will delete ALL data**

```powershell
# Stop all services
docker-compose down -v

# Remove all volumes (DATA LOSS!)
docker volume prune -f

# Remove all images
docker-compose down --rmi all

# Start fresh
docker-compose up -d
```

### Database Recovery

```powershell
# Backup current state (if possible)
docker exec baserow-postgres pg_dump -U baserow baserow > emergency_backup.sql

# Stop Baserow
docker-compose stop baserow

# Restore database
cat emergency_backup.sql | docker exec -i baserow-postgres psql -U baserow -d baserow

# Start Baserow
docker-compose start baserow
```

### Configuration Reset

```powershell
# Backup current config
Copy-Item docker-compose.yml docker-compose.yml.backup
Copy-Item .env .env.backup

# Reset to defaults
Copy-Item .env.example .env
# Edit .env with your settings

# Restart services
docker-compose down && docker-compose up -d
```

## Monitoring & Alerting

### Set Up Monitoring

```powershell
# Access Grafana
Start-Process "http://localhost:3000"

# Access Uptime Kuma
Start-Process "http://localhost:3001"

# Check Prometheus metrics
curl http://localhost:9090/metrics
```

### Key Metrics to Monitor

- **CPU Usage**: Should be < 80%
- **Memory Usage**: Should be < 90%
- **Disk Space**: Should be > 20% free
- **Response Time**: Should be < 2 seconds
- **Error Rate**: Should be < 1%

### Setting Up Alerts

1. **Discord/Slack Webhooks**
2. **Email Notifications**
3. **SMS Alerts** (for critical issues)

## Getting Help

### Collect Debug Information

Before seeking help, collect this information:

```powershell
# System information
Get-ComputerInfo | Select-Object WindowsVersion,TotalPhysicalMemory

# Docker information
docker version
docker info

# Service status
docker-compose ps > debug_info.txt

# Recent logs
docker-compose logs --tail=100 > debug_logs.txt

# Configuration (sanitized)
Get-Content .env | Where-Object {$_ -notmatch "PASSWORD\|SECRET\|TOKEN"} > debug_config.txt
```

### Support Channels

1. **Check documentation** first
2. **Search existing issues** in logs
3. **Collect debug information** above
4. **Describe the problem** clearly:
   - What were you trying to do?
   - What happened instead?
   - When did it start?
   - What changed recently?

---

Most issues can be resolved by following this guide. For persistent problems, ensure you have the debug information ready and follow the systematic approach outlined above.
