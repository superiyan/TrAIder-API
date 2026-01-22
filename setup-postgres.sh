#!/bin/bash

# PostgreSQL Production Database Setup
# Untuk Ubuntu/Debian servers
# Usage: sudo bash setup-postgres.sh

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
    error "This script must be run as root. Use: sudo bash setup-postgres.sh"
fi

info "=== PostgreSQL 16 Production Setup ==="
echo

# Step 1: Install PostgreSQL
info "Step 1: Installing PostgreSQL 16..."
apt-get update -qq
apt-get install -y postgresql postgresql-contrib postgresql-16 > /dev/null 2>&1
log "PostgreSQL installed"

# Step 2: Start service
info "Step 2: Starting PostgreSQL service..."
systemctl start postgresql
systemctl enable postgresql
log "PostgreSQL service enabled"

# Step 3: Check status
info "Step 3: Checking PostgreSQL status..."
if systemctl is-active --quiet postgresql; then
    log "PostgreSQL is running"
else
    error "PostgreSQL failed to start"
fi

# Step 4: Create production user and database
info "Step 4: Setting up production database..."

# Generate strong password
DB_PASSWORD=$(openssl rand -base64 32)
DB_USER="traider_prod"
DB_NAME="traider_prod"

# Create user and database
sudo -u postgres psql << EOF
-- Create user with password
CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';

-- Create database
CREATE DATABASE $DB_NAME OWNER $DB_USER;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;

-- Optional: Grant additional privileges
ALTER DATABASE $DB_NAME OWNER TO $DB_USER;
EOF

log "Database created: $DB_NAME"
log "User created: $DB_USER"

# Step 5: Create backup user (for automated backups)
info "Step 5: Creating backup user..."
sudo -u postgres psql << EOF
CREATE USER traider_backup WITH PASSWORD '$(openssl rand -base64 24)';
GRANT CONNECT ON DATABASE $DB_NAME TO traider_backup;
GRANT USAGE ON SCHEMA public TO traider_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO traider_backup;
EOF
log "Backup user created"

# Step 6: Optimize PostgreSQL
info "Step 6: Optimizing PostgreSQL configuration..."

# Backup original config
cp /etc/postgresql/16/main/postgresql.conf /etc/postgresql/16/main/postgresql.conf.bak

# Optimize for production
cat >> /etc/postgresql/16/main/postgresql.conf << 'EOF'

# === Production Optimizations ===
# Increase shared buffers (25% of RAM for dedicated server)
shared_buffers = 256MB

# Effective cache size (50-75% of RAM)
effective_cache_size = 1GB

# Work memory for queries
work_mem = 8MB

# Maintenance work memory
maintenance_work_mem = 64MB

# WAL configuration
max_wal_size = 2GB
min_wal_size = 1GB

# Connection settings
max_connections = 200

# Logging
logging_collector = on
log_directory = 'pg_log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_statement = 'mod'
log_duration = off
log_min_duration_statement = 1000

# Replication (if needed later)
wal_level = replica
max_wal_senders = 3
EOF

systemctl restart postgresql
log "PostgreSQL optimized and restarted"

# Step 7: Configure pg_hba for secure access
info "Step 7: Configuring access control..."
cat > /etc/postgresql/16/main/pg_hba.conf << 'EOF'
# Local connections
local   all             all                                     trust
host    all             all             127.0.0.1/32            md5
host    all             all             ::1/128                 md5

# Remote connections (secured)
# Uncomment and modify IP if needed for remote access
# host    all             all             192.168.1.0/24         md5

# Replication
host    replication     all             127.0.0.1/32            md5
host    replication     all             ::1/128                 md5
EOF

systemctl restart postgresql
log "Access control configured"

# Step 8: Test connection
info "Step 8: Testing database connection..."
PGPASSWORD="$DB_PASSWORD" psql -h localhost -U $DB_USER -d $DB_NAME -c "SELECT 1" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    log "Database connection successful"
else
    error "Database connection failed"
fi

# Step 9: Create backup directory
info "Step 9: Setting up backup directory..."
mkdir -p /backup/postgres
chown postgres:postgres /backup/postgres
chmod 700 /backup/postgres
log "Backup directory created: /backup/postgres"

# Step 10: Create backup script
info "Step 10: Creating backup script..."
cat > /usr/local/bin/backup-traider-db.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/backup/postgres"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/traider_prod_$DATE.sql.gz"

# Backup database
pg_dump -U traider_prod -h localhost traider_prod | gzip > "$BACKUP_FILE"

# Keep last 30 days
find $BACKUP_DIR -name "traider_prod_*.sql.gz" -mtime +30 -delete

echo "Backup created: $BACKUP_FILE"
EOF

chmod +x /usr/local/bin/backup-traider-db.sh
log "Backup script created: /usr/local/bin/backup-traider-db.sh"

# Step 11: Setup automated backup cron
info "Step 11: Setting up automated backups..."
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/backup-traider-db.sh") | crontab -
log "Daily backup scheduled at 2:00 AM"

echo
echo "=========================================="
log "=== PostgreSQL Setup Complete! ==="
echo "=========================================="
echo
echo "📋 Database Information:"
echo "  Host: localhost"
echo "  Port: 5432"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo "  Password: $DB_PASSWORD"
echo
echo "🔐 SAVE THIS INFO! Add to .env.production:"
echo
echo "DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME"
echo
echo "✅ Next steps:"
echo "  1. Copy the DATABASE_URL above"
echo "  2. Add to .env.production"
echo "  3. Run: npm run prisma:migrate:prod"
echo "  4. Deploy with PM2"
echo
echo "📊 Useful commands:"
echo "  psql -U $DB_USER -d $DB_NAME              # Connect to database"
echo "  pg_dump -U $DB_USER $DB_NAME > backup.sql # Manual backup"
echo "  /usr/local/bin/backup-traider-db.sh       # Run backup now"
echo "  crontab -l                                 # View cron jobs"
echo
