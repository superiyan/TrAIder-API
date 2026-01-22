# Quick Production Setup Guide

## 🚀 Fast Track Deployment (5 minutes)

### Step 1: Environment Setup
```bash
# Copy example env file
cp .env.example .env.production

# Edit with production values
nano .env.production
```

**Required values:**
```env
NODE_ENV=production
DATABASE_URL=postgresql://user:pass@host/db
JWT_SECRET=your-super-secret-key-min-32-chars
CORS_ORIGIN=https://yourdomain.com
```

### Step 2: Build
```bash
npm ci --omit=dev
npm run build
```

### Step 3: Database
```bash
export $(cat .env.production | xargs)
npx prisma migrate deploy
```

### Step 4: Start
```bash
# Option A: Using PM2 (Recommended for production)
npm install -g pm2
pm2 start ecosystem.config.js --env production
pm2 save

# Option B: Using npm
npm start

# Option C: Using Docker
docker-compose -f docker-compose.prod.yml up -d
```

### Step 5: Verify
```bash
curl http://localhost:3000/health
# Response: {"status":"OK","timestamp":"2026-01-22T..."}
```

---

## 📋 Important Checklist

| Item | Status | Notes |
|------|--------|-------|
| Environment variables set | ☐ | Use `.env.production` |
| Database is running | ☐ | PostgreSQL 16+ |
| Migrations applied | ☐ | `npx prisma migrate deploy` |
| Build succeeds | ☐ | `npm run build` |
| Health check passes | ☐ | `curl /health` |
| Logs are configured | ☐ | Check `/logs` directory |
| Rate limiting enabled | ☐ | Default: 100 req/15min |
| CORS configured | ☐ | Set specific origins |

---

## 🔧 Common Commands

```bash
# View logs
tail -f logs/combined.log

# PM2 management
pm2 status              # Check status
pm2 logs traider-api    # View real-time logs
pm2 restart traider-api # Restart app
pm2 stop traider-api    # Stop app

# Database
npx prisma studio      # Visual database explorer
npx prisma migrate status  # Check migration status

# Health & Status
curl http://localhost:3000/health
```

---

## 🚨 Troubleshooting

### Port Already in Use
```bash
lsof -i :3000
kill -9 <PID>
```

### Database Connection Error
```bash
# Test connection
psql $DATABASE_URL -c "SELECT 1"

# Check env variable
echo $DATABASE_URL
```

### Out of Memory
```bash
# Increase memory (for Node.js)
node --max-old-space-size=2048 dist/server.js
```

### Migrations Failed
```bash
# Rollback last migration
npx prisma migrate resolve --rolled-back <migration-name>

# See what's wrong
npx prisma migrate status
```

---

## 📊 Monitoring

### File-based Logs
- `logs/combined.log` - All logs
- `logs/error.log` - Errors only
- Logs rotate automatically

### Process Management
```bash
pm2 monit  # Real-time monitoring
pm2 web    # Web dashboard (port 9615)
```

### Health Check
```bash
curl -v http://localhost:3000/health

# Should return 200 OK
```

---

## 🔐 Security Reminders

⚠️ **BEFORE GOING TO PRODUCTION:**

1. ✅ JWT_SECRET is unique and strong (min 32 chars)
2. ✅ Database credentials are strong
3. ✅ CORS_ORIGIN is set to specific domains (NOT '*')
4. ✅ API keys are rotated and valid
5. ✅ SSL/TLS is configured
6. ✅ Secrets are NOT in git
7. ✅ Backups are scheduled
8. ✅ Logs don't contain sensitive data

---

## 📞 Support

For detailed information, see:
- [PRODUCTION.md](./PRODUCTION.md) - Comprehensive guide
- [DEPLOYMENT-CHECKLIST.md](./DEPLOYMENT-CHECKLIST.md) - Pre-deployment checklist
- [README.md](./README.md) - Project overview

---

**Last Updated**: January 22, 2026
**Version**: 1.0.0
