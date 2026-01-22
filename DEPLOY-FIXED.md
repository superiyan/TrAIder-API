# 🚀 Production Deployment Guide - FIXED

## ✅ Problem & Solution

### Problem yang sudah diperbaiki:
- ❌ Environment variables tidak terbaca saat startup production
- ❌ Script `npm start` tidak load `.env.production`
- ✅ FIXED: Membuat startup script khusus production
- ✅ FIXED: Server sekarang auto-detect env file berdasarkan NODE_ENV

---

## 📋 Quick Deployment (3 Steps)

### Step 1: Persiapkan Environment
```bash
# Pastikan .env.production sudah ada dan sesuai konfigurasi
cp .env.example .env.production

# Edit dengan nilai production yang sebenarnya
nano .env.production
```

**Minimum required values untuk .env.production:**
```env
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://user:password@db-host:5432/dbname
JWT_SECRET=your-secret-key-minimal-32-characters-long-here
CORS_ORIGIN=https://yourdomain.com
```

### Step 2: Build & Prepare
```bash
# Install dependencies
npm ci --omit=dev

# Build TypeScript
npm run build

# Run database migrations
npm run prisma:migrate:prod
```

### Step 3: Jalankan Server

#### Option A: Startup Script (Recommended)
```bash
# Langsung jalankan dengan script
NODE_ENV=production node start-prod.js

# Atau dengan nohup untuk persistent
nohup NODE_ENV=production node start-prod.js > logs/production.log 2>&1 &
```

#### Option B: PM2 (Auto-restart, clustering)
```bash
npm install -g pm2
NODE_ENV=production pm2 start start-prod.js --name "traider-api"
pm2 save
pm2 startup
```

#### Option C: Docker (Recommended untuk cloud)
```bash
docker-compose -f docker-compose.prod.yml up -d
```

### Step 4: Verifikasi
```bash
# Check health endpoint
curl http://localhost:3000/health

# Expected response:
# {"status":"OK","timestamp":"2026-01-22T..."}

# View logs
tail -f logs/combined.log
```

---

## 🔧 Available Startup Methods

| Method | Command | Best For | Auto-restart |
|--------|---------|----------|-------------|
| Direct | `NODE_ENV=production node start-prod.js` | Development/Testing | ❌ |
| PM2 | `pm2 start start-prod.js --env production` | VPS/Server | ✅ |
| Docker | `docker-compose -f docker-compose.prod.yml up -d` | Cloud Deployment | ✅ |
| systemd | `systemctl start traider-api` | Linux Server | ✅ |

---

## 🐳 Docker Deployment (Simplest)

### Build & Run
```bash
# Build image
docker build -t traider-api:latest .

# Run with production compose file
docker-compose -f docker-compose.prod.yml up -d

# Check status
docker-compose -f docker-compose.prod.yml ps

# View logs
docker-compose -f docker-compose.prod.yml logs -f api
```

### Using Docker Hub
```bash
# Push to registry
docker tag traider-api:latest yourusername/traider-api:latest
docker push yourusername/traider-api:latest

# Pull on server
docker pull yourusername/traider-api:latest
docker-compose -f docker-compose.prod.yml up -d
```

---

## 🖥️ VPS Deployment (AWS EC2, DigitalOcean, etc.)

### 1. Setup Server
```bash
# SSH ke server
ssh ubuntu@your-server-ip

# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 20
curl -sL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs postgresql redis-server

# Clone repo
git clone https://github.com/yourusername/TrAIder-API.git
cd TrAIder-API
```

### 2. Setup Environment
```bash
# Create .env.production
sudo nano .env.production

# Paste your production config
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://...
JWT_SECRET=...
```

### 3. Setup PostgreSQL
```bash
# Login ke postgres
sudo -u postgres psql

# Create user & database
CREATE USER traider_prod WITH PASSWORD 'strong-password-here';
CREATE DATABASE traider_prod OWNER traider_prod;
GRANT ALL PRIVILEGES ON DATABASE traider_prod TO traider_prod;
\q
```

### 4. Deploy
```bash
# Install & build
npm ci --omit=dev
npm run build
npm run prisma:migrate:prod

# Install PM2
sudo npm install -g pm2

# Start with PM2
NODE_ENV=production pm2 start start-prod.js --name "traider-api"
pm2 save
sudo pm2 startup systemd -u ubuntu --hp /home/ubuntu
```

### 5. Setup Nginx Reverse Proxy
```bash
# Install nginx
sudo apt install -y nginx

# Create config
sudo nano /etc/nginx/sites-available/traider-api
```

**File content:**
```nginx
server {
    listen 80;
    server_name yourdomain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/traider-api /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 6. SSL Certificate (Let's Encrypt)
```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com
```

---

## 📊 Monitoring & Maintenance

### PM2 Monitoring
```bash
# View all processes
pm2 status

# Real-time monitoring
pm2 monit

# View logs
pm2 logs traider-api

# Restart
pm2 restart traider-api

# Stop
pm2 stop traider-api

# Remove
pm2 delete traider-api
```

### Database Backup
```bash
# Backup
pg_dump traider_prod > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore
psql traider_prod < backup.sql
```

### Health Checks
```bash
# Monitor health endpoint
watch -n 5 'curl -s http://localhost:3000/health | jq .'

# Check port
netstat -tlnp | grep 3000

# Check logs
tail -f logs/combined.log
tail -f logs/error.log
```

---

## 🔒 Security Checklist

- ✅ Change JWT_SECRET to strong random value
- ✅ Change database password
- ✅ Set CORS_ORIGIN to specific domain
- ✅ Enable SSL/TLS (HTTPS)
- ✅ Set NODE_ENV=production
- ✅ Setup firewall (only ports 80, 443 public)
- ✅ Enable logging & monitoring
- ✅ Setup database backups
- ✅ Use environment variables, not hardcoded secrets

---

## 🆘 Troubleshooting

### Port already in use
```bash
# Find process using port 3000
lsof -i :3000
# Kill it
kill -9 <PID>

# Or use different port
PORT=3001 NODE_ENV=production node start-prod.js
```

### Database connection error
```bash
# Test connection
psql -U traider_prod -h localhost -d traider_prod

# Check DATABASE_URL format
# postgresql://user:password@host:5432/database
```

### Migrations failing
```bash
# Run with verbose output
npm run prisma:migrate:prod -- --skip-generate

# Reset database (caution!)
npx prisma migrate reset
```

### Out of memory
```bash
# Increase Node memory
NODE_OPTIONS="--max-old-space-size=2048" NODE_ENV=production node start-prod.js
```

---

## 📈 Next Steps

1. **Monitor**: Setup monitoring (PM2+, New Relic, DataDog)
2. **Backup**: Setup automated database backups
3. **CI/CD**: Setup GitHub Actions for auto-deployment
4. **Scaling**: Use load balancer for multiple servers
5. **Caching**: Configure Redis for caching

For more details, see [PRODUCTION.md](PRODUCTION.md)
