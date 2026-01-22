# Database Setup Helper

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Database Connection Setup" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Browser opened to Neon.tech!" -ForegroundColor Green
Write-Host ""
Write-Host "Steps in browser:" -ForegroundColor Yellow
Write-Host "  1. Sign in with GitHub (1 click)" -ForegroundColor White
Write-Host "  2. Click 'Create a project'" -ForegroundColor White
Write-Host "  3. Name it 'TrAIder' (or anything)" -ForegroundColor White
Write-Host "  4. Click 'Create project'" -ForegroundColor White
Write-Host "  5. Copy the connection string" -ForegroundColor White
Write-Host ""
Write-Host "The connection string looks like:" -ForegroundColor Gray
Write-Host "  postgresql://user:pass@ep-xxx.region.aws.neon.tech/dbname?sslmode=require" -ForegroundColor DarkGray
Write-Host ""

$connectionString = Read-Host "Paste your Neon connection string here"

if ([string]::IsNullOrWhiteSpace($connectionString)) {
    Write-Host ""
    Write-Host "No connection string provided. Exiting..." -ForegroundColor Red
    exit 1
}

# Validate connection string
if ($connectionString -notmatch '^postgresql://') {
    Write-Host ""
    Write-Host "Invalid connection string format!" -ForegroundColor Red
    Write-Host "It should start with: postgresql://" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Updating .env file..." -ForegroundColor Yellow

# Read current .env
$envContent = Get-Content .env -Raw

# Replace DATABASE_URL
$newEnvContent = $envContent -replace 'DATABASE_URL="[^"]*"', "DATABASE_URL=`"$connectionString`""

# Save
Set-Content .env -Value $newEnvContent -NoNewline

Write-Host "  .env file updated!" -ForegroundColor Green
Write-Host ""

# Run migrations
Write-Host "Running database migrations..." -ForegroundColor Yellow
Write-Host ""

npm run prisma:migrate

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host " Database Setup Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Your database is ready!" -ForegroundColor Cyan
Write-Host ""
Write-Host "Start the API server:" -ForegroundColor Cyan
Write-Host "  npm run dev" -ForegroundColor White
Write-Host ""

$startNow = Read-Host "Start the server now? (y/n)"
if ($startNow -eq 'y' -or $startNow -eq 'Y') {
    Write-Host ""
    Write-Host "Starting server..." -ForegroundColor Green
    Write-Host ""
    npm run dev
}
