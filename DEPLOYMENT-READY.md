# ✅ Production Deployment Checklist - TrAIder API

> Gunakan checklist ini untuk memastikan production deployment berjalan lancar

## 🔍 Pre-Deployment Checks

### Code & Build
- [ ] Latest code sudah di-commit ke git
- [ ] `git log` menunjukkan versi terbaru
- [ ] Tidak ada uncommitted changes: `git status`
- [ ] Build berhasil: `npm run build`
- [ ] Tidak ada TypeScript errors
- [ ] Tidak ada ESLint warnings (opsional tapi recommended)

### Environment Configuration
- [ ] `.env.production` sudah dibuat
- [ ] `NODE_ENV=production` sudah di-set
- [ ] `DATABASE_URL` adalah URL database production yang benar
- [ ] `JWT_SECRET` adalah string random minimal 32 karakter
- [ ] `CORS_ORIGIN` sesuai dengan domain production
- [ ] Semua API keys sudah di-set (OpenAI, Market Data API, dll)
- [ ] File `.env.production` ada di `.gitignore` (JANGAN di-push!)

### Database
- [ ] PostgreSQL 16+ sudah running di production server
- [ ] Database sudah dibuat: `CREATE DATABASE traider_prod;`
- [ ] Database user sudah dibuat dengan password yang kuat
- [ ] Connection string sudah tested: `psql -c "SELECT 1"`
- [ ] Migrations siap: `npm run prisma:migrate:prod`
- [ ] Backup existing data sudah dilakukan (jika upgrade)

### Server Requirements
- [ ] Server OS: Ubuntu 24.04+ atau equivalent
- [ ] Node.js version: 20.x atau lebih baru
- [ ] NPM version: 10.x atau lebih baru
- [ ] Memory minimal: 1GB RAM free
- [ ] Storage minimal: 20GB free space
- [ ] Port 3000 tersedia (atau custom port)
- [ ] Port 80 & 443 tersedia (untuk HTTP/HTTPS)

---

## 📋 Deployment Steps

### Local Testing First
```bash
# 1. Test dengan NODE_ENV=production lokal
npm ci --omit=dev
npm run build
NODE_ENV=production node start-prod.js

# 2. Verify health endpoint
curl http://localhost:3000/health

# 3. Test API endpoint (tanpa auth)
curl http://localhost:3000/api/v1/...

# 4. Stop server
Ctrl+C
```

### Server Deployment

#### Step 1: SSH ke Server
```bash
ssh user@your-server-ip
cd /home/user/TrAIder-API
```

#### Step 2: Update Code
```bash
git pull origin main
npm ci --omit=dev
npm run build
```

#### Step 3: Run Migrations
```bash
npm run prisma:migrate:prod
```

#### Step 4: Start Service
```bash
# Option A: Direct start
NODE_ENV=production node start-prod.js

# Option B: PM2 (recommended)
pm2 start start-prod.js --name "traider-api" --env production
pm2 save

# Option C: Systemd (if setup)
sudo systemctl start traider-api
sudo systemctl enable traider-api
```

---

## ✅ Post-Deployment Verification

### Health Checks
- [ ] Server responds on port 3000: `curl http://localhost:3000/health`
- [ ] Nginx/Reverse proxy working: `curl https://yourdomain.com`
- [ ] Health endpoint returns `{"status":"OK",...}`
- [ ] Logs menunjukkan "Server running on port 3000"

### Application Checks
- [ ] Can authenticate: `POST /api/v1/auth/login`
- [ ] Can access protected routes: `GET /api/v1/user/profile`
- [ ] Database queries working
- [ ] No errors di logs: `tail -f logs/error.log`

### Performance
- [ ] Response time < 500ms
- [ ] No memory leaks: `ps aux | grep node`
- [ ] CPU usage normal (< 50%)
- [ ] Disk space sufficient: `df -h`

### Security
- [ ] HTTPS enabled dengan valid certificate
- [ ] CORS configured correctly
- [ ] Rate limiting active
- [ ] No sensitive data di logs
- [ ] Environment variables tidak exposed

### Monitoring
- [ ] Logs rotating properly: `ls -la logs/`
- [ ] PM2 monitoring active: `pm2 status`
- [ ] Database backups configured
- [ ] Alerts/notifications setup (optional)

---

## 🆘 Troubleshooting

### Server won't start
```bash
# 1. Check logs
tail -f logs/error.log

# 2. Verify env file
cat .env.production | head -5

# 3. Test connection string
psql -c "SELECT 1" "$DATABASE_URL"

# 4. Check port
lsof -i :3000
```

### Database connection error
```bash
# Verify DATABASE_URL format
# postgresql://user:password@host:5432/database

# Test directly
psql "postgresql://user:password@host:5432/database" -c "SELECT 1"
```

### Migrations fail
```bash
# Check migration status
npx prisma migrate status

# Reset (careful!)
npx prisma migrate reset

# Run specific migration
npx prisma migrate deploy
```

### Port already in use
```bash
lsof -i :3000
kill -9 <PID>
```

---

## 📊 Monitoring Commands

```bash
# PM2 Status
pm2 status
pm2 logs traider-api
pm2 monit

# System Resources
top -p $(pgrep -f "node start-prod.js")
free -h
df -h

# Network
netstat -tlnp | grep 3000
curl -I https://yourdomain.com

# Database
psql traider_prod -c "SELECT count(*) FROM \"User\";"

# Logs
tail -100 logs/combined.log
grep ERROR logs/error.log
```

---

## 🔄 Rollback Procedure

Jika ada masalah:

```bash
# 1. Stop current version
pm2 stop traider-api

# 2. Revert code
git revert HEAD
git reset --hard <previous-commit-hash>

# 3. Rebuild
npm ci --omit=dev
npm run build

# 4. Run migrations (if needed)
npm run prisma:migrate:prod

# 5. Restart
pm2 start traider-api
pm2 logs traider-api
```

---

## 📅 Maintenance

### Weekly
- [ ] Review logs for errors
- [ ] Check disk space
- [ ] Verify backups completed
- [ ] Monitor uptime

### Monthly  
- [ ] Update dependencies: `npm audit fix`
- [ ] Review database size
- [ ] Test backup restore
- [ ] Check security updates

### Quarterly
- [ ] Full security audit
- [ ] Database optimization
- [ ] Load testing
- [ ] Disaster recovery drill

---

## 📞 Support & Documentation

- **Logs**: `/workspaces/TrAIder-API/logs/`
- **Docs**: See [DEPLOY-FIXED.md](DEPLOY-FIXED.md)
- **Status**: `pm2 status`
- **Health**: `curl http://localhost:3000/health`

---

## ✨ Success Indicators

✅ Server running without errors  
✅ All endpoints responding  
✅ Database connected successfully  
✅ Logs rotating properly  
✅ Backup configured  
✅ Monitoring active  
✅ Performance acceptable  
✅ Security configured  

**Deployment Complete! 🎉**
