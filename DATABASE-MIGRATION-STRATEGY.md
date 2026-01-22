# 🗄️ Database Migration Strategy

Production-safe database migration procedures untuk TrAIder API dengan zero-downtime deployment.

## 📋 Table of Contents

1. [Migration Best Practices](#migration-best-practices)
2. [Pre-Migration Checklist](#pre-migration-checklist)
3. [Safe Migration Patterns](#safe-migration-patterns)
4. [Backwards-Compatible Migrations](#backwards-compatible-migrations)
5. [Rollback Procedures](#rollback-procedures)
6. [Performance Optimization](#performance-optimization)
7. [Migration Examples](#migration-examples)

---

## 📚 Migration Best Practices

### The Golden Rules

1. **Always Backup Before Migrating**
   ```bash
   # Automated backup
   pg_dump $DATABASE_URL > backup_$(date +%Y%m%d_%H%M%S).sql
   
   # Verify backup
   psql $DATABASE_URL < backup_*.sql --dry-run
   ```

2. **Test Migrations in Staging First**
   - Create staging environment identical to production
   - Run migration there first
   - Verify for 24+ hours before production

3. **Keep Migrations Reversible**
   - Always write DOWN migrations
   - Test rollback procedures
   - Document rollback steps

4. **Use Feature Flags for Schema Changes**
   - Deploy code that handles both old and new schemas
   - Then run migration
   - Then clean up old code

5. **Monitor During and After Migration**
   - Watch application logs
   - Monitor database performance
   - Check error rates

---

## ✅ Pre-Migration Checklist

```bash
#!/bin/bash
# scripts/pre-migration-check.sh

echo "🔍 Pre-Migration Verification"
echo "============================="

# 1. Verify backup exists
if [ -f "$BACKUP_FILE" ]; then
  BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
  echo "✅ Backup exists: $BACKUP_SIZE"
else
  echo "❌ No backup found. Creating backup..."
  pg_dump $DATABASE_URL > backup_$(date +%Y%m%d_%H%M%S).sql
fi

# 2. Check database is accessible
echo -n "Checking database access..."
psql $DATABASE_URL -c "SELECT 1" > /dev/null && echo "✅" || echo "❌"

# 3. Check disk space (migrations need 2x current DB size)
DB_SIZE=$(psql $DATABASE_URL -c "SELECT pg_size_pretty(pg_database_size(current_database()));" --tuples-only)
echo "✅ Database size: $DB_SIZE"

# 4. Verify application version
echo "✅ Application version: $(grep version package.json)"

# 5. Check all services are running
pm2 status traider-api

# 6. Review migration files
echo "📋 Migrations to apply:"
ls -la prisma/migrations/ | grep "migration.sql"

echo ""
echo "✅ Pre-migration checks complete!"
echo "Ready to proceed with migration."
```

---

## 🔄 Safe Migration Patterns

### Pattern 1: Add Column (Simple)

✅ **Safe** - Non-destructive
- Doesn't affect existing code
- Can be done during production

```sql
-- migration.sql
ALTER TABLE users ADD COLUMN last_login_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Rollback
ALTER TABLE users DROP COLUMN last_login_at;
```

### Pattern 2: Add Column with Not-Null Constraint (Medium)

⚠️ **Requires careful handling**

```sql
-- Step 1: Add column without constraint
ALTER TABLE users ADD COLUMN phone VARCHAR(20);

-- Step 2: Populate with default values (can be slow)
UPDATE users SET phone = '0000000000' WHERE phone IS NULL;

-- Step 3: Add constraint after data is populated
ALTER TABLE users ALTER COLUMN phone SET NOT NULL;
```

### Pattern 3: Remove Column (Complex)

❌ **High risk** - Can break application

**Instead: Use feature flags**

```prisma
// schema.prisma - Deprecated field
model User {
  id String @id
  email String
  deprecated_phone String? // Mark for removal
}
```

```typescript
// Application code ignores deprecated_phone
const { id, email } = user; // Don't use deprecated_phone

// After 1-2 releases:
// 1. Deploy code that doesn't reference field
// 2. Wait 24+ hours for all clients to update
// 3. Then run migration to drop column
```

### Pattern 4: Rename Column (Complex)

**Don't rename directly - use shadows**

```sql
-- Step 1: Create new column
ALTER TABLE users ADD COLUMN email_address VARCHAR(255);

-- Step 2: Copy data
UPDATE users SET email_address = email;

-- Step 3: Update application to write to BOTH columns

-- Step 4: After verification, use new column exclusively

-- Step 5: Drop old column
ALTER TABLE users DROP COLUMN email;
```

---

## ↔️ Backwards-Compatible Migrations

### The Double-Write Strategy

```typescript
// src/models/user.ts
import { prisma } from '../config/database';

export class User {
  // During migration: write to both old and new columns
  async updateUser(id: string, data: Partial<User>) {
    const updates: any = {};
    
    // Map new field to old column for backwards compatibility
    if (data.email_address) {
      updates.email_address = data.email_address;
      updates.email = data.email_address; // Write to both during transition
    }
    
    return prisma.user.update({
      where: { id },
      data: updates
    });
  }
  
  // Read from new column preferentially
  async getUser(id: string) {
    const user = await prisma.user.findUnique({
      where: { id },
      select: {
        email_address: true,
        email: true // For backwards compatibility
      }
    });
    
    // Use new column if exists, fall back to old
    return {
      ...user,
      email: user.email_address || user.email
    };
  }
}
```

### Migration Timeline

```
Day 1: Deploy code that handles both columns
       ↓
Day 1: Run Prisma migration (add column, copy data)
       ↓
Day 2-7: Monitor application, handle edge cases
       ↓
Day 8: Deploy code that only uses new column
       ↓
Day 9: Run migration to drop old column
```

---

## ⏮️ Rollback Procedures

### Automatic Rollback

```bash
#!/bin/bash
# scripts/auto-rollback.sh

set -e

BACKUP_FILE=$1

if [ -z "$BACKUP_FILE" ]; then
  echo "Usage: ./auto-rollback.sh <backup_file>"
  exit 1
fi

echo "⏮️  Starting automated rollback..."

# 1. Stop application
echo "1️⃣  Stopping application..."
pm2 stop traider-api

# 2. Backup current state
echo "2️⃣  Backing up current database..."
pg_dump $DATABASE_URL > backup_before_rollback_$(date +%Y%m%d_%H%M%S).sql

# 3. Drop existing database
echo "3️⃣  Dropping current database..."
dropdb --if-exists traider

# 4. Restore from backup
echo "4️⃣  Restoring from backup..."
createdb traider
psql traider < "$BACKUP_FILE"

# 5. Verify restoration
echo "5️⃣  Verifying restoration..."
psql $DATABASE_URL -c "SELECT COUNT(*) FROM users;" 

# 6. Restart application
echo "6️⃣  Restarting application..."
pm2 restart traider-api

# 7. Verify application
echo "7️⃣  Verifying application..."
sleep 5
curl http://localhost:3000/health

echo "✅ Rollback complete!"
```

### Manual Rollback Checklist

```bash
# 1. Check backup exists and is valid
file /path/to/backup.sql

# 2. Stop application
pm2 stop traider-api

# 3. Create safety backup
pg_dump $DATABASE_URL > safety_backup_$(date +%s).sql

# 4. Restore from backup
# Option A: Restore entire database
dropdb traider
createdb traider
psql traider < /path/to/backup.sql

# Option B: Restore specific table
psql traider << EOF
BEGIN;
DROP TABLE IF EXISTS users;
RESTORE ... (from backup)
COMMIT;
EOF

# 5. Verify data integrity
psql $DATABASE_URL << EOF
SELECT COUNT(*) as user_count FROM users;
SELECT COUNT(*) as trade_count FROM trades;
EOF

# 6. Restart application
pm2 restart traider-api

# 7. Test application
curl http://localhost:3000/health
```

---

## ⚡ Performance Optimization

### Pre-Migration Optimization

```sql
-- Analyze query plans before migration
ANALYZE;

-- Disable maintenance during migration
ALTER SYSTEM SET maintenance_work_mem = '256MB';
SELECT pg_reload_conf();

-- Increase work_mem for faster sorting
SET work_mem = '256MB';
```

### Create Indexes After Data Operations

```sql
-- Good: Create index after INSERT/UPDATE
INSERT INTO table_name VALUES (...);
CREATE INDEX idx_name ON table_name(column_name);

-- Bad: Indices slow down bulk operations
CREATE INDEX idx_name ON table_name(column_name);
INSERT INTO table_name VALUES (...); -- Slower
```

### Large Table Migrations

For tables with >1 million rows, use strategies to avoid long-running transactions:

```sql
-- Bad: Long-running transaction locks table
BEGIN;
UPDATE huge_table SET column = value WHERE condition;
COMMIT; -- Blocks everything until done

-- Good: Batch updates
DO $$
DECLARE
  v_total INT;
  v_processed INT := 0;
  v_batch_size INT := 10000;
BEGIN
  SELECT COUNT(*) INTO v_total FROM huge_table WHERE condition;
  
  WHILE v_processed < v_total LOOP
    UPDATE huge_table 
    SET column = value 
    WHERE condition 
    LIMIT v_batch_size;
    
    v_processed := v_processed + v_batch_size;
    RAISE NOTICE 'Processed % of %', v_processed, v_total;
  END LOOP;
END;
$$;
```

---

## 📝 Migration Examples

### Example 1: Add Audit Trail Columns

```prisma
// schema.prisma
model User {
  id String @id
  email String
  // New audit fields
  created_at DateTime @default(now())
  updated_at DateTime @updatedAt
  deleted_at DateTime?
}
```

```sql
-- migration.sql (forward)
ALTER TABLE users ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE users ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE users ADD COLUMN deleted_at TIMESTAMP;

-- migration.sql (rollback)
ALTER TABLE users DROP COLUMN created_at;
ALTER TABLE users DROP COLUMN updated_at;
ALTER TABLE users DROP COLUMN deleted_at;
```

**Application code:**
```typescript
// src/services/user.service.ts
async createUser(data: CreateUserInput) {
  return prisma.user.create({
    data: {
      ...data,
      created_at: new Date(),
      updated_at: new Date()
    }
  });
}

async updateUser(id: string, data: UpdateUserInput) {
  return prisma.user.update({
    where: { id },
    data: {
      ...data,
      updated_at: new Date()
    }
  });
}

async softDeleteUser(id: string) {
  return prisma.user.update({
    where: { id },
    data: {
      deleted_at: new Date()
    }
  });
}
```

### Example 2: Add Foreign Key Constraint

```prisma
// schema.prisma
model Trade {
  id String @id
  user_id String
  user User @relation(fields: [user_id], references: [id])
  status TradeStatus
}
```

```sql
-- migration.sql
-- Step 1: Verify data integrity first
SELECT COUNT(*) FROM trades WHERE user_id NOT IN (SELECT id FROM users);

-- Step 2: Create index first (improves FK constraint creation)
CREATE INDEX idx_trades_user_id ON trades(user_id);

-- Step 3: Add constraint
ALTER TABLE trades 
ADD CONSTRAINT fk_trades_user_id 
FOREIGN KEY (user_id) REFERENCES users(id);
```

### Example 3: Add Enum Type

```prisma
// schema.prisma
enum TradeStatus {
  PENDING
  ACTIVE
  COMPLETED
  CANCELLED
}

model Trade {
  status TradeStatus @default(PENDING)
}
```

```sql
-- migration.sql
-- Create ENUM type
CREATE TYPE trade_status AS ENUM ('PENDING', 'ACTIVE', 'COMPLETED', 'CANCELLED');

-- Add column
ALTER TABLE trades ADD COLUMN status trade_status DEFAULT 'PENDING';
```

---

## 🧪 Testing Migrations

```bash
#!/bin/bash
# scripts/test-migration.sh

echo "🧪 Testing migration on staging..."

# 1. Create staging copy of production database
PROD_DB="traider"
STAGING_DB="traider_staging_$(date +%s)"

createdb $STAGING_DB -T $PROD_DB

# 2. Run migration on staging
export DATABASE_URL="postgresql://user:pass@localhost:5432/$STAGING_DB"
npm run prisma:migrate:deploy

# 3. Run tests against staging
npm test

# 4. Run performance tests
npm run test:performance

# 5. If all pass, migration is safe
if [ $? -eq 0 ]; then
  echo "✅ Migration tests passed!"
  dropdb $STAGING_DB
  exit 0
else
  echo "❌ Migration tests failed!"
  dropdb $STAGING_DB
  exit 1
fi
```

---

## 📋 Migration Checklist

```bash
#!/bin/bash

echo "📋 Pre-Migration Checklist"
echo "========================="

CHECKS_PASSED=0
CHECKS_FAILED=0

check() {
  if eval "$1"; then
    echo "✅ $2"
    ((CHECKS_PASSED++))
  else
    echo "❌ $2"
    ((CHECKS_FAILED++))
  fi
}

check "test -f backup_*.sql" "Backup file exists"
check "psql \$DATABASE_URL -c 'SELECT 1' > /dev/null 2>&1" "Database is accessible"
check "pm2 status traider-api > /dev/null 2>&1" "Application is running"
check "test -f prisma/migrations/**/migration.sql" "Migration files exist"
check "git status --porcelain | grep -q '^'" "All changes committed"

echo ""
echo "Results: $CHECKS_PASSED passed, $CHECKS_FAILED failed"

if [ $CHECKS_FAILED -gt 0 ]; then
  echo "❌ Some checks failed. Fix issues before migrating."
  exit 1
fi

echo "✅ Ready to migrate!"
```

---

## 🚀 Deployment Flow with Migrations

```
1. Create backup of production database
   ↓
2. Merge migration PR to main
   ↓
3. CI/CD triggers on main push
   ↓
4. Tests run (include migration tests)
   ↓
5. Docker image built and pushed
   ↓
6. New code deployed to staging
   ↓
7. Migration runs on staging
   ↓
8. Tests run on staging + production data
   ↓
9. If all pass: Deploy to production
   ↓
10. Before migration: Stop application (5 min downtime)
    ↓
11. Run migration on production
    ↓
12. Restart application
    ↓
13. Verify health checks pass
    ↓
14. Monitor logs for 30 minutes
    ↓
15. Resume normal operations
```

---

## 📚 Resources

- [Prisma Migration Guide](https://www.prisma.io/docs/concepts/components/prisma-migrate)
- [PostgreSQL Migration Patterns](https://wiki.postgresql.org/wiki/Migrations)
- [Zero-Downtime Deployments](https://github.com/ankane/strong_migrations)
- [Database Migration Safety](https://www.liquibase.org/get-started/best-practices)
