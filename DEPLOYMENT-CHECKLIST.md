# Production Deployment Checklist

## Pre-Deployment

### Security
- [ ] JWT_SECRET is strong (min 32 chars, alphanumeric + special chars)
- [ ] Database password is strong and unique
- [ ] All API keys are rotated and valid
- [ ] CORS_ORIGIN is set to specific domains (not '*' in production)
- [ ] SSL/TLS certificates are valid and not expired
- [ ] Sensitive data is not committed to git

### Configuration
- [ ] `.env.production` is created and filled with correct values
- [ ] Database connection string is correct
- [ ] Log level is set to 'warn' or 'error'
- [ ] Rate limiting is configured appropriately
- [ ] Port is not blocked by firewall

### Database
- [ ] PostgreSQL is running and accessible
- [ ] Database user has limited permissions (not superuser)
- [ ] Backups are scheduled and tested
- [ ] Backup storage is encrypted and redundant
- [ ] Connection pooling is configured
- [ ] Database indices are optimized

### Code Quality
- [ ] All tests pass: `npm test`
- [ ] Build succeeds: `npm run build`
- [ ] No console.log statements in production code
- [ ] Error handling covers edge cases
- [ ] API response formats are consistent

### Infrastructure
- [ ] Server has sufficient CPU (2+ cores recommended)
- [ ] Server has sufficient RAM (2+ GB recommended)
- [ ] Server has sufficient disk space (10+ GB recommended)
- [ ] Network latency to database is acceptable (<50ms)
- [ ] Backup and recovery procedure is documented

### Monitoring & Logging
- [ ] Winston logging is configured
- [ ] Log rotation is setup
- [ ] Error tracking (Sentry) is configured
- [ ] Monitoring alerts are setup
- [ ] Health check endpoint is accessible

## Deployment Steps

### 1. Build Application
```bash
npm ci
npm run build
```

### 2. Database Migration
```bash
DATABASE_URL=<prod-url> npx prisma migrate deploy
npx prisma generate
```

### 3. Start with PM2
```bash
pm2 start ecosystem.config.js --env production
pm2 save
pm2 startup
```

Or use Docker:
```bash
docker-compose -f docker-compose.prod.yml up -d
```

### 4. Verify Deployment
- [ ] Health check returns 200: `curl http://localhost:3000/health`
- [ ] API endpoints are responsive
- [ ] Database queries work correctly
- [ ] Logs show no errors

## Post-Deployment

### Monitoring
- [ ] Server CPU usage is normal (<80%)
- [ ] Server memory usage is normal (<80%)
- [ ] Response times are acceptable (<500ms p95)
- [ ] Error rate is low (<1%)
- [ ] Database connections are stable

### Validation
- [ ] Auth flow works (login/signup)
- [ ] Market data endpoints respond correctly
- [ ] Trading operations execute properly
- [ ] WebSocket connections (if any) are stable
- [ ] External API integrations work

### Cleanup
- [ ] Old logs are archived
- [ ] Temporary files are cleaned up
- [ ] Development dependencies are not installed
- [ ] Build artifacts are removed from deployment

## Rollback Procedure

If issues occur:

```bash
# Stop current version
pm2 stop traider-api
pm2 delete traider-api

# Rollback code
git revert <commit-hash>
npm run build

# Revert database (if migrations were run)
npx prisma migrate resolve --rolled-back <migration-name>

# Restart
pm2 start ecosystem.config.js --env production
```

## Emergency Contacts

- [ ] On-call engineer is assigned
- [ ] Escalation path is documented
- [ ] Status page is updated (if applicable)
- [ ] Stakeholders are notified

## Post-Incident

- [ ] Root cause analysis is performed
- [ ] Fix is tested and deployed
- [ ] Monitoring alert is created
- [ ] Documentation is updated
- [ ] Team is debriefed

---

**Deployment Date**: ___________
**Deployed By**: ___________
**Approved By**: ___________
