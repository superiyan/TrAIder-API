# 🌐 Deploying to Production Server (VPS/Cloud)

## Overview

Your application is now ready to deploy to a production environment. This guide covers deployment to:
- AWS EC2 / Lightsail
- Digital Ocean
- Heroku
- Azure
- Google Cloud
- Self-hosted VPS

---

## 🎯 Pre-Deployment Checklist

Before deploying, ensure:

```bash
# Build locally
npm run build

# Test build
npm start

# Verify health endpoint
curl http://localhost:3000/health

# Check environment file
cat .env.production
```

---

## 📋 Option 1: Deploy to Digital Ocean App Platform (Recommended)

### Step 1: Push to GitHub

```bash
git add .
git commit -m "Production deployment setup"
git push origin main
```

### Step 2: Create Digital Ocean App

1. Go to [Digital Ocean Apps](https://cloud.digitalocean.com/apps)
2. Click "Create App"
3. Select your GitHub repository
4. Click "Next"

### Step 3: Configure App

**Service Settings:**
- Source: GitHub repository
- Branch: `main`
- Docker: Dockerfile
- Port: 3000

**Environment Variables:**
- Add all variables from `.env.production`
- Set secure values for:
  - JWT_SECRET
  - POSTGRES_PASSWORD
  - Any API keys

### Step 4: Add Database

1. Click "Create database"
2. Choose PostgreSQL 16
3. Name: `traider_prod`
4. Database URL will be provided

### Step 5: Deploy

```bash
# Update DATABASE_URL in environment variables
# Update other values as needed
# Click "Deploy"
```

---

## 📋 Option 2: Deploy to AWS EC2

### Step 1: Launch EC2 Instance

```bash
# Recommended specs:
# - Ubuntu 24.04 LTS
# - t3.small (1GB RAM, 2 vCPU)
# - 30GB EBS volume
# - Security group: Allow ports 80, 443, 3000, 5432
```

### Step 2: Connect to Server

```bash
ssh -i your-key.pem ec2-user@your-server-ip
```

### Step 3: Setup Server

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt install docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER
```

### Step 4: Clone and Deploy

```bash
# Clone repository
git clone https://github.com/yourusername/TrAIder-API.git
cd TrAIder-API

# Create production environment
cp .env.example .env.production
nano .env.production  # Edit with production values

# Start with Docker Compose
docker-compose -f docker-compose.prod.yml up -d

# Check status
docker-compose -f docker-compose.prod.yml ps
```

### Step 5: Setup Domain

```bash
# Install Nginx as reverse proxy
sudo apt install nginx

# Create Nginx config
sudo nano /etc/nginx/sites-available/traider-api

# Add this config:
```

```nginx
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://localhost:3000/health;
        access_log off;
    }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/traider-api /etc/nginx/sites-enabled/

# Test config
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx

# Setup SSL with Let's Encrypt
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

---

## 📋 Option 3: Deploy to Heroku

```bash
# Install Heroku CLI
curl https://cli.heroku.com/install.sh | sh

# Login
heroku login

# Create app
heroku create traider-api

# Add PostgreSQL
heroku addons:create heroku-postgresql:standard-0 -a traider-api

# Add Redis (optional)
heroku addons:create heroku-redis:premium-0 -a traider-api

# Set environment variables
heroku config:set -a traider-api \
  NODE_ENV=production \
  JWT_SECRET=your-super-secret-key \
  API_VERSION=v1

# Deploy
git push heroku main

# View logs
heroku logs --tail -a traider-api

# Migrate database
heroku run npx prisma migrate deploy -a traider-api
```

---

## 📋 Option 4: Manual VPS Deployment (PM2)

### Step 1: Connect to VPS

```bash
ssh user@your-vps-ip
```

### Step 2: Install Dependencies

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install PostgreSQL (if not using managed DB)
sudo apt install postgresql postgresql-contrib

# Install Redis (optional)
sudo apt install redis-server

# Install PM2 globally
sudo npm install -g pm2
```

### Step 3: Clone and Setup

```bash
# Create app directory
sudo mkdir -p /var/www/traider-api
sudo chown $USER:$USER /var/www/traider-api
cd /var/www/traider-api

# Clone repository
git clone https://github.com/yourusername/TrAIder-API.git .

# Install dependencies
npm ci --omit=dev

# Create production environment
cp .env.example .env.production
nano .env.production  # Edit values

# Build
npm run build
```

### Step 4: Start with PM2

```bash
# Start application
pm2 start ecosystem.config.js --env production

# Save PM2 config
pm2 save

# Setup auto-restart on reboot
pm2 startup
# Copy and run the command it provides

# View logs
pm2 logs traider-api
```

### Step 5: Nginx Reverse Proxy

```bash
# Install Nginx
sudo apt install nginx

# Create config (see Option 2 above for example)
sudo nano /etc/nginx/sites-available/traider-api

# Enable and test
sudo ln -s /etc/nginx/sites-available/traider-api /etc/nginx/sites-enabled/
sudo nginx -t

# Restart
sudo systemctl restart nginx

# SSL with Certbot
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com
```

---

## 🔐 Production Environment Variables

Make sure to set these on your production server:

```env
# Production settings
NODE_ENV=production
PORT=3000
LOG_LEVEL=warn

# Database (use managed service in production)
DATABASE_URL=postgresql://user:password@db-host:5432/traider_prod

# Security
JWT_SECRET=<generate-strong-random-secret>
CORS_ORIGIN=https://yourdomain.com,https://app.yourdomain.com

# API Configuration
API_VERSION=v1
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Cache (optional)
REDIS_URL=redis://cache-host:6379

# External APIs (optional)
OPENAI_API_KEY=sk-...
MARKET_DATA_API_KEY=...
```

---

## 🛠️ Monitoring & Maintenance

### Setup Monitoring

```bash
# Install Sentry
npm install @sentry/node

# Or use PM2 Plus for monitoring
pm2 plus  # Interactive setup

# View PM2 dashboard
pm2 web
# Access at http://server-ip:9615
```

### Backup Database

```bash
# Automated backup script
cat > /home/user/backup-db.sh << 'EOF'
#!/bin/bash
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
pg_dump $DATABASE_URL > /backups/traider_$TIMESTAMP.sql
find /backups -name "traider_*.sql" -mtime +30 -delete  # Keep 30 days
EOF

chmod +x /home/user/backup-db.sh

# Add to crontab (daily at 2 AM)
(crontab -l 2>/dev/null; echo "0 2 * * * /home/user/backup-db.sh") | crontab -
```

### Monitor Services

```bash
# Check API health
curl https://yourdomain.com/health

# View logs
pm2 logs traider-api

# Monitor processes
pm2 monit

# Check disk space
df -h

# Check memory
free -m
```

---

## 🔄 Updating Production

### Deploy Updates

```bash
# Pull latest code
git pull origin main

# Install new dependencies
npm ci --omit=dev

# Build
npm run build

# Run migrations
DATABASE_URL=<prod-db> npx prisma migrate deploy

# Restart PM2
pm2 restart traider-api
# Or Docker
docker-compose -f docker-compose.prod.yml up -d
```

### Rollback

```bash
# Revert last commit
git revert HEAD

# Rebuild and restart
npm run build
pm2 restart traider-api
```

---

## 📊 Performance Tips

### Database
- Use connection pooling (PgBouncer)
- Enable query caching
- Index frequently queried columns
- Archive old logs

### Application
- Enable gzip compression
- Use Redis caching
- Implement pagination
- Monitor memory usage

### Infrastructure
- Use CDN for static assets
- Setup auto-scaling
- Configure load balancer
- Monitor uptime

---

## 🆘 Troubleshooting

### API not responding

```bash
# Check if running
curl http://localhost:3000/health

# View logs
pm2 logs traider-api

# Restart
pm2 restart traider-api
```

### Database connection error

```bash
# Test connection
psql $DATABASE_URL -c "SELECT 1"

# Check env variable
echo $DATABASE_URL

# Verify database is running
pg_isready -h your-db-host
```

### High memory usage

```bash
# Monitor memory
pm2 monit

# Increase Node heap size
pm2 start ecosystem.config.js --max-memory-restart 2G
```

---

## 📞 Support

For detailed information:
- 📖 [PRODUCTION.md](./PRODUCTION.md)
- ✅ [DEPLOYMENT-CHECKLIST.md](./DEPLOYMENT-CHECKLIST.md)
- 📊 [PRODUCTION-LIVE.md](./PRODUCTION-LIVE.md)

---

**Happy Deploying! 🚀**
