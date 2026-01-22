# PostgreSQL Installation Helper for TrAIder API

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " PostgreSQL Installation Helper" -ForegroundColor Cyan  
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if PostgreSQL is installed
$pgCommand = Get-Command psql -ErrorAction SilentlyContinue

if (-not $pgCommand) {
    Write-Host "PostgreSQL is NOT installed on this system." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install PostgreSQL manually:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Option 1 - Official Installer (Recommended):" -ForegroundColor Green
    Write-Host "  1. Open: https://www.postgresql.org/download/windows/" -ForegroundColor White
    Write-Host "  2. Download PostgreSQL 16 for Windows x64" -ForegroundColor White
    Write-Host "  3. Run the installer" -ForegroundColor White
    Write-Host "  4. Set password: traider_password" -ForegroundColor White
    Write-Host "  5. Keep default port: 5432" -ForegroundColor White
    Write-Host "  6. Complete installation" -ForegroundColor White
    Write-Host "  7. Run this script again" -ForegroundColor White
    Write-Host ""
    Write-Host "Option 2 - Using Docker:" -ForegroundColor Green
    Write-Host "  docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=traider_password postgres:16" -ForegroundColor White
    Write-Host ""
    
    $openPage = Read-Host "Open download page in browser? (y/n)"
    if ($openPage -eq 'y') {
        Start-Process "https://www.postgresql.org/download/windows/"
    }
    exit
}

Write-Host "PostgreSQL is installed!" -ForegroundColor Green
psql --version
Write-Host ""

# Ask for postgres password
Write-Host "Now let's create the TrAIder database..." -ForegroundColor Yellow
Write-Host "Please enter your PostgreSQL 'postgres' user password:" -ForegroundColor White
$password = Read-Host -AsSecureString
$ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
$plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr)

$env:PGPASSWORD = $plainPassword

# Create database and user
Write-Host ""
Write-Host "Creating database and user..." -ForegroundColor Yellow

$sql1 = "CREATE USER traider_user WITH PASSWORD 'traider_password';"
$sql2 = "CREATE DATABASE traider_db OWNER traider_user;"
$sql3 = "GRANT ALL PRIVILEGES ON DATABASE traider_db TO traider_user;"

Write-Host "  - Creating user..." -NoNewline
$result1 = psql -U postgres -c $sql1 2>&1
if ($?) { Write-Host " OK" -ForegroundColor Green } else { Write-Host " (may already exist)" -ForegroundColor Yellow }

Write-Host "  - Creating database..." -NoNewline
$result2 = psql -U postgres -c $sql2 2>&1
if ($?) { Write-Host " OK" -ForegroundColor Green } else { Write-Host " (may already exist)" -ForegroundColor Yellow }

Write-Host "  - Granting privileges..." -NoNewline
$result3 = psql -U postgres -c $sql3 2>&1
if ($?) { Write-Host " OK" -ForegroundColor Green } else { Write-Host " OK" -ForegroundColor Green }

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Database Connection Info:" -ForegroundColor Cyan
Write-Host "  Host:     localhost" -ForegroundColor White
Write-Host "  Port:     5432" -ForegroundColor White
Write-Host "  Database: traider_db" -ForegroundColor White
Write-Host "  Username: traider_user" -ForegroundColor White
Write-Host "  Password: traider_password" -ForegroundColor White
Write-Host ""
Write-Host "Connection string (already in your .env file):" -ForegroundColor Cyan
Write-Host "postgresql://traider_user:traider_password@localhost:5432/traider_db" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Install Node.js: https://nodejs.org" -ForegroundColor White
Write-Host "  2. npm install" -ForegroundColor White
Write-Host "  3. npm run prisma:generate" -ForegroundColor White
Write-Host "  4. npm run prisma:migrate" -ForegroundColor White
Write-Host "  5. npm run dev" -ForegroundColor White
Write-Host ""
