# 🚀 PRODUCTION DEPLOYMENT ROADMAP - EXECUTABLE

> Panduan step-by-step untuk deploy TrAIder API ke production dengan PM2, Nginx, dan SSL

---

## 📅 **TIMELINE & ROADMAP**

### **Week 1: Foundation** ⏰ (Day 1-3)
- ✅ Setup PostgreSQL production database
- ✅ Configure `.env.production` properly
- ✅ Deploy dengan PM2
- ✅ Verify semua endpoint working

### **Week 2: Security** 🔒 (Day 4-7)
- ✅ Setup Nginx reverse proxy
- ✅ Enable SSL/HTTPS dengan Let's Encrypt
- ✅ Setup firewall rules
- ✅ Test CORS configuration

### **Week 3: Monitoring** 📊 (Day 8-14)
- ✅ Setup automated health checks
- ✅ Configure error logging
- ✅ Setup database backups
- ✅ Document runbook

### **Week 4+: Optimization** ⚡ (Ongoing)
- ✅ Monitor performance
- ✅ Setup caching (Redis)
- ✅ Optimize database queries
- ✅ Plan scaling strategy

---

## 🎯 **EXECUTION PLAN**

### **Prerequisites**
Before starting, ensure you have:
- [ ] Ubuntu 24.04 LTS server (or equivalent)
- [ ] SSH access with sudo privileges
- [ ] Domain name (for SSL)
- [ ] Email address (for Let's Encrypt)

---

## 📋 **WEEK 1: FOUNDATION SETUP**

### **Step 1.1: Clone Repository**
```bash
cd /home/yourusername
git clone https://github.com/superiyan/TrAIder-API.git
cd TrAIder-API
npm ci --omit=dev
npm run build
```

### **Step 1.2: Setup PostgreSQL Database** (10 minutes)
```bash
# Copy the setup script to your server
sudo bash setup-postgres.sh

# This will:
# ✓ Install PostgreSQL 16
# ✓ Create production database & user
# ✓ Optimize settings
# ✓ Setup automated backups
# ✓ Output DATABASE_URL

# Save the DATABASE_URL output!
```

**Output akan seperti:**
```
DATABASE_URL=postgresql://traider_prod:STRONG_PASSWORD@localhost:5432/traider_prod
```

### **Step 1.3: Configure Production Environment** (5 minutes)
```bash
# Copy template
cp .env.production.example .env.production

# Edit dengan nilai production
nano .env.production
```

**Minimal configuration:**
```env
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://traider_prod:PASSWORD@localhost:5432/traider_prod

# Generate JWT_SECRET
openssl rand -base64 32

JWT_SECRET=<paste-result-here>
CORS_ORIGIN=https://yourdomain.com
```

### **Step 1.4: Install Node & PM2** (5 minutes)
```bash
# Install Node.js 20
curl -sL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install PM2 globally
sudo npm install -g pm2

# Verify
node -v    # Should be v20.x
pm2 -v
```

### **Step 1.5: Deploy dengan PM2** (10 minutes)
```bash
# Run deployment script
bash deploy-pm2.sh start

# This will:
# ✓ Build application
# ✓ Run database migrations
# ✓ Start with PM2
# ✓ Setup auto-restart
# ✓ Test health endpoint

# Verify
curl http://localhost:3000/health
```

**Expected output:**
```json
{
  "status": "OK",
  "timestamp": "2026-01-22T..."
}
```

### **Step 1.6: Verify Deployment** (5 minutes)
```bash
# Check PM2 status
pm2 status

# View logs
pm2 logs traider-api

# Monitor resources
pm2 monit

# Test API (if you have endpoints)
curl http://localhost:3000/api/v1/...
```

✅ **WEEK 1 COMPLETE!** Your app is running on port 3000.

---

## 🔒 **WEEK 2: SECURITY SETUP**

### **Step 2.1: Setup Nginx Reverse Proxy** (10 minutes)
```bash
# Run Nginx setup
sudo bash setup-nginx.sh yourdomain.com

# This will:
# ✓ Install Nginx
# ✓ Create reverse proxy config
# ✓ Configure rate limiting
# ✓ Setup SSL placeholders
# ✓ Enable compression & security headers

# Verify
sudo nginx -t
curl http://localhost/health
```

### **Step 2.2: Enable SSL with Let's Encrypt** (5 minutes)
```bash
# Run SSL setup
sudo bash setup-ssl.sh yourdomain.com your-email@example.com

# This will:
# ✓ Install certbot
# ✓ Request SSL certificate
# ✓ Update Nginx config
# ✓ Setup auto-renewal
# ✓ Reload Nginx

# Verify
curl -I https://yourdomain.com
```

**Expected output:**
```
HTTP/2 200
Strict-Transport-Security: max-age=31536000
```

### **Step 2.3: Configure Firewall** (5 minutes)
```bash
# UFW firewall rules
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 5432/tcp  # PostgreSQL (internal only - see below)
sudo ufw enable

# Restrict PostgreSQL to localhost only
sudo ufw delete allow 5432/tcp
sudo ufw allow from 127.0.0.1 to 127.0.0.1 port 5432

# Verify
sudo ufw status
```

### **Step 2.4: Test CORS Configuration** (5 minutes)
```bash
# Test CORS
curl -H "Origin: https://yourdomain.com" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type" \
     -X OPTIONS https://yourdomain.com/api/v1/some-endpoint \
     -v

# Should see CORS headers in response
```

✅ **WEEK 2 COMPLETE!** Your app is now secure with HTTPS!

---

## 📊 **WEEK 3: MONITORING SETUP**

### **Step 3.1: Health Check Monitoring** (5 minutes)
```bash
# Create health check cron job
(crontab -l 2>/dev/null; echo "*/5 * * * * curl -s http://localhost:3000/health > /dev/null || pm2 restart traider-api") | crontab -

# Verify
crontab -l
```

### **Step 3.2: Application Logging** (5 minutes)
```bash
# View logs in real-time
pm2 logs traider-api

# View error logs
tail -f logs/error.log

# View combined logs
tail -f logs/combined.log

# Setup log rotation (automatic with Winston)
```

### **Step 3.3: Database Backups** (5 minutes)
```bash
# Backup script already created by setup-postgres.sh
# Runs automatically daily at 2:00 AM

# Manual backup
/usr/local/bin/backup-traider-db.sh

# View backups
ls -lh /backup/postgres/

# Restore backup
psql traider_prod < /backup/postgres/traider_prod_20260122.sql.gz
```

### **Step 3.4: Create Runbook** (10 minutes)
```bash
# Create operational documentation
cat > RUNBOOK.md << 'EOF'
# TrAIder API Runbook

## Daily Tasks
- [ ] Check health: `pm2 logs traider-api`
- [ ] Monitor resources: `pm2 monit`
- [ ] Verify backups: `ls /backup/postgres/`

## Troubleshooting
- App crashed: `pm2 restart traider-api && pm2 logs traider-api`
- DB down: `sudo systemctl restart postgresql`
- High memory: Check logs for memory leaks
- Port conflict: `lsof -i :3000`

## Disaster Recovery
1. Stop app: `pm2 stop traider-api`
2. Restore DB: `psql traider_prod < backup.sql.gz`
3. Restart app: `pm2 restart traider-api`
EOF
```

### **Step 3.5: Monitoring Dashboard** (Optional)
```bash
# Use the monitoring script
bash monitor-traider.sh

# Or continuous monitoring
bash monitor-traider.sh monitor

# Available commands:
# - dashboard: Full overview
# - health: API & DB health
# - status: Process status
# - resources: CPU/Memory/Disk
# - logs: Recent logs
# - metrics: Performance
# - backup: Create backup
# - restart: Restart app
```

✅ **WEEK 3 COMPLETE!** Your app is fully monitored!

---

## ⚡ **WEEK 4+: OPTIMIZATION**

### **Step 4.1: Monitor Performance**
```bash
# Real-time monitoring
pm2 monit

# Check response times
ab -n 100 -c 10 https://yourdomain.com/health

# Check database queries
psql traider_prod -c "\timing" -c "SELECT ..."
```

### **Step 4.2: Setup Redis Caching** (Optional)
```bash
# Install Redis
sudo apt install -y redis-server

# Add to .env.production
REDIS_URL=redis://localhost:6379

# Restart app
pm2 restart traider-api
```

### **Step 4.3: Optimize Database**
```bash
# Analyze query performance
psql traider_prod -c "EXPLAIN ANALYZE SELECT ...;"

# Check table sizes
psql traider_prod -c "SELECT * FROM pg_stat_user_tables;"

# Setup indexes
psql traider_prod -c "CREATE INDEX idx_user_email ON user(email);"
```

### **Step 4.4: Plan Scaling**
```bash
# Current setup handles ~100 concurrent users
# For scaling:
# 1. Add more PM2 instances (clustering)
# 2. Setup load balancer
# 3. Use managed database
# 4. Add CDN for static assets
```

---

## 🆘 **TROUBLESHOOTING**

### **App won't start**
```bash
# Check logs
pm2 logs traider-api

# Check env file
cat .env.production | head -5

# Verify database
psql "$DATABASE_URL" -c "SELECT 1"
```

### **High memory usage**
```bash
# Check memory
pm2 monit

# Check for leaks
pm2 describe traider-api | grep memory

# Restart
pm2 restart traider-api
```

### **Database connection error**
```bash
# Test connection
psql -U traider_prod -h localhost -d traider_prod

# Check DATABASE_URL
grep DATABASE_URL .env.production

# Reset connection
sudo systemctl restart postgresql
```

### **SSL certificate issues**
```bash
# Check certificate
certbot certificates

# Renew manually
sudo certbot renew

# Test renewal
sudo certbot renew --dry-run
```

---

## 📞 **USEFUL COMMANDS**

### **Application Management**
```bash
pm2 status           # Check status
pm2 logs traider-api # View logs
pm2 restart traider-api  # Restart
pm2 stop traider-api # Stop
pm2 delete traider-api   # Remove
pm2 save            # Save config
```

### **Monitoring**
```bash
bash monitor-traider.sh dashboard    # Full dashboard
bash monitor-traider.sh health       # Health check
bash monitor-traider.sh resources    # CPU/Memory
bash monitor-traider.sh logs         # Logs
bash monitor-traider.sh backup       # Create backup
pm2 monit           # Real-time monitoring
```

### **System**
```bash
# Logs
tail -f logs/combined.log
tail -f logs/error.log

# Database
psql traider_prod -c "SELECT * FROM \"User\";"
/usr/local/bin/backup-traider-db.sh

# Nginx
sudo nginx -t
sudo systemctl restart nginx
tail -f /var/log/nginx/traider-api_access.log

# SSL
certbot certificates
sudo certbot renew
```

---

## ✅ **SUCCESS CHECKLIST**

### **Week 1 ✓**
- [ ] PostgreSQL running
- [ ] `.env.production` configured
- [ ] PM2 deployed
- [ ] Health endpoint responds
- [ ] Logs working

### **Week 2 ✓**
- [ ] Nginx configured
- [ ] HTTPS working
- [ ] SSL certificate valid
- [ ] Firewall rules applied
- [ ] CORS working

### **Week 3 ✓**
- [ ] Health checks automated
- [ ] Logs collected
- [ ] Backups running
- [ ] Runbook created
- [ ] Monitoring active

### **Week 4+ ✓**
- [ ] Performance baseline
- [ ] Caching configured
- [ ] Database optimized
- [ ] Scaling plan ready
- [ ] Team trained

---

## 🎉 **DEPLOYMENT COMPLETE!**

Your TrAIder API is now:
✅ Running on production server  
✅ Protected with HTTPS  
✅ Auto-restarting with PM2  
✅ Monitored 24/7  
✅ Backed up daily  
✅ Optimized for performance  
✅ Ready to scale  

**Next: Monitor and optimize based on real traffic!**

---

## 📚 **ADDITIONAL RESOURCES**

- [PM2 Documentation](https://pm2.keymetrics.io/docs)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Let's Encrypt](https://letsencrypt.org/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

---

**Questions? Check the scripts:**
- `setup-postgres.sh` - Database setup
- `deploy-pm2.sh` - Application deployment
- `setup-nginx.sh` - Reverse proxy
- `setup-ssl.sh` - SSL certificate
- `monitor-traider.sh` - Monitoring dashboard
