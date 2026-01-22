#!/bin/bash

# Nginx Configuration Generator for TrAIder API
# Generates proper reverse proxy config
# Usage: bash setup-nginx.sh yourdomain.com

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}✅${NC} $1"; }
warn() { echo -e "${YELLOW}⚠️${NC} $1"; }
error() { echo -e "${RED}❌${NC} $1"; exit 1; }
info() { echo -e "${BLUE}ℹ️${NC} $1"; }

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    error "This script must be run as root. Use: sudo bash setup-nginx.sh yourdomain.com"
fi

# Get domain from argument
DOMAIN=${1:-}

if [ -z "$DOMAIN" ]; then
    error "Usage: sudo bash setup-nginx.sh yourdomain.com"
fi

info "=== Setting up Nginx Reverse Proxy ==="
echo

# Step 1: Install Nginx
info "Step 1: Installing Nginx..."
apt-get update -qq
apt-get install -y nginx > /dev/null 2>&1
log "Nginx installed"

# Step 2: Create Nginx configuration
info "Step 2: Creating Nginx configuration for $DOMAIN..."

cat > /etc/nginx/sites-available/traider-api << EOF
# TrAIder API Reverse Proxy
# Proxies requests from Nginx to Node.js app running on port 3000

# Rate limiting zone
limit_req_zone \$binary_remote_addr zone=api_limit:10m rate=100r/m;
limit_req_zone \$binary_remote_addr zone=general_limit:10m rate=1000r/m;

# Upstream backend server
upstream traider_backend {
    least_conn;
    server localhost:3000 max_fails=3 fail_timeout=30s;
    keepalive 32;
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN www.$DOMAIN;

    # Let's Encrypt validation
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    # Redirect all to HTTPS
    location / {
        return 301 https://\$host\$request_uri;
    }
}

# Main HTTPS server
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;

    # SSL Configuration (will be added by certbot)
    # ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    # SSL Security settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # HSTS (HTTP Strict Transport Security)
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Logging
    access_log /var/log/nginx/traider-api_access.log combined;
    error_log /var/log/nginx/traider-api_error.log warn;

    # Increase max body size for uploads
    client_max_body_size 10M;

    # Compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss;

    # Root location
    root /var/www/html;

    # Health check (internal)
    location /health {
        limit_req zone=general_limit burst=20 nodelay;
        
        proxy_pass http://trailer_backend;
        proxy_http_version 1.1;
        
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        proxy_connect_timeout 5s;
        proxy_send_timeout 10s;
        proxy_read_timeout 10s;
    }

    # API endpoints with rate limiting
    location /api/ {
        limit_req zone=api_limit burst=10 nodelay;

        proxy_pass http://traider_backend;
        proxy_http_version 1.1;
        
        # Proxy headers
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$server_name;
        proxy_set_header X-Forwarded-Port \$server_port;
        
        # WebSocket support
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffering
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;
    }

    # Catch all remaining locations
    location / {
        limit_req zone=general_limit burst=20 nodelay;
        
        proxy_pass http://traider_backend;
        proxy_http_version 1.1;
        
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        proxy_connect_timeout 30s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF

log "Nginx configuration created"

# Step 3: Enable site
info "Step 3: Enabling site..."
if [ -L /etc/nginx/sites-enabled/traider-api ]; then
    rm /etc/nginx/sites-enabled/traider-api
fi
ln -s /etc/nginx/sites-available/traider-api /etc/nginx/sites-enabled/traider-api
log "Site enabled"

# Step 4: Disable default site
info "Step 4: Disabling default site..."
if [ -L /etc/nginx/sites-enabled/default ]; then
    rm /etc/nginx/sites-enabled/default
fi
log "Default site disabled"

# Step 5: Test Nginx config
info "Step 5: Testing Nginx configuration..."
if nginx -t > /dev/null 2>&1; then
    log "Nginx configuration is valid"
else
    error "Nginx configuration test failed"
fi

# Step 6: Start Nginx
info "Step 6: Starting Nginx..."
systemctl restart nginx
systemctl enable nginx
log "Nginx restarted and enabled"

echo
log "=== Nginx Setup Complete! ==="
echo
echo "📋 Next steps:"
echo
echo "1. Setup SSL Certificate with Let's Encrypt:"
echo "   sudo apt install certbot python3-certbot-nginx -y"
echo "   sudo certbot --nginx -d $DOMAIN"
echo
echo "2. Test your setup:"
echo "   curl -I https://$DOMAIN"
echo "   curl https://$DOMAIN/health | jq"
echo
echo "3. View logs:"
echo "   tail -f /var/log/nginx/traider-api_access.log"
echo "   tail -f /var/log/nginx/traider-api_error.log"
echo
echo "4. Verify configuration:"
echo "   nginx -t"
echo "   systemctl status nginx"
echo
