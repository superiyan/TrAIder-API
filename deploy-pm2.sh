#!/bin/bash

# TrAIder API - PM2 Deployment Script
# Deploy and manage application with PM2
# Usage: bash deploy-pm2.sh [start|restart|stop|logs|status|delete]

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

# Configuration
APP_NAME="traider-api"
START_SCRIPT="start-prod.js"
LOG_FILE="logs/production.log"

# Get command
COMMAND=${1:-status}

# Verify environment
if [ ! -f ".env.production" ]; then
    error ".env.production not found. Please create it first."
fi

if [ ! -f "$START_SCRIPT" ]; then
    error "$START_SCRIPT not found. Run npm run build first."
fi

# Function to check PM2
check_pm2() {
    if ! command -v pm2 &> /dev/null; then
        warn "PM2 not found. Installing globally..."
        sudo npm install -g pm2
        log "PM2 installed"
    fi
}

# Function to check Node
check_node() {
    if ! command -v node &> /dev/null; then
        error "Node.js not found. Please install Node.js 20+"
    fi
    
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        error "Node.js 18+ required. Current: $(node -v)"
    fi
    log "Node.js $(node -v) ✓"
}

# Function to check database
check_database() {
    info "Checking database connection..."
    
    DB_URL=$(grep "DATABASE_URL=" .env.production | cut -d'=' -f2-)
    
    if [ -z "$DB_URL" ]; then
        error "DATABASE_URL not found in .env.production"
    fi
    
    # Test connection with psql if available
    if command -v psql &> /dev/null; then
        if PGPASSWORD="${DB_URL##*@}" psql "${DB_URL%%@*}" -c "SELECT 1" > /dev/null 2>&1; then
            log "Database connection OK"
        else
            warn "Could not verify database connection (psql test failed)"
            warn "Proceeding anyway - server will fail if DB is down"
        fi
    else
        warn "psql not available - skipping database check"
    fi
}

# Function to start application
start_app() {
    info "=== Starting TrAIder API with PM2 ==="
    
    check_pm2
    check_node
    check_database
    
    info "Building application..."
    npm run build || error "Build failed"
    log "Build successful"
    
    info "Running database migrations..."
    npm run prisma:migrate:prod || warn "Migrations may have failed"
    log "Migrations completed"
    
    info "Starting application..."
    
    # Delete old instance if exists
    pm2 delete "$APP_NAME" 2>/dev/null || true
    
    # Start with PM2
    pm2 start "$START_SCRIPT" \
        --name "$APP_NAME" \
        --env production \
        --instance_var INSTANCE_ID \
        --merge-logs \
        --no-daemon=false \
        --log "$LOG_FILE"
    
    pm2 save
    
    log "Application started with PM2"
    
    # Wait and check health
    info "Waiting for application to start..."
    sleep 3
    
    if pm2 describe "$APP_NAME" | grep -q "online"; then
        log "Application is running ✓"
    else
        error "Application failed to start. Check logs: pm2 logs $APP_NAME"
    fi
    
    # Test health endpoint
    info "Testing health endpoint..."
    sleep 2
    
    if curl -s http://localhost:3000/health > /dev/null 2>&1; then
        log "Health endpoint responding ✓"
        curl -s http://localhost:3000/health | jq .
    else
        warn "Health endpoint not responding yet - server may still be starting"
    fi
    
    echo
    log "=== Deployment Complete! ==="
    echo
    echo "📊 Useful commands:"
    echo "  pm2 status                 # Check status"
    echo "  pm2 logs traider-api       # View logs"
    echo "  pm2 monit                  # Monitor resources"
    echo "  pm2 restart traider-api    # Restart"
    echo "  pm2 stop traider-api       # Stop"
    echo "  curl http://localhost:3000/health # Health check"
}

# Function to restart application
restart_app() {
    info "Restarting application..."
    check_pm2
    
    if pm2 describe "$APP_NAME" > /dev/null 2>&1; then
        pm2 restart "$APP_NAME"
        log "Application restarted"
        sleep 2
        pm2 logs "$APP_NAME" --lines 20
    else
        error "Application not running. Use: bash deploy-pm2.sh start"
    fi
}

# Function to stop application
stop_app() {
    info "Stopping application..."
    check_pm2
    
    if pm2 describe "$APP_NAME" > /dev/null 2>&1; then
        pm2 stop "$APP_NAME"
        log "Application stopped"
    else
        warn "Application already stopped"
    fi
}

# Function to show status
show_status() {
    check_pm2
    
    if pm2 describe "$APP_NAME" > /dev/null 2>&1; then
        echo
        pm2 describe "$APP_NAME"
        echo
        echo "Recent logs:"
        pm2 logs "$APP_NAME" --lines 10 --nostream
    else
        warn "Application not running"
        echo "Start with: bash deploy-pm2.sh start"
    fi
}

# Function to show logs
show_logs() {
    check_pm2
    info "Showing real-time logs (Ctrl+C to exit)..."
    pm2 logs "$APP_NAME"
}

# Function to delete application
delete_app() {
    warn "This will stop and remove the application from PM2"
    read -p "Are you sure? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        check_pm2
        pm2 delete "$APP_NAME"
        log "Application removed from PM2"
    fi
}

# Execute command
case $COMMAND in
    start)
        start_app
        ;;
    restart)
        restart_app
        ;;
    stop)
        stop_app
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    delete)
        delete_app
        ;;
    *)
        echo "Usage: bash deploy-pm2.sh [command]"
        echo
        echo "Commands:"
        echo "  start     - Build, migrate, and start application"
        echo "  restart   - Restart running application"
        echo "  stop      - Stop application"
        echo "  status    - Show application status"
        echo "  logs      - View real-time logs"
        echo "  delete    - Remove application from PM2"
        echo
        show_status
        ;;
esac
