#!/bin/bash

# Monitoring and Backup Script for TrAIder API
# Monitors health, logs, and creates backups
# Usage: bash monitor-traider.sh [command]

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}✅${NC} $1"; }
warn() { echo -e "${YELLOW}⚠️${NC} $1"; }
error() { echo -e "${RED}❌${NC} $1"; }
info() { echo -e "${BLUE}ℹ️${NC} $1"; }
header() { echo -e "\n${MAGENTA}═══════════════════════════════════════${NC}"; echo -e "${MAGENTA}$1${NC}"; echo -e "${MAGENTA}═══════════════════════════════════════${NC}\n"; }

COMMAND=${1:-dashboard}

# Configuration
APP_NAME="traider-api"
PORT="3000"
DOMAIN="localhost"
BACKUP_DIR="/backup/traider"

# Function: Health Check
health_check() {
    header "🏥 HEALTH CHECK"
    
    # API Health
    info "Checking API health..."
    if curl -s "http://localhost:$PORT/health" > /dev/null 2>&1; then
        HEALTH=$(curl -s "http://localhost:$PORT/health")
        log "API is responding"
        echo "Response:"
        echo "$HEALTH" | jq . 2>/dev/null || echo "$HEALTH"
    else
        error "API not responding on port $PORT"
        return 1
    fi
    
    # Database Health
    info "Checking database connection..."
    if command -v psql &> /dev/null; then
        if PGPASSWORD="${DB_PASS}" psql -h "${DB_HOST:-localhost}" -U "${DB_USER:-traider_prod}" -d "${DB_NAME:-traider_prod}" -c "SELECT 1" > /dev/null 2>&1; then
            log "Database is responding"
        else
            error "Database connection failed"
        fi
    else
        warn "psql not available - skipping database check"
    fi
    
    echo
}

# Function: Process Status
process_status() {
    header "⚙️ PROCESS STATUS"
    
    # Check if PM2 is installed
    if ! command -v pm2 &> /dev/null; then
        warn "PM2 not installed"
        return
    fi
    
    # PM2 Status
    if pm2 describe "$APP_NAME" > /dev/null 2>&1; then
        pm2 describe "$APP_NAME" | grep -E "│ (pid|memory|cpu|status)" || true
        echo
        
        # Process uptime
        info "Recent restarts:"
        pm2 describe "$APP_NAME" | grep restart || true
    else
        warn "Application not running in PM2"
    fi
    
    # System processes
    info "Node.js processes:"
    ps aux | grep "node.*start-prod" | grep -v grep || warn "No Node.js processes found"
    
    echo
}

# Function: Resource Usage
resource_usage() {
    header "📊 RESOURCE USAGE"
    
    # Memory
    info "System Memory:"
    free -h | head -2
    echo
    
    # Disk
    info "Disk Usage:"
    df -h / | tail -1
    echo
    
    # Process resources
    info "Application Memory:"
    ps aux | grep "node.*start-prod" | grep -v grep | awk '{print "PID: "$2", Memory: "$6"KB, CPU: "$3"%"}' || warn "Application not running"
    
    # Logs size
    if [ -d "logs" ]; then
        info "Log Files Size:"
        du -sh logs/* 2>/dev/null || echo "  No logs yet"
    fi
    
    echo
}

# Function: Recent Logs
recent_logs() {
    header "📋 RECENT LOGS"
    
    if command -v pm2 &> /dev/null && pm2 describe "$APP_NAME" > /dev/null 2>&1; then
        info "PM2 Logs (last 20 lines):"
        pm2 logs "$APP_NAME" --lines 20 --nostream 2>/dev/null || echo "No logs available"
    fi
    
    if [ -f "logs/error.log" ]; then
        info "Error Log (last 10 lines):"
        tail -10 logs/error.log || echo "Empty"
    fi
    
    echo
}

# Function: Performance Metrics
performance_metrics() {
    header "⚡ PERFORMANCE METRICS"
    
    info "Response Time Test:"
    
    # Test health endpoint
    START=$(date +%s%N)
    curl -s "http://localhost:$PORT/health" > /dev/null 2>&1
    END=$(date +%s%N)
    
    DURATION=$((($END - $START) / 1000000))
    
    if [ "$DURATION" -lt 100 ]; then
        log "Health endpoint: ${DURATION}ms (Excellent)"
    elif [ "$DURATION" -lt 500 ]; then
        log "Health endpoint: ${DURATION}ms (Good)"
    elif [ "$DURATION" -lt 1000 ]; then
        warn "Health endpoint: ${DURATION}ms (Slow)"
    else
        error "Health endpoint: ${DURATION}ms (Very Slow)"
    fi
    
    echo
}

# Function: Port Status
port_status() {
    header "🔌 PORT STATUS"
    
    info "Checking port $PORT..."
    
    if lsof -i ":$PORT" > /dev/null 2>&1; then
        log "Port $PORT is in use"
        lsof -i ":$PORT" | tail -1
    else
        error "Port $PORT is not in use"
    fi
    
    # Check common ports
    info "Common ports:"
    echo "  Port 80 (HTTP):   $(lsof -i :80 > /dev/null 2>&1 && echo "✓ In use" || echo "✗ Not in use")"
    echo "  Port 443 (HTTPS): $(lsof -i :443 > /dev/null 2>&1 && echo "✓ In use" || echo "✗ Not in use")"
    echo "  Port 5432 (DB):   $(lsof -i :5432 > /dev/null 2>&1 && echo "✓ In use" || echo "✗ Not in use")"
    
    echo
}

# Function: Create Backup
create_backup() {
    header "💾 DATABASE BACKUP"
    
    if ! command -v pg_dump &> /dev/null; then
        error "pg_dump not found. Install PostgreSQL client."
        return 1
    fi
    
    mkdir -p "$BACKUP_DIR"
    
    DATE=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="$BACKUP_DIR/traider_prod_$DATE.sql.gz"
    
    info "Creating backup..."
    
    # Get DB URL from env
    if [ -f ".env.production" ]; then
        DB_URL=$(grep "DATABASE_URL=" .env.production | cut -d'=' -f2-)
        
        if pg_dump "$DB_URL" | gzip > "$BACKUP_FILE"; then
            FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
            log "Backup created: $BACKUP_FILE ($FILE_SIZE)"
            
            # Cleanup old backups (keep last 30 days)
            find "$BACKUP_DIR" -name "traider_prod_*.sql.gz" -mtime +30 -delete
            log "Old backups cleaned up (kept last 30 days)"
        else
            error "Backup failed"
            return 1
        fi
    else
        error ".env.production not found"
        return 1
    fi
    
    echo
}

# Function: Restart Application
restart_app() {
    header "🔄 RESTART APPLICATION"
    
    if ! command -v pm2 &> /dev/null; then
        error "PM2 not installed"
        return 1
    fi
    
    warn "Restarting application..."
    pm2 restart "$APP_NAME"
    
    sleep 3
    
    if pm2 describe "$APP_NAME" | grep -q "online"; then
        log "Application restarted successfully"
        health_check
    else
        error "Application failed to restart"
        pm2 logs "$APP_NAME" --lines 20 --nostream
    fi
    
    echo
}

# Function: Show Dashboard
dashboard() {
    clear
    
    header "🚀 TrAIder API - MONITORING DASHBOARD"
    
    health_check
    process_status
    port_status
    resource_usage
    performance_metrics
    
    echo
    echo "${CYAN}Timestamp: $(date)${NC}"
    echo "${CYAN}Commands: dashboard | health | status | resources | logs | metrics | ports | backup | restart${NC}"
    echo
}

# Function: Continuous Monitoring
monitor_continuous() {
    header "📡 CONTINUOUS MONITORING (Ctrl+C to exit)"
    
    while true; do
        clear
        echo "TrAIder API Continuous Monitor - Updated: $(date)"
        echo
        
        # Quick health check
        if curl -s "http://localhost:$PORT/health" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ API Online${NC}"
        else
            echo -e "${RED}✗ API Offline${NC}"
        fi
        
        # Memory
        MEMORY=$(ps aux | grep "node.*start-prod" | grep -v grep | awk '{print $6}' || echo "0")
        echo "Memory: ${MEMORY}KB"
        
        # CPU
        CPU=$(ps aux | grep "node.*start-prod" | grep -v grep | awk '{print $3}' || echo "0")
        echo "CPU: ${CPU}%"
        
        # Disk
        echo "Disk: $(df -h / | tail -1 | awk '{print $5}')"
        
        echo
        sleep 5
    done
}

# Execute command
case $COMMAND in
    health)
        health_check
        ;;
    status)
        process_status
        ;;
    resources)
        resource_usage
        ;;
    logs)
        recent_logs
        ;;
    metrics)
        performance_metrics
        ;;
    ports)
        port_status
        ;;
    backup)
        create_backup
        ;;
    restart)
        restart_app
        ;;
    monitor)
        monitor_continuous
        ;;
    dashboard)
        dashboard
        ;;
    *)
        echo "TrAIder API Monitoring Tool"
        echo
        echo "Usage: bash monitor-traider.sh [command]"
        echo
        echo "Commands:"
        echo "  dashboard - Show full monitoring dashboard (default)"
        echo "  health    - API & database health check"
        echo "  status    - Process and PM2 status"
        echo "  resources - Memory, CPU, disk usage"
        echo "  logs      - Recent logs"
        echo "  metrics   - Performance metrics"
        echo "  ports     - Port status"
        echo "  backup    - Create database backup"
        echo "  restart   - Restart application"
        echo "  monitor   - Continuous monitoring (updates every 5s)"
        echo
        ;;
esac
