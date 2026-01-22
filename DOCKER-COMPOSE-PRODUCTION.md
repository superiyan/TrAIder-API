# 🐳 Docker Compose Production Guide

Complete guide untuk menjalankan TrAIder API menggunakan Docker Compose di production environment.

## 📋 Table of Contents

1. [Quick Start](#quick-start)
2. [Prerequisites](#prerequisites)
3. [Configuration](#configuration)
4. [Running Services](#running-services)
5. [Container Management](#container-management)
6. [Database Management](#database-management)
7. [Monitoring & Logs](#monitoring--logs)
8. [Troubleshooting](#troubleshooting)
9. [Production Best Practices](#production-best-practices)

---

## 🚀 Quick Start

```bash
# 1. Copy environment file
cp .env.production.example .env.production

# 2. Edit with your values
nano .env.production

# 3. Build and start all services
docker-compose -f docker-compose.prod.yml up -d

# 4. Check status
docker-compose -f docker-compose.prod.yml ps

# 5. View logs
docker-compose -f docker-compose.prod.yml logs -f app

# 6. Test health
curl http://localhost:3000/health
```

---

## ✅ Prerequisites

### System Requirements

```bash
# Check Docker is installed
docker --version  # >= 20.10

# Check Docker Compose is installed
docker-compose --version  # >= 2.0

# Check disk space (need at least 10GB free)
df -h /
```

### Install Docker & Docker Compose

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $(whoami)
newgrp docker

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify
docker --version
docker-compose --version
```

---

## ⚙️ Configuration

### 1. Environment File

```bash
# Copy template
cp .env.production.example .env.production

# Edit with production values
cat >> .env.production << 'EOF'
# Database
POSTGRES_USER=traider
POSTGRES_PASSWORD=StrongRandomPassword123!
POSTGRES_DB=traider
POSTGRES_PORT=5432

# Application
NODE_ENV=production
PORT=3000
JWT_SECRET=your-very-long-random-secret-key-here-32-chars-minimum
JWT_EXPIRE=7d

# Redis
REDIS_PASSWORD=AnotherStrongPassword123!
REDIS_PORT=6379

# Services
CORS_ORIGIN=https://yourdomain.com
LOG_LEVEL=info

# pgAdmin
PGADMIN_EMAIL=admin@yourdomain.com
PGADMIN_PASSWORD=AdminPassword123!

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000  # 15 minutes
RATE_LIMIT_MAX_REQUESTS=100
EOF
```

### 2. Nginx Configuration

```bash
# Create Nginx config directory
mkdir -p ./ssl ./nginx

# Create nginx.conf
cat > ./nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 10M;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript application/xml+rss 
               application/rss+xml font/truetype font/opentype 
               application/vnd.ms-fontobject image/svg+xml;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=100r/m;
    limit_req_zone $binary_remote_addr zone=auth_limit:10m rate=10r/m;

    upstream app {
        server app:3000;
    }

    server {
        listen 80;
        server_name _;
        
        # Redirect all HTTP to HTTPS
        location / {
            return 301 https://$host$request_uri;
        }
        
        # Allow certbot challenges
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }
    }

    server {
        listen 443 ssl http2;
        server_name yourdomain.com www.yourdomain.com;

        # SSL certificates (update paths)
        ssl_certificate /etc/nginx/ssl/cert.pem;
        ssl_certificate_key /etc/nginx/ssl/key.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers on;

        # Security headers
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Referrer-Policy "strict-origin-when-cross-origin" always;

        # Rate limiting
        limit_req zone=api_limit burst=20 nodelay;

        location / {
            proxy_pass http://app;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }

        # Health check endpoint (no rate limiting)
        location /health {
            limit_req off;
            proxy_pass http://app;
            access_log off;
        }

        # Metrics endpoint (restricted)
        location /metrics {
            allow 127.0.0.1;
            deny all;
            proxy_pass http://app;
        }
    }
}
EOF
```

### 3. SSL Certificates

```bash
# For Let's Encrypt (if using certbot)
mkdir -p ./ssl

# If already have certificates
cp /path/to/cert.pem ./ssl/
cp /path/to/key.pem ./ssl/
chmod 644 ./ssl/cert.pem
chmod 600 ./ssl/key.pem

# Or use self-signed (development only)
openssl req -x509 -newkey rsa:4096 -keyout ./ssl/key.pem \
  -out ./ssl/cert.pem -days 365 -nodes \
  -subj "/C=ID/ST=State/L=City/O=Org/CN=localhost"
```

---

## 🏃 Running Services

### Start All Services

```bash
# Start in background
docker-compose -f docker-compose.prod.yml up -d

# Watch startup progress
docker-compose -f docker-compose.prod.yml logs -f

# Wait for all services to be healthy
docker-compose -f docker-compose.prod.yml ps
```

### Service Status

```bash
# Check all services
docker-compose -f docker-compose.prod.yml ps

# Output should show all services as "healthy" or "running"
```

### Stop All Services

```bash
# Gracefully stop all services
docker-compose -f docker-compose.prod.yml down

# Stop and remove volumes (data loss!)
docker-compose -f docker-compose.prod.yml down -v
```

### Restart Services

```bash
# Restart all
docker-compose -f docker-compose.prod.yml restart

# Restart single service
docker-compose -f docker-compose.prod.yml restart app

# Force restart (kill and start)
docker-compose -f docker-compose.prod.yml kill app
docker-compose -f docker-compose.prod.yml up -d app
```

---

## 🐳 Container Management

### Execute Commands in Container

```bash
# Run command in app container
docker-compose -f docker-compose.prod.yml exec app npm run build

# Open shell in container
docker-compose -f docker-compose.prod.yml exec app sh

# Run command in postgres
docker-compose -f docker-compose.prod.yml exec postgres psql -U traider -d traider
```

### View Container Logs

```bash
# Follow logs
docker-compose -f docker-compose.prod.yml logs -f app

# Last 100 lines
docker-compose -f docker-compose.prod.yml logs --tail=100 app

# Timestamp included
docker-compose -f docker-compose.prod.yml logs --timestamps app

# Only errors
docker-compose -f docker-compose.prod.yml logs app 2>&1 | grep -i error
```

### Resource Usage

```bash
# Monitor all containers
docker stats

# Monitor specific container
docker stats traider-api

# Container details
docker inspect traider-api
```

---

## 🗄️ Database Management

### Backup Database

```bash
# Backup to file
docker-compose -f docker-compose.prod.yml exec -T postgres \
  pg_dump -U traider traider > backup_$(date +%Y%m%d_%H%M%S).sql

# Verify backup
ls -lh backup_*.sql
wc -l backup_*.sql

# Backup to backups directory
docker-compose -f docker-compose.prod.yml exec -T postgres \
  pg_dump -U traider traider > ./backups/backup_$(date +%Y%m%d_%H%M%S).sql
```

### Restore Database

```bash
# From file
docker-compose -f docker-compose.prod.yml exec -T postgres \
  psql -U traider traider < backup_*.sql

# Verify restoration
docker-compose -f docker-compose.prod.yml exec postgres \
  psql -U traider -d traider -c "SELECT COUNT(*) FROM users;"
```

### Database Maintenance

```bash
# Connect to database
docker-compose -f docker-compose.prod.yml exec postgres \
  psql -U traider -d traider

# Common commands
\dt                  # List tables
\d users            # Describe table
SELECT COUNT(*) FROM users;  # Count rows
VACUUM ANALYZE;     # Optimize database
```

### Access pgAdmin

```
# Open in browser
http://localhost:5050

# Login with
Email: admin@traider.com
Password: (from PGADMIN_PASSWORD)

# Add Server:
Name: traider-postgres
Host: postgres
Port: 5432
Username: traider
Password: (from POSTGRES_PASSWORD)
```

---

## 📊 Monitoring & Logs

### Real-Time Monitoring

```bash
# Watch container stats
watch -n 1 'docker stats --no-stream'

# Monitor specific container
docker stats traider-api --no-stream

# CPU and Memory limits
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

### Log Analysis

```bash
# All logs
docker-compose -f docker-compose.prod.yml logs

# Application logs
docker-compose -f docker-compose.prod.yml logs -f app

# Database logs
docker-compose -f docker-compose.prod.yml logs -f postgres

# Nginx access logs
docker-compose -f docker-compose.prod.yml logs -f nginx

# Search in logs
docker-compose -f docker-compose.prod.yml logs app | grep "ERROR"
```

### Health Checks

```bash
# Check service health
docker-compose -f docker-compose.prod.yml ps

# Manual health checks
curl http://localhost:3000/health
curl http://localhost:5050  # pgAdmin
redis-cli -a $REDIS_PASSWORD ping  # Redis
psql $DATABASE_URL -c "SELECT 1"   # PostgreSQL
```

---

## 🐛 Troubleshooting

### Service Won't Start

```bash
# Check logs
docker-compose -f docker-compose.prod.yml logs app

# Common issues:
# 1. Port already in use
lsof -i :3000
kill -9 <PID>

# 2. Database connection issue
docker-compose -f docker-compose.prod.yml logs postgres

# 3. Environment variables
docker-compose -f docker-compose.prod.yml config | grep JWT_SECRET

# Rebuild container
docker-compose -f docker-compose.prod.yml build --no-cache app
docker-compose -f docker-compose.prod.yml up -d app
```

### Database Connection Issues

```bash
# Test connection
docker-compose -f docker-compose.prod.yml exec postgres \
  psql -U traider -d traider -c "SELECT 1"

# Check DATABASE_URL format
docker-compose -f docker-compose.prod.yml exec app \
  echo $DATABASE_URL

# Restart postgres
docker-compose -f docker-compose.prod.yml restart postgres
docker-compose -f docker-compose.prod.yml restart app
```

### High Memory Usage

```bash
# Check memory limits
docker stats --no-stream traider-api

# Reduce memory limit in docker-compose.prod.yml
# deploy.resources.limits.memory: 512M

# Clear cache
docker system prune -a

# Restart container
docker-compose -f docker-compose.prod.yml restart app
```

### Network Issues

```bash
# Check network
docker network ls

# Inspect network
docker network inspect traider-network

# Restart network
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d

# Test connectivity
docker-compose -f docker-compose.prod.yml exec app \
  curl http://postgres:5432 -v
```

---

## 🏆 Production Best Practices

### 1. Persistent Volumes

```yaml
volumes:
  postgres_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /data/postgres  # Use dedicated partition
  redis_data:
    driver: local
    driver_opts:
      device: /data/redis
```

### 2. Resource Limits

```yaml
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 2G
    reservations:
      cpus: '1'
      memory: 1G
```

### 3. Restart Policies

```yaml
# Automatically restart failed containers
restart_policy:
  condition: on-failure
  delay: 5s
  max_attempts: 3
```

### 4. Health Checks

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

### 5. Logging

```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
    labels: "service=traider-api"
```

### 6. Security

- [ ] Change all default passwords in .env.production
- [ ] Use secret management (Docker Secrets for Swarm)
- [ ] Enable SSL/HTTPS
- [ ] Restrict database access to container network
- [ ] Run containers as non-root user

### 7. Monitoring

```bash
# Setup monitoring
docker-compose -f docker-compose.prod.yml exec app curl http://localhost:3000/metrics

# Export logs to ELK/Datadog
docker-compose -f docker-compose.prod.yml logs --timestamps --all > logs.json
```

### 8. Backup Strategy

```bash
#!/bin/bash
# Daily backup
0 2 * * * docker-compose -f /opt/traider/docker-compose.prod.yml exec -T postgres \
  pg_dump -U traider traider > /backups/traider_$(date +\%Y\%m\%d).sql
```

---

## 📋 Useful Aliases

```bash
# Add to .bashrc or .zshrc
alias dc='docker-compose -f docker-compose.prod.yml'
alias dclogs='docker-compose -f docker-compose.prod.yml logs -f'
alias dcps='docker-compose -f docker-compose.prod.yml ps'
alias dcexec='docker-compose -f docker-compose.prod.yml exec'

# Usage:
# dc up -d
# dclogs app
# dcps
# dcexec app npm run build
```

---

**🎉 Your Docker Compose production setup is complete!**
