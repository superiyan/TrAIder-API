#!/bin/bash

# SSL Certificate Setup with Let's Encrypt
# Installs and configures SSL for Nginx
# Usage: sudo bash setup-ssl.sh yourdomain.com your-email@example.com

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
    error "This script must be run as root. Use: sudo bash setup-ssl.sh yourdomain.com email@example.com"
fi

# Get arguments
DOMAIN=${1:-}
EMAIL=${2:-admin@example.com}

if [ -z "$DOMAIN" ]; then
    error "Usage: sudo bash setup-ssl.sh yourdomain.com your-email@example.com"
fi

info "=== Setting up SSL Certificate with Let's Encrypt ==="
echo

# Step 1: Install certbot
info "Step 1: Installing certbot and nginx plugin..."
apt-get update -qq
apt-get install -y certbot python3-certbot-nginx > /dev/null 2>&1
log "Certbot installed"

# Step 2: Verify Nginx is running
info "Step 2: Checking Nginx..."
if ! systemctl is-active --quiet nginx; then
    error "Nginx is not running. Start it first with: sudo systemctl start nginx"
fi
log "Nginx is running"

# Step 3: Create certbot webroot
info "Step 3: Creating webroot for certificate validation..."
mkdir -p /var/www/certbot
log "Webroot created"

# Step 4: Request certificate
info "Step 4: Requesting SSL certificate from Let's Encrypt..."
info "This may take a minute..."

certbot certonly \
    --agree-tos \
    --email "$EMAIL" \
    --no-eff-email \
    --webroot \
    -w /var/www/certbot \
    -d "$DOMAIN" \
    -d "www.$DOMAIN" \
    --staging

# Ask if production ready
echo
read -p "Did certificate generation succeed? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    warn "Certificate generation failed or not ready"
    echo "If there were validation errors, make sure:"
    echo "  1. Domain DNS points to this server"
    echo "  2. Port 80 is accessible from outside"
    echo "  3. Check logs: certbot logs"
    exit 1
fi

# Step 5: Update Nginx config with SSL paths
info "Step 5: Updating Nginx configuration with SSL certificate paths..."

sed -i "s|# ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;|ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;|g" /etc/nginx/sites-available/traider-api
sed -i "s|# ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;|ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;|g" /etc/nginx/sites-available/traider-api

log "Nginx configuration updated"

# Step 6: Test and reload Nginx
info "Step 6: Testing and reloading Nginx..."
if nginx -t > /dev/null 2>&1; then
    systemctl reload nginx
    log "Nginx reloaded successfully"
else
    error "Nginx configuration test failed"
fi

# Step 7: Setup auto-renewal
info "Step 7: Setting up automatic certificate renewal..."

# Create renewal hook
cat > /etc/letsencrypt/renewal-hooks/post/nginx-reload.sh << 'EOF'
#!/bin/bash
systemctl reload nginx
EOF

chmod +x /etc/letsencrypt/renewal-hooks/post/nginx-reload.sh

# Enable certbot timer
systemctl enable certbot.timer
systemctl start certbot.timer

log "Automatic renewal configured"

# Step 8: Verify SSL
info "Step 8: Verifying SSL certificate..."
sleep 2

if curl -s "https://$DOMAIN" > /dev/null 2>&1; then
    log "HTTPS is working! ✓"
else
    warn "Could not connect via HTTPS yet - may take a moment to propagate"
fi

echo
log "=== SSL Setup Complete! ==="
echo
echo "🔒 Certificate Information:"
echo "  Domain: $DOMAIN"
echo "  Certificate: /etc/letsencrypt/live/$DOMAIN/fullchain.pem"
echo "  Private Key: /etc/letsencrypt/live/$DOMAIN/privkey.pem"
echo "  Valid until: $(certbot certificates | grep -A2 "$DOMAIN" | grep expiration || echo "Check with: certbot certificates")"
echo
echo "✅ Verification:"
echo "  Test HTTPS: curl https://$DOMAIN"
echo "  Check cert: openssl s_client -connect $DOMAIN:443"
echo "  Browser: https://$DOMAIN"
echo
echo "🔄 Renewal:"
echo "  Auto-renewal is enabled"
echo "  Check status: sudo certbot renew --dry-run"
echo "  Manual renew: sudo certbot renew"
echo
echo "📊 Monitoring:"
echo "  View certificates: certbot certificates"
echo "  Logs: tail -f /var/log/letsencrypt/letsencrypt.log"
echo
