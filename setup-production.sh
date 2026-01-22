#!/bin/bash

# TrAIder API Production Setup Script
# Automated setup untuk VPS deployment
# Usage: bash setup-production.sh [domain-name] [email-for-ssl]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}✅${NC} $1"
}

warn() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

error() {
    echo -e "${RED}❌${NC} $1"
    exit 1
}

info() {
    echo -e "${BLUE}ℹ️${NC} $1"
}

# Check if running as root for system-wide installations
if [[ "$EUID" -ne 0 && "$1" != "--local" ]]; then
    warn "This script needs sudo for system installations"
    echo "Run with: sudo bash setup-production.sh [domain] [email]"
fi

info "=== TrAIder API Production Setup ==="
echo

# Arguments
DOMAIN=${1:-}
EMAIL=${2:-admin@example.com}

if [ -z "$DOMAIN" ]; then
    warn "Usage: sudo bash setup-production.sh yourdomain.com admin@yourdomain.com"
    warn "Continuing with localhost configuration..."
    DOMAIN="localhost"
fi

# Step 1: Check Node version
info "Checking Node.js version..."
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    error "Node.js 18+ required. Current: $(node -v)"
fi
log "Node.js $(node -v) ✓"

# Step 2: Install system dependencies
if [ "$EUID" -eq 0 ]; then
    info "Installing system dependencies..."
    apt-get update -qq
    apt-get install -y -qq postgresql redis-server nginx certbot python3-certbot-nginx > /dev/null 2>&1
    log "System dependencies installed"
fi

# Step 3: Setup Node modules
info "Installing Node.js dependencies..."
npm ci --omit=dev > /dev/null 2>&1
log "Dependencies installed"

# Step 4: Build application
info "Building TypeScript..."
npm run build
log "Build successful"

# Step 5: Setup .env.production
if [ ! -f ".env.production" ]; then
    warn ".env.production not found"
    info "Creating .env.production from example..."
    cp .env.example .env.production
    
    warn "⚠️  IMPORTANT: Edit .env.production with your actual values:"
    warn "  - DATABASE_URL"
    warn "  - JWT_SECRET (generate a random 32+ char string)"
    warn "  - CORS_ORIGIN (set to https://$DOMAIN)"
    
    echo "Press Enter to continue after editing .env.production..."
    read -r
fi

# Step 6: Database setup
info "Setting up PostgreSQL database..."

# Get database config from .env.production
DB_USER=$(grep "POSTGRES_USER=" .env.production | cut -d'=' -f2)
DB_PASS=$(grep "POSTGRES_PASSWORD=" .env.production | cut -d'=' -f2)
DB_NAME=$(grep "POSTGRES_DB=" .env.production | cut -d'=' -f2)

DB_USER=${DB_USER:-traider}
DB_PASS=${DB_PASS:-traider_password}
DB_NAME=${DB_NAME:-traider_prod}

if [ "$EUID" -eq 0 ]; then
    info "Creating database and user..."
    sudo -u postgres psql << EOF
CREATE USER "$DB_USER" WITH PASSWORD '$DB_PASS';
CREATE DATABASE "$DB_NAME" OWNER "$DB_USER";
GRANT ALL PRIVILEGES ON DATABASE "$DB_NAME" TO "$DB_USER";
EOF
    log "PostgreSQL configured"
else
    warn "Skipping PostgreSQL setup (requires sudo)"
    warn "Run manually:"
    warn "  sudo -u postgres psql"
    warn "  CREATE USER \"$DB_USER\" WITH PASSWORD '$DB_PASS';"
    warn "  CREATE DATABASE \"$DB_NAME\" OWNER \"$DB_USER\";"
fi

# Step 7: Run migrations
info "Running database migrations..."
npm run prisma:migrate:prod
log "Migrations completed"

# Step 8: Setup PM2 (if globally installed)
if command -v pm2 &> /dev/null; then
    info "Setting up PM2..."
    pm2 delete traider-api || true
    pm2 start start-prod.js --name "traider-api" --env production
    pm2 save
    if [ "$EUID" -eq 0 ]; then
        pm2 startup systemd -u $(whoami) --hp $(eval echo ~$(whoami))
    fi
    log "PM2 configured"
fi

# Step 9: Setup Nginx (if domain specified and root)
if [ "$DOMAIN" != "localhost" ] && [ "$EUID" -eq 0 ]; then
    info "Setting up Nginx reverse proxy..."
    
    # Create Nginx config
    cat > /etc/nginx/sites-available/traider-api << EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_buffering off;
    }
}
EOF
    
    # Enable site
    ln -sf /etc/nginx/sites-available/traider-api /etc/nginx/sites-enabled/
    
    # Test and reload
    nginx -t && systemctl reload nginx
    log "Nginx configured"
    
    # Setup SSL
    info "Setting up SSL certificate..."
    certbot --nginx -d $DOMAIN --email $EMAIL --non-interactive --agree-tos || true
    log "SSL setup completed"
fi

# Step 10: Verify
info "Verifying setup..."
sleep 3

if curl -s http://localhost:3000/health > /dev/null 2>&1; then
    log "Server is running and responding ✓"
    HEALTH=$(curl -s http://localhost:3000/health)
    echo "Response: $HEALTH"
else
    error "Server not responding. Check logs: pm2 logs traider-api"
fi

echo
log "=== Setup Complete! ==="
echo
echo "📋 Next steps:"
echo "  1. Review logs: pm2 logs traider-api"
echo "  2. Monitor: pm2 monit"
echo "  3. Access: https://$DOMAIN"
echo
echo "📚 Documentation:"
echo "  - Deployment: cat DEPLOY-FIXED.md"
echo "  - Monitoring: pm2 help"
echo "  - Logs: tail -f logs/combined.log"
echo
echo "🔒 Security reminders:"
echo "  - Never commit .env.production to git"
echo "  - Regularly backup database"
echo "  - Monitor logs for errors"
echo "  - Keep Node.js updated"
echo
