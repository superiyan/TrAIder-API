# Post-Installation Setup Script
# Run this after Node.js and PostgreSQL are installed

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " TrAIder API - Post Installation Setup" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Refresh environment variables
Write-Host "Step 1: Refreshing environment variables..." -ForegroundColor Yellow
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
Write-Host "Done!" -ForegroundColor Green
Write-Host ""

# Verify Node.js
Write-Host "Step 2: Verifying Node.js installation..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version
    $npmVersion = npm --version
    Write-Host "  Node.js: $nodeVersion" -ForegroundColor Green
    Write-Host "  npm: $npmVersion" -ForegroundColor Green
} catch {
    Write-Host "  Node.js not found. Please restart terminal and run again." -ForegroundColor Red
    exit 1
}
Write-Host ""

# Verify PostgreSQL
Write-Host "Step 3: Verifying PostgreSQL installation..." -ForegroundColor Yellow
try {
    $pgVersion = psql --version
    Write-Host "  $pgVersion" -ForegroundColor Green
} catch {
    Write-Host "  PostgreSQL not found. Please restart terminal and run again." -ForegroundColor Red
    exit 1
}
Write-Host ""

# Create PostgreSQL database
Write-Host "Step 4: Creating PostgreSQL database..." -ForegroundColor Yellow
Write-Host "Enter the PostgreSQL 'postgres' user password:" -ForegroundColor White
Write-Host "(Default is usually 'postgres' or what you set during installation)" -ForegroundColor Gray
$password = Read-Host -AsSecureString
$ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
$plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr)
$env:PGPASSWORD = $plainPassword

Write-Host "  Creating user 'traider_user'..." -NoNewline
psql -U postgres -c "CREATE USER traider_user WITH PASSWORD 'traider_password';" 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) { 
    Write-Host " OK" -ForegroundColor Green 
} else { 
    Write-Host " (may already exist)" -ForegroundColor Yellow 
}

Write-Host "  Creating database 'traider_db'..." -NoNewline
psql -U postgres -c "CREATE DATABASE traider_db OWNER traider_user;" 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) { 
    Write-Host " OK" -ForegroundColor Green 
} else { 
    Write-Host " (may already exist)" -ForegroundColor Yellow 
}

Write-Host "  Granting privileges..." -NoNewline
psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE traider_db TO traider_user;" 2>&1 | Out-Null
Write-Host " OK" -ForegroundColor Green
Write-Host ""

# Install npm dependencies
Write-Host "Step 5: Installing npm dependencies..." -ForegroundColor Yellow
npm install
Write-Host ""

# Generate Prisma Client
Write-Host "Step 6: Generating Prisma Client..." -ForegroundColor Yellow
npm run prisma:generate
Write-Host ""

# Run database migrations
Write-Host "Step 7: Running database migrations..." -ForegroundColor Yellow
npm run prisma:migrate
Write-Host ""

Write-Host "==========================================" -ForegroundColor Green
Write-Host " Installation Complete! " -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Database Info:" -ForegroundColor Cyan
Write-Host "  URL: postgresql://traider_user:traider_password@localhost:5432/traider_db" -ForegroundColor White
Write-Host ""
Write-Host "Start the API server:" -ForegroundColor Cyan
Write-Host "  npm run dev" -ForegroundColor White
Write-Host ""
Write-Host "The API will run at: http://localhost:3000" -ForegroundColor Yellow
Write-Host ""
