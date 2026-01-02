# Migration Runner

Execute database migrations safely with rollback capability.

## When to Run
- Before deploying schema changes
- Setting up new environment
- After pulling changes with new migrations
- "Run migrations"

## Safety Principles

1. **Always backup first** - No exceptions
2. **Test on staging first** - Never go straight to production
3. **Have rollback ready** - Know how to undo before you do
4. **Run during low traffic** - Schedule maintenance windows
5. **Monitor after** - Watch for errors post-migration

## Pre-Flight Checklist

- [ ] Database backup completed
- [ ] Rollback script tested
- [ ] Staging migration successful
- [ ] Team notified of maintenance
- [ ] Monitoring dashboards open

## Steps

### 1. Backup Database

```bash
# PostgreSQL
pg_dump -h {{DB_HOST}} -U {{DB_USER}} {{DB_NAME}} > backup_$(date +%Y%m%d_%H%M%S).sql

# MySQL
mysqldump -h {{DB_HOST}} -u {{DB_USER}} -p {{DB_NAME}} > backup_$(date +%Y%m%d_%H%M%S).sql

# MongoDB
mongodump --uri="{{MONGO_URI}}" --out=backup_$(date +%Y%m%d_%H%M%S)
```

### 2. Check Pending Migrations

```bash
# Prisma
npx prisma migrate status

# Knex
npx knex migrate:status

# TypeORM
npx typeorm migration:show

# Django
python manage.py showmigrations

# Rails
rails db:migrate:status
```

### 3. Run Migrations

```bash
# Prisma
npx prisma migrate deploy

# Knex
npx knex migrate:latest

# TypeORM
npx typeorm migration:run

# Django
python manage.py migrate

# Rails
rails db:migrate
```

### 4. Verify Migration

```bash
# Check migration was applied
{{MIGRATION_STATUS_COMMAND}}

# Verify schema changes
{{SCHEMA_CHECK_COMMAND}}

# Run smoke tests
{{PKG}} run test:db
```

## Rollback Procedures

### Prisma
```bash
# Rollback last migration
npx prisma migrate resolve --rolled-back {{MIGRATION_NAME}}
# Then manually revert schema changes
```

### Knex
```bash
# Rollback last batch
npx knex migrate:rollback

# Rollback all
npx knex migrate:rollback --all
```

### TypeORM
```bash
# Revert last migration
npx typeorm migration:revert
```

### Django
```bash
# Rollback to specific migration
python manage.py migrate {{APP_NAME}} {{MIGRATION_NAME}}
```

### Rails
```bash
# Rollback last migration
rails db:rollback

# Rollback N migrations
rails db:rollback STEP=N
```

### Emergency: Restore from Backup

```bash
# PostgreSQL
psql -h {{DB_HOST}} -U {{DB_USER}} {{DB_NAME}} < backup_YYYYMMDD_HHMMSS.sql

# MySQL
mysql -h {{DB_HOST}} -u {{DB_USER}} -p {{DB_NAME}} < backup_YYYYMMDD_HHMMSS.sql

# MongoDB
mongorestore --uri="{{MONGO_URI}}" backup_YYYYMMDD_HHMMSS/
```

## Common Issues

### Migration Timeout
```bash
# Increase timeout for large tables
SET statement_timeout = '30min';
# Or break into smaller migrations
```

### Lock Contention
```bash
# Check for blocking queries
SELECT * FROM pg_stat_activity WHERE state = 'active';

# Kill blocking query (carefully!)
SELECT pg_terminate_backend({{PID}});
```

### Schema Drift
```bash
# Compare expected vs actual schema
npx prisma db pull --force
git diff prisma/schema.prisma
```

## Output

```
## Migration Report: {{ENVIRONMENT}}

### Pre-Migration
- Backup: ✅ backup_20240115_143022.sql (2.3GB)
- Current version: migration_20240110_add_users
- Pending migrations: 3

### Migrations Applied
| Migration | Duration | Status |
|-----------|----------|--------|
| 20240112_add_orders | 1.2s | ✅ |
| 20240113_add_order_items | 0.8s | ✅ |
| 20240115_add_indexes | 45.3s | ✅ |

### Post-Migration
- Schema version: migration_20240115_add_indexes
- Tables affected: orders, order_items
- Indexes created: 3
- Verification tests: ✅ passed

### Rollback Command (if needed)
\`\`\`bash
npx knex migrate:rollback --all
psql -h {{DB_HOST}} -U {{DB_USER}} {{DB_NAME}} < backup_20240115_143022.sql
\`\`\`

---
**Status: ✅ Migration successful**
Total duration: 47.3s
```

OR

```
## Migration Report: {{ENVIRONMENT}}

### Migration Failed ❌

**Failed at:** 20240115_add_indexes
**Error:** relation "orders" does not exist
**Duration before failure:** 2.1s

### Automatic Rollback
- Rolled back: 20240113_add_order_items ✅
- Rolled back: 20240112_add_orders ✅
- Current version: migration_20240110_add_users

### Root Cause
Migration 20240112_add_orders was skipped in staging but exists in production.

### Resolution Steps
1. Fix migration order in source control
2. Re-run migrations after fix
3. Verify on staging first

---
**Status: ❌ Migration failed and rolled back**
Database restored to previous state
```

## Environment-Specific Commands

| Environment | Command | Notes |
|-------------|---------|-------|
| Development | `{{PKG}} run migrate:dev` | Auto-reset on failure |
| Staging | `{{PKG}} run migrate:staging` | Test rollback after |
| Production | `{{PKG}} run migrate:prod` | Requires approval |
