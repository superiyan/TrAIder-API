# 🏥 Health Monitoring & Alerting Setup

Complete guide untuk setup monitoring dan alerting untuk TrAIder API production environment.

## 📋 Table of Contents

1. [Quick Setup (5 min)](#quick-setup)
2. [Monitoring Options](#monitoring-options)
3. [Health Endpoints](#health-endpoints)
4. [Alert Configuration](#alert-configuration)
5. [Grafana Dashboard](#grafana-dashboard)
6. [Troubleshooting](#troubleshooting)

---

## 🚀 Quick Setup

### Option A: Using PM2 Monitoring (Simplest)

**1. Install PM2 Plus (Free tier available)**

```bash
# On production server
npm install -g pm2
pm2 install pm2-auto-pull  # Auto-update on git changes
pm2 install pm2-logrotate  # Rotate logs automatically

# Link to PM2 Plus (optional)
pm2 link <secret_key> <public_key>
```

**2. Update PM2 ecosystem config**

```bash
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'traider-api',
    script: 'dist/server.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    // Monitoring
    max_memory_restart: '1G',
    watch: false,
    ignore_watch: ['node_modules', 'logs'],
    error_file: './logs/pm2-error.log',
    out_file: './logs/pm2-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    
    // Auto-restart
    autorestart: true,
    max_restarts: 10,
    min_uptime: '10s',
    
    // Health check
    listen_timeout: 5000,
    kill_timeout: 5000
  }]
};
EOF

# Restart with new config
pm2 start ecosystem.config.js --only traider-api
```

**3. View monitoring dashboard**

```bash
# Real-time dashboard
pm2 monit

# Web dashboard (localhost:9615)
pm2 web

# Status check
pm2 status
pm2 logs traider-api
```

---

### Option B: Using Prometheus + Grafana (Professional)

#### Step 1: Install Prometheus

```bash
# On monitoring server
wget https://github.com/prometheus/prometheus/releases/download/v2.48.0/prometheus-2.48.0.linux-amd64.tar.gz
tar xvfz prometheus-2.48.0.linux-amd64.tar.gz
cd prometheus-2.48.0.linux-amd64

# Create config
cat > prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'traider-api'
    static_configs:
      - targets: ['your-server-ip:3000']
    metrics_path: '/metrics'
    scrape_interval: 10s
    
  - job_name: 'node'
    static_configs:
      - targets: ['your-server-ip:9100']

  - job_name: 'postgres'
    static_configs:
      - targets: ['your-server-ip:9187']
EOF

# Start Prometheus
./prometheus --config.file=prometheus.yml
```

#### Step 2: Add metrics endpoint to API

```typescript
// src/routes/metrics.routes.ts
import express from 'express';
import prometheus from 'prom-client';

const router = express.Router();

// Default metrics (CPU, memory, etc)
prometheus.collectDefaultMetrics();

// Custom metrics
const httpRequestDuration = new prometheus.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.5, 1, 2, 5]
});

const httpRequestTotal = new prometheus.Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

const databaseConnectionPoolSize = new prometheus.Gauge({
  name: 'database_connection_pool_size',
  help: 'Size of database connection pool',
  labelNames: ['pool_name']
});

// Middleware to track metrics
export const metricsMiddleware = (req: any, res: any, next: any) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    httpRequestDuration
      .labels(req.method, req.route?.path || req.path, res.statusCode)
      .observe(duration);
    httpRequestTotal
      .labels(req.method, req.route?.path || req.path, res.statusCode)
      .inc();
  });
  next();
};

// Metrics endpoint
router.get('/metrics', async (req, res) => {
  res.set('Content-Type', prometheus.register.contentType);
  res.end(await prometheus.register.metrics());
});

export default router;
```

#### Step 3: Install Grafana

```bash
# On monitoring server
sudo apt-get install -y adduser libfontconfig1 musl
wget https://dl.grafana.com/oss/release/grafana_10.2.2_amd64.deb
sudo dpkg -i grafana_10.2.2_amd64.deb
sudo systemctl start grafana-server
sudo systemctl enable grafana-server

# Access at http://localhost:3000 (default: admin/admin)
```

---

## 🏥 Health Endpoints

### 1. Basic Health Check (Already implemented)

```bash
curl http://localhost:3000/health
# Response: {"status":"OK","timestamp":"2026-01-22T..."}
```

### 2. Detailed Health Check (Add this)

```typescript
// src/routes/health.routes.ts
import express, { Router } from 'express';
import { prisma } from '../config/database';

const router: Router = express.Router();

interface HealthStatus {
  status: 'OK' | 'DEGRADED' | 'DOWN';
  timestamp: string;
  uptime: number;
  database: {
    status: 'OK' | 'DOWN';
    responseTime: number;
  };
  memory: {
    used: number;
    total: number;
    percentage: number;
  };
  services: {
    api: 'OK' | 'DOWN';
    jwt: 'OK' | 'DOWN';
    rateLimit: 'OK' | 'DOWN';
  };
}

router.get('/health/detailed', async (req, res) => {
  const healthStatus: HealthStatus = {
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    database: { status: 'OK', responseTime: 0 },
    memory: {
      used: process.memoryUsage().heapUsed,
      total: process.memoryUsage().heapTotal,
      percentage: (process.memoryUsage().heapUsed / process.memoryUsage().heapTotal) * 100
    },
    services: {
      api: 'OK',
      jwt: 'OK',
      rateLimit: 'OK'
    }
  };

  // Check database
  const start = Date.now();
  try {
    await prisma.$queryRaw`SELECT 1`;
    healthStatus.database.responseTime = Date.now() - start;
  } catch (error) {
    healthStatus.database.status = 'DOWN';
    healthStatus.status = 'DEGRADED';
  }

  // Check memory
  if (healthStatus.memory.percentage > 90) {
    healthStatus.status = 'DEGRADED';
  }

  res.status(healthStatus.status === 'OK' ? 200 : 503).json(healthStatus);
});

export default router;
```

---

## 📢 Alert Configuration

### Slack Integration

```bash
# 1. Create Slack webhook
# Go to: https://api.slack.com/apps → Create New App
# Features > Incoming Webhooks → Add New Webhook to Workspace
# Copy the Webhook URL

# 2. Add to environment variables
echo "SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL" >> .env.production

# 3. Create alert service
```

```typescript
// src/services/alerts.service.ts
import axios from 'axios';

interface Alert {
  severity: 'critical' | 'warning' | 'info';
  title: string;
  message: string;
  metadata?: Record<string, any>;
}

export class AlertService {
  private webhookUrl = process.env.SLACK_WEBHOOK_URL;

  async sendSlackAlert(alert: Alert) {
    if (!this.webhookUrl) return;

    const color = {
      critical: '#FF0000',
      warning: '#FFA500',
      info: '#0099FF'
    }[alert.severity];

    try {
      await axios.post(this.webhookUrl, {
        attachments: [{
          color,
          title: `[${alert.severity.toUpperCase()}] ${alert.title}`,
          text: alert.message,
          fields: Object.entries(alert.metadata || {}).map(([key, value]) => ({
            title: key,
            value: String(value),
            short: true
          })),
          ts: Math.floor(Date.now() / 1000)
        }]
      });
    } catch (error) {
      console.error('Failed to send Slack alert:', error);
    }
  }
}
```

### Email Alerts (Using SendGrid)

```bash
npm install @sendgrid/mail
```

```typescript
// src/services/email-alerts.service.ts
import sgMail from '@sendgrid/mail';

sgMail.setApiKey(process.env.SENDGRID_API_KEY!);

export class EmailAlertService {
  static async sendAlert(alert: Alert) {
    await sgMail.send({
      to: process.env.ALERT_EMAIL!,
      from: 'alerts@traider-api.com',
      subject: `[${alert.severity.toUpperCase()}] ${alert.title}`,
      html: `
        <h2>${alert.title}</h2>
        <p>${alert.message}</p>
        <p>Severity: <strong>${alert.severity}</strong></p>
        <p>Time: ${new Date().toISOString()}</p>
      `
    });
  }
}
```

---

## 📊 Grafana Dashboard

### Pre-built Dashboard JSON

```json
{
  "dashboard": {
    "title": "TrAIder API Production",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [{
          "expr": "rate(http_requests_total[5m])"
        }]
      },
      {
        "title": "Response Time (p95)",
        "targets": [{
          "expr": "histogram_quantile(0.95, http_request_duration_seconds_bucket)"
        }]
      },
      {
        "title": "Error Rate",
        "targets": [{
          "expr": "rate(http_requests_total{status_code=~\"5..\"}[5m])"
        }]
      },
      {
        "title": "Database Connections",
        "targets": [{
          "expr": "database_connection_pool_size"
        }]
      },
      {
        "title": "Memory Usage",
        "targets": [{
          "expr": "process_resident_memory_bytes / 1024 / 1024"
        }]
      },
      {
        "title": "CPU Usage",
        "targets": [{
          "expr": "100 - (avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)"
        }]
      }
    ]
  }
}
```

---

## 🔧 Continuous Monitoring Script

```bash
#!/bin/bash
# scripts/monitor-continuous.sh

set -e

echo "🏥 TrAIder API - Continuous Health Monitoring"
echo "=============================================="

HEALTH_URL="http://localhost:3000/health"
DETAILED_URL="http://localhost:3000/health/detailed"
ALERT_THRESHOLD_MEMORY=85
ALERT_THRESHOLD_RESPONSE=1000

while true; do
  # Basic health check
  if curl -s "$HEALTH_URL" > /dev/null 2>&1; then
    echo "✅ $(date '+%Y-%m-%d %H:%M:%S') - API is healthy"
  else
    echo "❌ $(date '+%Y-%m-%d %H:%M:%S') - API is down!"
    # Send alert
  fi

  # Detailed checks
  HEALTH=$(curl -s "$DETAILED_URL")
  MEMORY=$(echo "$HEALTH" | jq '.memory.percentage')
  DB_TIME=$(echo "$HEALTH" | jq '.database.responseTime')

  if (( $(echo "$MEMORY > $ALERT_THRESHOLD_MEMORY" | bc -l) )); then
    echo "⚠️  High memory usage: ${MEMORY}%"
  fi

  if (( $(echo "$DB_TIME > $ALERT_THRESHOLD_RESPONSE" | bc -l) )); then
    echo "⚠️  Slow database response: ${DB_TIME}ms"
  fi

  sleep 60
done
```

---

## 🐛 Troubleshooting

### Monitoring Not Working?

```bash
# Check if health endpoint is accessible
curl -v http://localhost:3000/health

# Check logs
pm2 logs traider-api

# Check port is open
netstat -tlnp | grep 3000

# Check firewall
sudo ufw status
sudo ufw allow 3000/tcp
```

### Prometheus Not Scraping Metrics?

```bash
# Check Prometheus config
curl http://localhost:9090/api/v1/targets

# Check if metrics endpoint is accessible
curl http://your-server-ip:3000/metrics

# Check Prometheus logs
tail -f /var/log/prometheus/prometheus.log
```

### Grafana Dashboard Not Updating?

```bash
# Verify Prometheus is connected as data source
# Go to: http://localhost:3000/datasources

# Check scrape interval in prometheus.yml
# Default is 15s, metrics query needs 5+ minutes of data

# Force Prometheus to scrape
curl -X POST http://localhost:9090/-/reload
```

---

## 📋 Monitoring Checklist

- [ ] Health endpoints implemented and tested
- [ ] PM2 monitoring configured
- [ ] Prometheus installed and configured
- [ ] Grafana dashboards created
- [ ] Slack/Email alerts configured
- [ ] Alert thresholds set
- [ ] Continuous monitoring script running
- [ ] Log rotation configured
- [ ] Database query monitoring active
- [ ] Performance baselines established

---

## 🔗 Resources

- [PM2 Documentation](https://pm2.keymetrics.io/)
- [Prometheus Guide](https://prometheus.io/docs/prometheus/latest/)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)
- [Slack API](https://api.slack.com/)
- [Node.js Metrics](https://nodejs.org/en/docs/guides/nodejs-performance-monitoring/)
