# 🚀 QUICK DEPLOYMENT REFERENCE CARD

Gunakan panduan cepat ini untuk production deployment

---

## **ONE-LINER DEPLOYMENT** (Untuk yang impatient)

```bash
# Semua command di bawah - jalankan satu per satu di server production

# 1. Setup (30 minutes total)
sudo bash setup-postgres.sh && \
cp .env.production.example .env.production && \
nano .env.production && \
sudo npm install -g pm2 && \
bash deploy-pm2.sh start && \
sudo bash setup-nginx.sh yourdomain.com && \
sudo bash setup-ssl.sh yourdomain.com your-email@example.com

# 2. Verify
curl https://yourdomain.com/health | jq
pm2 status
bash monitor-traider.sh dashboard
```

---

## **STEP-BY-STEP DEPLOYMENT**

### **Step 1: SSH ke server (2 min)**
```bash
ssh user@your-server-ip
cd /home/yourusername
git clone https://github.com/superiyan/TrAIder-API.git
cd TrAIder-API
npm ci --omit=dev
npm run build
```

### **Step 2: Setup Database (10 min)**
```bash
sudo bash setup-postgres.sh

# Simpan output DATABASE_URL!
# Format: postgresql://traider_prod:PASSWORD@localhost:5432/traider_prod
```

### **Step 3: Configure Environment (5 min)**
```bash
cp .env.production.example .env.production
nano .env.production

# Isi:
# NODE_ENV=production
# DATABASE_URL=postgresql://traider_prod:PASSWORD@localhost:5432/traider_prod
# JWT_SECRET=<output dari: openssl rand -base64 32>
# CORS_ORIGIN=https://yourdomain.com
```

### **Step 4: Deploy dengan PM2 (10 min)**
```bash
sudo npm install -g pm2
bash deploy-pm2.sh start

# Verify:
curl http://localhost:3000/health | jq
```

### **Step 5: Setup Nginx (10 min)**
```bash
sudo bash setup-nginx.sh yourdomain.com

# Verify:
curl http://localhost/health
```

### **Step 6: Enable SSL (5 min)**
```bash
sudo bash setup-ssl.sh yourdomain.com your-email@example.com

# Verify:
curl -I https://yourdomain.com
```

### **Step 7: Verify (5 min)**
```bash
# Check all
bash monitor-traider.sh dashboard

# Test endpoints
curl https://yourdomain.com/health | jq
pm2 status
```

**DONE!** ✅ App is running on https://yourdomain.com

---

## **MOST COMMON COMMANDS**

### **🔍 Check Status**
```bash
# Quick check
pm2 status

# Full dashboard
bash monitor-traider.sh dashboard

# Real-time monitoring
pm2 monit

# View logs
pm2 logs traider-api
```

### **🔄 Restart / Manage**
```bash
# Restart app
bash deploy-pm2.sh restart

# View logs
bash deploy-pm2.sh logs

# Stop app
pm2 stop traider-api

# Restart app
pm2 restart traider-api

# Full deployment
bash deploy-pm2.sh start
```

### **💾 Backup / Restore**
```bash
# Backup database
bash monitor-traider.sh backup

# Manual backup
/usr/local/bin/backup-traider-db.sh

# List backups
ls -lh /backup/postgres/

# Restore
psql traider_prod < /backup/postgres/traider_prod_20260122.sql.gz
```

### **🔒 SSL / Nginx**
```bash
# Check SSL certificate
certbot certificates

# Renew SSL
sudo certbot renew

# Test SSL
curl -I https://yourdomain.com

# Check Nginx config
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

### **📊 Monitor**
```bash
# Health check
bash monitor-traider.sh health

# Performance metrics
bash monitor-traider.sh metrics

# Resource usage
bash monitor-traider.sh resources

# Error logs
tail -f logs/error.log

# Combined logs
tail -f logs/combined.log
```

---

## **TROUBLESHOOTING QUICK FIXES**

### **❌ App not starting**
```bash
# Check logs
pm2 logs traider-api

# Check env file
cat .env.production | head -10

# Restart
pm2 restart traider-api

# If still down:
npm run build
npm run prisma:migrate:prod
pm2 start start-prod.js --name "traider-api" --env production
```

### **❌ Port already in use**
```bash
# Check what's using port 3000
lsof -i :3000

# Kill it
kill -9 <PID>

# Or use different port in .env.production
PORT=3001
pm2 restart traider-api
```

### **❌ Database connection error**
```bash
# Test connection
psql -U traider_prod -d traider_prod

# Check DATABASE_URL
grep DATABASE_URL .env.production

# Verify PostgreSQL running
sudo systemctl status postgresql

# Restart if needed
sudo systemctl restart postgresql
```

### **❌ Out of memory**
```bash
# Check memory usage
pm2 monit

# Increase Node memory
sed -i 's/node start-prod.js/node --max-old-space-size=2048 start-prod.js/g' .env.production
pm2 restart traider-api

# Or restart with flag
NODE_OPTIONS="--max-old-space-size=2048" pm2 restart traider-api
```

### **❌ SSL certificate error**
```bash
# Check certificate
certbot certificates

# Renewal
sudo certbot renew

# Dry run first
sudo certbot renew --dry-run

# If expired, manually renew
sudo certbot certonly --nginx -d yourdomain.com
```

### **❌ HTTPS not working**
```bash
# Check Nginx config
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx

# Check firewall
sudo ufw status

# Allow HTTPS
sudo ufw allow 443/tcp

# Test
curl -I https://yourdomain.com
```

---

## **DAILY MAINTENANCE**

### **Morning Checklist** ☀️
```bash
# Run dashboard
bash monitor-traider.sh dashboard

# Verify 24h uptime
pm2 describe traider-api | grep uptime

# Check logs for errors
grep ERROR logs/error.log | tail -20
```

### **Weekly Checklist** 📅
```bash
# Backup status
ls -lh /backup/postgres/ | tail -7

# Log sizes
du -sh logs/

# Database size
psql traider_prod -c "SELECT pg_size_pretty(pg_database_size('traider_prod'));"

# Update dependencies (optional)
npm audit fix
```

### **Monthly Checklist** 📆
```bash
# Review performance
pm2 describe traider-api

# SSL certificate expiry
certbot certificates

# Rotate old backups (auto but verify)
find /backup/postgres -name "traider_prod_*.sql.gz" -mtime +30

# Disk space check
df -h /

# Database optimization
psql traider_prod -c "VACUUM ANALYZE;"
```

---

## **IMPORTANT PATHS**

```
# Application
/home/yourusername/TrAIder-API/

# Logs
./logs/combined.log
./logs/error.log

# Backups
/backup/postgres/

# Nginx config
/etc/nginx/sites-available/traider-api
/var/log/nginx/traider-api_*.log

# SSL certificates
/etc/letsencrypt/live/yourdomain.com/

# PostgreSQL data
/var/lib/postgresql/16/main/

# PM2 logs
~/.pm2/logs/
```

---

## **DOCUMENTATION FILES**

Inside the project directory:

```
PRODUCTION-ROADMAP.md      ← START HERE (main guide)
PRODUCTION-DEPLOYMENT.md   ← Quick start
DEPLOY-FIXED.md           ← Complete deployment guide
DEPLOYMENT-READY.md       ← Checklists

setup-postgres.sh         ← Database setup
deploy-pm2.sh            ← Application deployment
setup-nginx.sh           ← Reverse proxy setup
setup-ssl.sh             ← SSL certificate setup
monitor-traider.sh       ← Monitoring dashboard
```

---

## **EMERGENCY PROCEDURES**

### **🔴 Full System Recovery**
```bash
# 1. Stop everything
pm2 stop traider-api
pm2 delete traider-api
sudo systemctl stop nginx

# 2. Restore database from backup
psql traider_prod < /backup/postgres/latest_backup.sql.gz

# 3. Restart services
sudo systemctl start postgresql
sudo systemctl start nginx

# 4. Redeploy app
cd TrAIder-API
git pull
npm ci --omit=dev
npm run build
npm run prisma:migrate:prod
bash deploy-pm2.sh start

# 5. Verify
curl https://yourdomain.com/health
```

### **🔴 Rollback Deployment**
```bash
# 1. Stop current version
pm2 stop traider-api

# 2. Revert code
git revert HEAD

# 3. Rebuild and redeploy
npm run build
npm run prisma:migrate:prod
pm2 restart traider-api

# 4. If still broken, restore from backup
psql traider_prod < /backup/postgres/backup_before_deploy.sql.gz
```

---

## **QUICK CONTACT REFERENCE**

```
Server IP:      ___________________
Domain:         ___________________
SSH User:       ___________________
DB Password:    ___________________
JWT_SECRET:     ___________________
SSL Email:      ___________________
Backup Location: /backup/postgres/
```

---

## **NOTES**

```
Setup Date:     ________________
Deployed By:    ________________
Last Updated:   ________________
Known Issues:   ________________
```

---

**Print this & keep at your desk!** 📋

For detailed guides, see `PRODUCTION-ROADMAP.md`
