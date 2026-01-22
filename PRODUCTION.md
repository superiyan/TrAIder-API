# Production Deployment Guide

## Pre-Deployment Checklist

- [ ] All environment variables configured in `.env.production`
- [ ] Database backups setup
- [ ] SSL/TLS certificates configured
- [ ] Rate limiting adjusted for production traffic
- [ ] Logging and monitoring enabled (Sentry, Datadog, etc.)
- [ ] Error tracking setup
- [ ] API keys and secrets rotated
- [ ] Database migrations tested
- [ ] Load testing completed
- [ ] Security audit performed

## Environment Setup

### 1. Create Production Environment File

```bash
cp .env.example .env.production
```

Edit `.env.production` and set production values:

```env
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://produser:strongpass@prod-db.example.com:5432/traider_prod
JWT_SECRET=generate-strong-random-secret-min-32-chars
CORS_ORIGIN=https://yourdomain.com,https://app.yourdomain.com
LOG_LEVEL=warn
```

### 2. Database Setup

```bash
# Run migrations
npm run prisma:migrate -- --name "production_init"

# Generate Prisma Client
npm run prisma:generate
```

### 3. Build Application

```bash
npm run build
```

### 4. Start Server

```bash
# Development
npm run dev

# Production
npm start

# With PM2 (recommended)
npm install -g pm2
pm2 start dist/server.js --name "traider-api"
pm2 save
```

## Docker Deployment

### Build Image

```bash
docker build -t traider-api:latest .
```

### Run with Docker Compose

```bash
docker-compose -f docker-compose.yml up -d
```

For production use `docker-compose.prod.yml`:

```bash
docker-compose -f docker-compose.prod.yml -p traider-prod up -d
```

## Monitoring & Logging

### Winston Logs

Logs are stored in `/logs` directory:

```
logs/
├── combined.log    # All logs
├── error.log       # Errors only
└── combined.*.log  # Rotated logs
```

### Health Check

```bash
curl http://localhost:3000/health
```

Response:
```json
{
  "status": "OK",
  "timestamp": "2026-01-22T10:00:00.000Z"
}
```

## Security Recommendations

### 1. API Key Management

- Use strong JWT_SECRET (min 32 characters)
- Rotate keys every 90 days
- Never commit secrets to git

### 2. Database Security

- Use SSL connections: `postgresql://...?ssl=require`
- Enable connection pooling
- Regular backups with retention

### 3. Rate Limiting

Current defaults:
- Window: 15 minutes (900,000 ms)
- Max requests: 100 per window

Adjust in `.env`:
```env
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
```

### 4. CORS Configuration

Set specific origins in production:
```env
CORS_ORIGIN=https://yourdomain.com,https://app.yourdomain.com
```

### 5. Helmet Security Headers

Already enabled with Helmet middleware. Headers include:
- X-Content-Type-Options
- X-Frame-Options
- Content-Security-Policy
- Strict-Transport-Security (HSTS)

## Performance Optimization

### 1. Database Connection Pool

```env
DATABASE_URL=postgresql://user:pass@host/db?connection_limit=10
```

### 2. Caching

Implement Redis caching:
```env
REDIS_URL=redis://cache.example.com:6379
```

### 3. API Response Compression

Already configured via Express middleware.

## Backup & Recovery

### Database Backup

```bash
# Manual backup
pg_dump postgres://user:pass@host/db > backup.sql

# Scheduled backup (crontab)
0 2 * * * pg_dump $DATABASE_URL > /backups/traider_$(date +\%Y\%m\%d).sql
```

### Restore from Backup

```bash
psql postgres://user:pass@host/db < backup.sql
```

## Scaling

### Horizontal Scaling

Deploy multiple instances behind a load balancer:

```
Load Balancer
    ↓
  ┌─┴─┐
  │   │
Instance 1  Instance 2  Instance 3
  │   │        │
  └─┬─┘────────┘
    │
PostgreSQL (Shared)
```

### Recommended Services

- **Load Balancer**: Nginx, HAProxy, AWS ALB
- **Database**: Managed PostgreSQL (AWS RDS, GCP Cloud SQL, Azure Database)
- **Cache**: Redis on AWS ElastiCache or similar
- **Monitoring**: Datadog, New Relic, Prometheus

## Troubleshooting

### Port Already in Use

```bash
lsof -i :3000
kill -9 <PID>
```

### Database Connection Error

```bash
# Check connection string
echo $DATABASE_URL

# Test connection
psql $DATABASE_URL -c "SELECT 1"
```

### High Memory Usage

- Check for memory leaks with: `node --expose-gc dist/server.js`
- Monitor with: `pm2 monit`
- Use: `node --max-old-space-size=2048 dist/server.js`

## CI/CD Pipeline

Example GitHub Actions workflow in `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '20'
      - run: npm ci
      - run: npm run build
      - run: npm test
      - name: Deploy to Server
        run: |
          ssh user@prod-server.com "cd /app && git pull && npm ci && npm run build && pm2 restart traider-api"
```

## Support & Emergency

### Enable Debug Mode

```env
LOG_LEVEL=debug
NODE_ENV=development
```

### Check Server Status

```bash
pm2 status
pm2 logs traider-api
```

### Rollback Procedure

```bash
git revert <commit-hash>
npm run build
pm2 restart traider-api
```

---

**Last Updated**: January 22, 2026
**Version**: 1.0.0
