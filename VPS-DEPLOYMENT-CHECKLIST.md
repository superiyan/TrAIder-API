# 🖥️ VPS Production Deployment Checklist

Complete pre-deployment and post-deployment checklist untuk TrAIder API di production VPS.

## 📋 Table of Contents

1. [Pre-Deployment Requirements](#pre-deployment-requirements)
2. [Server Selection & Setup](#server-selection--setup)
3. [Security Hardening](#security-hardening)
4. [Application Deployment Steps](#application-deployment-steps)
5. [Post-Deployment Verification](#post-deployment-verification)
6. [Maintenance & Monitoring](#maintenance--monitoring)
7. [Emergency Procedures](#emergency-procedures)

---

## ✅ Pre-Deployment Requirements

### Domain & DNS
- [ ] Domain name purchased and registered
- [ ] Nameservers updated to VPS provider
- [ ] DNS A record pointing to VPS IP
  ```bash
  nslookup yourdomain.com
  # Should return VPS IP
  ```
- [ ] SSL certificate ready for HTTPS

### Credentials & Access
- [ ] SSH key pair generated (ED25519 recommended)
  ```bash
  ssh-keygen -t ed25519 -f ~/.ssh/traider-api -C "traider-api@production"
  ```
- [ ] SSH public key added to VPS authorized_keys
- [ ] Backup of private key stored securely
- [ ] SSH config entry created:
  ```bash
  cat >> ~/.ssh/config << 'EOF'
  Host traider-prod
    HostName your-vps-ip
    User deploy
    IdentityFile ~/.ssh/traider-api
    IdentitiesOnly yes
  EOF
  ```

### Environment Setup
- [ ] `.env.production` created with all required variables
- [ ] Sensitive values secured (passwords, API keys)
- [ ] File permissions secured (chmod 600)
- [ ] Backup of `.env.production` stored in secure location

---

## 🖥️ Server Selection & Setup

### Recommended VPS Specs

For production TrAIder API:

| Component | Minimum | Recommended | Large |
|-----------|---------|-------------|-------|
| CPU | 2 cores | 4 cores | 8+ cores |
| RAM | 2 GB | 4 GB | 8+ GB |
| Storage | 20 GB | 50 GB | 100+ GB |
| Bandwidth | 1 TB/mo | 5 TB/mo | Unlimited |
| Price | $5-10/mo | $15-25/mo | $50+/mo |

### Recommended Providers

1. **DigitalOcean** - Easiest for beginners, good performance
   ```bash
   # Create droplet: Ubuntu 24.04 LTS, 4GB RAM, $20/month
   # Select SSH key during setup
   ```

2. **Linode** - Great uptime, excellent support
3. **Vultr** - Good performance, affordable
4. **AWS EC2** - Enterprise grade, complex billing

### Initial Server Setup

```bash
#!/bin/bash
# Run this on your local machine to connect to VPS

# 1. Connect to VPS
ssh -i ~/.ssh/traider-api root@your-vps-ip

# 2. Create deploy user (run on VPS as root)
adduser deploy
addgroup deploy sudo
su - deploy

# 3. Setup SSH for deploy user
mkdir -p ~/.ssh
chmod 700 ~/.ssh
cat >> ~/.ssh/authorized_keys << 'EOF'
# Your SSH public key here
EOF
chmod 600 ~/.ssh/authorized_keys

# 4. Disable root login
sudo sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo service ssh reload
```

---

## 🔒 Security Hardening

### System Updates

```bash
#!/bin/bash
# scripts/harden-vps.sh

set -e

echo "🔒 Hardening VPS Security..."

# Update system
sudo apt update && sudo apt upgrade -y

# Install fail2ban (prevent brute force)
sudo apt install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Install UFW firewall
sudo apt install -y ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw allow 3000/tcp # App (behind proxy)
sudo ufw enable

# Disable unnecessary services
sudo systemctl disable bluetooth.service 2>/dev/null || true
sudo systemctl disable avahi-daemon.service 2>/dev/null || true

# Set timezone to UTC
sudo timedatectl set-timezone UTC

# Enable automatic security updates
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# Setup log rotation
sudo apt install -y logrotate

echo "✅ VPS hardening complete!"
```

### SSH Security

```bash
# Test SSH is working before making changes
ssh -i ~/.ssh/traider-api deploy@your-vps-ip "echo 'SSH Working!'"

# Configure SSH (as deploy user)
sudo sed -i 's/^#PermitEmptyPasswords no/PermitEmptyPasswords no/' /etc/ssh/sshd_config
sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl reload ssh
```

### Firewall Rules

```bash
# Configure UFW rules
sudo ufw allow from 127.0.0.1 to 127.0.0.1 port 5432  # PostgreSQL (local only)
sudo ufw allow from 127.0.0.1 to 127.0.0.1 port 6379  # Redis (local only)
sudo ufw allow rate 22/tcp                             # Rate limit SSH

# Check rules
sudo ufw status verbose
```

---

## 🚀 Application Deployment Steps

### Step 1: Clone Repository

```bash
ssh traider-prod << 'EOF'
mkdir -p /opt/traider-api
cd /opt/traider-api
git clone https://github.com/yourusername/TrAIder-API.git .
EOF
```

### Step 2: Install System Dependencies

```bash
ssh traider-prod << 'EOF'
set -e

# Update system
sudo apt update

# Install Node.js 20 LTS
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Install Nginx
sudo apt install -y nginx

# Install PM2 globally
sudo npm install -g pm2

# Install other tools
sudo apt install -y git curl wget htop net-tools

echo "✅ Dependencies installed!"
EOF
```

### Step 3: Configure Database

```bash
ssh traider-prod << 'EOF'
#!/bin/bash
set -e

# Run the database setup script
sudo bash /opt/traider-api/setup-postgres.sh

# Output will show DATABASE_URL - copy this!
EOF
```

### Step 4: Configure Application

```bash
ssh traider-prod << 'EOF'
cd /opt/traider-api

# Copy example .env
cp .env.production.example .env.production

# Edit .env.production with actual values
nano .env.production  # Or use your preferred editor

# Verify required variables
grep -E 'DATABASE_URL|JWT_SECRET|NODE_ENV|PORT' .env.production

# Install dependencies
npm ci --production

# Build application
npm run build

echo "✅ Application configured!"
EOF
```

### Step 5: Deploy Application

```bash
ssh traider-prod << 'EOF'
cd /opt/traider-api

# Run deployment script
bash ./deploy-pm2.sh

# Verify it's running
pm2 status traider-api
pm2 logs traider-api --lines 20

echo "✅ Application deployed!"
EOF
```

### Step 6: Setup Reverse Proxy (Nginx)

```bash
ssh traider-prod << 'EOF'
cd /opt/traider-api

# Run Nginx setup
sudo bash ./setup-nginx.sh

# Test Nginx configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx

echo "✅ Nginx configured!"
EOF
```

### Step 7: Setup SSL/HTTPS

```bash
ssh traider-prod << 'EOF'
cd /opt/traider-api

# Run SSL setup
sudo bash ./setup-ssl.sh

# Verify certificate
sudo certbot certificates

echo "✅ SSL certificate installed!"
EOF
```

---

## ✔️ Post-Deployment Verification

### Health Checks

```bash
#!/bin/bash
# Perform all health checks

echo "🏥 Running Post-Deployment Health Checks..."

# 1. Check application status
echo "1️⃣  Checking application..."
curl -s http://your-vps-ip:3000/health | jq '.'

# 2. Check HTTPS
echo "2️⃣  Checking HTTPS..."
curl -s https://yourdomain.com/health | jq '.'

# 3. Check Nginx is running
echo "3️⃣  Checking Nginx..."
ssh traider-prod "sudo systemctl status nginx"

# 4. Check PM2 is running
echo "4️⃣  Checking PM2..."
ssh traider-prod "pm2 status traider-api"

# 5. Check database connection
echo "5️⃣  Checking database..."
ssh traider-prod "psql $DATABASE_URL -c 'SELECT NOW();'"

# 6. Check firewall
echo "6️⃣  Checking firewall..."
ssh traider-prod "sudo ufw status"

# 7. Check disk space
echo "7️⃣  Checking disk space..."
ssh traider-prod "df -h /"

# 8. Check memory
echo "8️⃣  Checking memory..."
ssh traider-prod "free -h"

echo "✅ All checks complete!"
```

### Performance Baseline

```bash
# Establish performance baseline for monitoring
time curl https://yourdomain.com/health

# Should respond in < 100ms
```

---

## 🔧 Maintenance & Monitoring

### Daily Tasks

```bash
#!/bin/bash
# Daily maintenance checklist

echo "📋 Daily Maintenance Checklist"

# 1. Check application is running
pm2 status traider-api

# 2. Check error logs
pm2 logs traider-api --err | tail -20

# 3. Check disk usage
df -h / | tail -1

# 4. Check database size
psql $DATABASE_URL -c "SELECT pg_size_pretty(pg_database_size(current_database()));"

# 5. Check certificate expiration
openssl s_client -connect yourdomain.com:443 -showcerts 2>/dev/null | grep "notAfter"
```

### Weekly Tasks

```bash
#!/bin/bash
# Weekly maintenance

echo "📋 Weekly Maintenance"

# 1. System updates
sudo apt update && sudo apt upgrade -y

# 2. Database vacuum
psql $DATABASE_URL -c "VACUUM ANALYZE;"

# 3. Check backup status
ls -lh /var/lib/postgresql/backups/ | tail -10

# 4. Review logs for errors
journalctl -u traider-api -n 100 | grep -i error

# 5. Monitor performance metrics
pm2 monitoring
```

### Monthly Tasks

```bash
#!/bin/bash
# Monthly maintenance

echo "📋 Monthly Maintenance"

# 1. Full system backup
# (implement your backup strategy)

# 2. SSL certificate check
sudo certbot renew --dry-run

# 3. Database optimization
psql $DATABASE_URL << EOF
REINDEX DATABASE traider;
ANALYZE;
EOF

# 4. Review security logs
grep -i fail /var/log/auth.log | tail -20

# 5. Update PM2 ecosystem
pm2 save
pm2 startup
```

---

## 🚨 Emergency Procedures

### Application Down

```bash
#!/bin/bash
# Emergency restart

echo "🚨 EMERGENCY: Application Down"
echo "================================"

# 1. Check if process is running
pm2 status traider-api

# 2. Check logs for errors
pm2 logs traider-api --err

# 3. Check database connection
psql $DATABASE_URL -c "SELECT 1" || echo "❌ Database down!"

# 4. Restart application
pm2 restart traider-api

# 5. Wait for startup
sleep 5

# 6. Verify it's running
curl http://localhost:3000/health

# 7. Check Nginx is serving requests
curl https://yourdomain.com/health
```

### Database Issues

```bash
#!/bin/bash
# Database recovery

echo "🚨 EMERGENCY: Database Issues"

# 1. Check if PostgreSQL is running
sudo systemctl status postgresql

# 2. Restart PostgreSQL
sudo systemctl restart postgresql

# 3. Check connections
psql -U postgres -c "SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;"

# 4. Kill idle connections
psql -U postgres -c "SELECT pid, usename, application_name FROM pg_stat_activity WHERE state = 'idle';"

# 5. Force kill (if needed)
sudo systemctl restart postgresql
```

### Disk Space Critical

```bash
#!/bin/bash
# Disk space emergency

echo "🚨 EMERGENCY: Disk Space Critical"

# 1. Check disk usage
df -h

# 2. Find large files
sudo find / -type f -size +100M -exec ls -lh {} \;

# 3. Clean package manager cache
sudo apt clean
sudo apt autoclean

# 4. Clean logs (careful!)
sudo journalctl --vacuum=7d
sudo find /var/log -name "*.log" -mtime +30 -delete

# 5. Check what can be deleted
du -sh /opt/traider-api/*
du -sh /var/lib/postgresql/*

# 6. Stop app to free memory
pm2 stop traider-api

# 7. Restart
pm2 restart traider-api
```

### Rollback Deployment

```bash
#!/bin/bash
# Rollback to previous version

echo "⏮️  Rollback to Previous Version"

cd /opt/traider-api

# 1. Check git history
git log --oneline -10

# 2. Reset to previous commit
PREVIOUS_COMMIT=$(git rev-parse HEAD~1)
git reset --hard $PREVIOUS_COMMIT

# 3. Rebuild
npm ci --production
npm run build
npx prisma migrate deploy --skip-generate

# 4. Restart
pm2 restart traider-api

# 5. Verify
curl http://localhost:3000/health

echo "✅ Rollback complete!"
```

---

## 📋 Final Checklist

- [ ] Domain and DNS configured
- [ ] SSH access verified
- [ ] VPS hardened and secured
- [ ] Node.js and dependencies installed
- [ ] PostgreSQL database set up and backed up
- [ ] Application deployed with PM2
- [ ] Nginx reverse proxy configured
- [ ] SSL/HTTPS certificate installed
- [ ] Health endpoints responding
- [ ] Monitoring and alerts configured
- [ ] Automated backups running
- [ ] Documentation updated
- [ ] Team members notified
- [ ] 24/7 monitoring active

---

## 🆘 Support

If you encounter issues:

1. **Check logs first**
   ```bash
   pm2 logs traider-api
   sudo journalctl -u nginx -n 50
   ```

2. **Check system resources**
   ```bash
   free -h
   df -h
   top
   ```

3. **Test connectivity**
   ```bash
   curl http://localhost:3000/health
   curl https://yourdomain.com/health
   ```

4. **Review deployment script output**
   ```bash
   pm2 show traider-api
   ```

5. **Contact support** with:
   - Error message (from logs)
   - System info (free -h, df -h, uname -a)
   - Steps to reproduce
   - Any recent changes

---

**🎉 Congratulations! Your TrAIder API is now in production!**
