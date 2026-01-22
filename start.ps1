# Quick Start - TrAIder API

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " TrAIder API - Quick Start" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check Node.js
Write-Host "Checking Node.js..." -ForegroundColor Yellow
$nodeCheck = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodeCheck) {
    $env:Path = "$env:Path;$env:USERPROFILE\nodejs"
}

try {
    $nodeVer = node --version
    Write-Host "  Node.js $nodeVer" -ForegroundColor Green
} catch {
    Write-Host "  Node.js not found!" -ForegroundColor Red
    Write-Host "  Run: .\install-nodejs-portable.ps1" -ForegroundColor Yellow
    exit 1
}

# Check if dependencies installed
Write-Host "Checking dependencies..." -ForegroundColor Yellow
if (-not (Test-Path "node_modules")) {
    Write-Host "  Installing dependencies..." -ForegroundColor Yellow
    npm install
}
Write-Host "  Dependencies OK" -ForegroundColor Green

# Check if Prisma Client generated
Write-Host "Checking Prisma Client..." -ForegroundColor Yellow
if (-not (Test-Path "node_modules\.prisma\client")) {
    Write-Host "  Generating Prisma Client..." -ForegroundColor Yellow
    npm run prisma:generate
}
Write-Host "  Prisma Client OK" -ForegroundColor Green

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host " Setup Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""

# Check database
Write-Host "Database Setup:" -ForegroundColor Cyan
Write-Host ""
$envContent = Get-Content .env -Raw
if ($envContent -match 'DATABASE_URL="postgresql://traider_user:traider_password@localhost') {
    Write-Host "  You're using LOCAL database" -ForegroundColor Yellow
    Write-Host "  Options:" -ForegroundColor White
    Write-Host "    1. Install PostgreSQL locally (requires admin)" -ForegroundColor Gray
    Write-Host "    2. Use online database (recommended)" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Recommended: Use Neon (free, no admin needed)" -ForegroundColor Yellow
    Write-Host "  Guide: See ONLINE-DATABASE.md" -ForegroundColor Gray
    Write-Host "  Quick: https://neon.tech" -ForegroundColor Gray
    Write-Host ""
    
    $useOnline = Read-Host "Open Neon.tech to get free database? (y/n)"
    if ($useOnline -eq 'y') {
        Start-Process "https://console.neon.tech/sign_in"
        Write-Host ""
        Write-Host "After getting your connection string:" -ForegroundColor Cyan
        Write-Host "  1. Copy the connection string" -ForegroundColor White
        Write-Host "  2. Open .env file" -ForegroundColor White
        Write-Host "  3. Replace DATABASE_URL value" -ForegroundColor White
        Write-Host "  4. Run: npm run prisma:migrate" -ForegroundColor White
        Write-Host "  5. Run: npm run dev" -ForegroundColor White
    }
} else {
    Write-Host "  Database configured!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Ready to start!" -ForegroundColor Cyan
    Write-Host "  Run: npm run dev" -ForegroundColor White
    Write-Host ""
    
    $startNow = Read-Host "Start the API server now? (y/n)"
    if ($startNow -eq 'y') {
        npm run dev
    }
}

Write-Host ""
