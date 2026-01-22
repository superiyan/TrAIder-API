# Quick PostgreSQL Installation Guide for Windows

## 🚀 Quick Install (Automatic)

### Option 1: Run PowerShell Script (Recommended)

1. Open PowerShell as Administrator (Right-click PowerShell → Run as Administrator)
2. Navigate to project folder:
   ```powershell
   cd "C:\Users\riyan.tamara\Documents\TrAIder-API"
   ```
3. Run the installer script:
   ```powershell
   .\install-postgres.ps1
   ```

If you get an error about execution policy, run this first:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## 📦 Manual Installation

### Option 2: Download and Install

1. **Download PostgreSQL:**
   - Visit: https://www.postgresql.org/download/windows/
   - Or direct link: https://www.enterprisedb.com/downloads/postgres-postgresql-downloads
   - Download PostgreSQL 16.x for Windows x64

2. **Run Installer:**
   - Double-click the downloaded `.exe` file
   - Click "Next" through the wizard
   - Choose installation directory (default is fine)
   - Select components:
     - ✅ PostgreSQL Server
     - ✅ pgAdmin 4 (GUI tool)
     - ✅ Command Line Tools
   - Set password: **traider_password** (or your choice)
   - Port: **5432** (default)
   - Locale: Default locale
   - Click "Next" → "Next" → Install

3. **Create Database:**
   
   After installation, open PowerShell and run:
   ```powershell
   # Set password environment variable
   $env:PGPASSWORD = "traider_password"
   
   # Create user
   psql -U postgres -c "CREATE USER traider_user WITH PASSWORD 'traider_password';"
   
   # Create database
   psql -U postgres -c "CREATE DATABASE traider_db OWNER traider_user;"
   
   # Grant privileges
   psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE traider_db TO traider_user;"
   ```

4. **Verify Installation:**
   ```powershell
   psql --version
   ```

---

## 🐳 Alternative: Docker (Easiest but requires Docker)

If you want to install Docker first, then use PostgreSQL via Docker:

1. **Install Docker Desktop:**
   - Download: https://www.docker.com/products/docker-desktop/
   - Install and restart your computer

2. **Run PostgreSQL Container:**
   ```powershell
   docker run -d `
     --name traider-postgres `
     -e POSTGRES_USER=traider_user `
     -e POSTGRES_PASSWORD=traider_password `
     -e POSTGRES_DB=traider_db `
     -p 5432:5432 `
     postgres:16-alpine
   ```

3. **Or use Docker Compose (already configured):**
   ```powershell
   docker-compose up -d postgres
   ```

---

## 🧪 Test Connection

After installation, test if PostgreSQL is working:

```powershell
# Test connection
psql -h localhost -U traider_user -d traider_db -c "SELECT version();"
```

Password: `traider_password`

If you see PostgreSQL version info, it's working! ✅

---

## 📝 Your Connection Details

```
Host:     localhost
Port:     5432
Database: traider_db
Username: traider_user
Password: traider_password
```

**Connection String (for .env file):**
```
DATABASE_URL="postgresql://traider_user:traider_password@localhost:5432/traider_db?schema=public"
```

This is already configured in your `.env` file! 🎉

---

## 🔧 Troubleshooting

### PostgreSQL service not running
```powershell
# Start PostgreSQL service
net start postgresql-16
```

### Can't connect to database
1. Check if service is running: `services.msc` → Look for PostgreSQL
2. Check firewall: Allow port 5432
3. Verify pg_hba.conf allows local connections

### Reset password
```powershell
psql -U postgres
ALTER USER traider_user WITH PASSWORD 'new_password';
```

---

## ✅ Next Steps After PostgreSQL is Installed

1. Install Node.js: https://nodejs.org/ (download LTS version)
2. Install dependencies:
   ```powershell
   npm install
   ```
3. Generate Prisma Client:
   ```powershell
   npm run prisma:generate
   ```
4. Run database migrations:
   ```powershell
   npm run prisma:migrate
   ```
5. Start the API:
   ```powershell
   npm run dev
   ```

---

## 📚 Useful PostgreSQL Commands

```powershell
# Connect to database
psql -U traider_user -d traider_db

# List databases
\l

# List tables
\dt

# Quit psql
\q

# Check PostgreSQL status
pg_ctl status

# Start/Stop PostgreSQL
net start postgresql-16
net stop postgresql-16
```

---

Need help? Check the main [SETUP.md](SETUP.md) for more details!
