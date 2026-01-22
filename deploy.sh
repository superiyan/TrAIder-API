#!/bin/bash

# Production Deployment Script
# Usage: ./deploy.sh [production|staging|rollback]

set -e

ENVIRONMENT=${1:-production}
PROJECT_NAME="traider-api"
BRANCH=${CI_BRANCH:-main}

echo "🚀 Starting deployment for $ENVIRONMENT environment..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if we're on the right branch
if [ "$ENVIRONMENT" = "production" ] && [ "$BRANCH" != "main" ]; then
    error "Can only deploy to production from main branch. Current branch: $BRANCH"
fi

# Validation steps
log "📋 Running pre-deployment checks..."

# Check if required files exist
if [ ! -f ".env.production" ]; then
    error ".env.production file not found. Create it from .env.example"
fi

if [ ! -f "package.json" ]; then
    error "package.json not found"
fi

# Check Node version
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    error "Node.js 18+ required. Current version: $(node -v)"
fi

log "✅ Pre-deployment checks passed"

# Build steps
log "🔨 Building application..."
npm ci --omit=dev || error "Failed to install dependencies"
npm run build || error "Failed to build application"
log "✅ Build successful"

# Database migration
log "📦 Running database migrations..."
if [ "$ENVIRONMENT" = "production" ]; then
    export $(cat .env.production | grep DATABASE_URL | xargs)
    npx prisma migrate deploy || error "Failed to run migrations"
    log "✅ Migrations completed"
else
    warning "Skipping migrations for non-production environment"
fi

# Start application
log "🚀 Starting application..."

if command -v pm2 &> /dev/null; then
    log "Using PM2 to start application"
    pm2 delete $PROJECT_NAME || true
    pm2 start ecosystem.config.js --env $ENVIRONMENT
    pm2 save
    log "✅ Application started with PM2"
else
    warning "PM2 not found. Starting with npm..."
    npm start &
    log "✅ Application started"
fi

# Health check
log "🏥 Checking health..."
sleep 5

for i in {1..30}; do
    if curl -f http://localhost:3000/health > /dev/null 2>&1; then
        log "✅ Health check passed"
        break
    fi
    if [ $i -eq 30 ]; then
        error "Health check failed after 30 attempts"
    fi
    warning "Health check attempt $i/30 failed, retrying..."
    sleep 2
done

log "✅ Deployment completed successfully!"
echo ""
echo "📊 Application Info:"
echo "  Environment: $ENVIRONMENT"
echo "  URL: http://localhost:3000"
echo "  Health: http://localhost:3000/health"
echo "  API Docs: http://localhost:3000/api/v1/docs"
echo ""
echo "📝 View Logs:"
echo "  npm: tail -f logs/combined.log"
echo "  PM2: pm2 logs $PROJECT_NAME"
