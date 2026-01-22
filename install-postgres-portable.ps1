# PostgreSQL Portable Installation (No Admin Rights Required)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " PostgreSQL Portable Installation" -ForegroundColor Cyan
Write-Host " No Administrator Rights Required" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$pgVersion = "16.6"
$pgUrl = "https://get.enterprisedb.com/postgresql/postgresql-$pgVersion-1-windows-x64-binaries.zip"
$pgZip = "$env:TEMP\postgres.zip"
$pgDir = "$env:USERPROFILE\pgsql"
$pgData = "$pgDir\data"

Write-Host "Downloading PostgreSQL $pgVersion portable..." -ForegroundColor Yellow
Write-Host "This may take a few minutes (180MB)..." -ForegroundColor Gray
Write-Host ""

try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $pgUrl -OutFile $pgZip -UseBasicParsing
    Write-Host "Download complete!" -ForegroundColor Green
} catch {
    Write-Host "Download failed. Using alternative method..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please download manually from:" -ForegroundColor Yellow
    Write-Host "https://www.enterprisedb.com/download-postgresql-binaries" -ForegroundColor White
    Write-Host ""
    Write-Host "Or use online database (free):" -ForegroundColor Yellow
    Write-Host "1. Neon: https://neon.tech (Best for Vercel)" -ForegroundColor White
    Write-Host "2. Supabase: https://supabase.com" -ForegroundColor White
    Write-Host "3. Railway: https://railway.app" -ForegroundColor White
    exit 1
}

Write-Host ""
Write-Host "Extracting PostgreSQL..." -ForegroundColor Yellow

if (Test-Path $pgDir) {
    Remove-Item $pgDir -Recurse -Force
}

Expand-Archive -Path $pgZip -DestinationPath $env:TEMP -Force
$extractedFolder = "$env:TEMP\pgsql"
Move-Item $extractedFolder $pgDir -Force
Remove-Item $pgZip -Force

Write-Host "PostgreSQL extracted to: $pgDir" -ForegroundColor Green
Write-Host ""

# Initialize database
Write-Host "Initializing database..." -ForegroundColor Yellow
$env:Path = "$env:Path;$pgDir\bin"

& "$pgDir\bin\initdb.exe" -D $pgData -U postgres -W -E UTF8 --locale=C

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host " PostgreSQL Installation Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "To start PostgreSQL:" -ForegroundColor Cyan
Write-Host "  $pgDir\bin\pg_ctl.exe -D $pgData -l $pgDir\logfile.log start" -ForegroundColor White
Write-Host ""
Write-Host "To stop PostgreSQL:" -ForegroundColor Cyan
Write-Host "  $pgDir\bin\pg_ctl.exe -D $pgData stop" -ForegroundColor White
Write-Host ""
Write-Host "Create database:" -ForegroundColor Cyan
Write-Host "  $pgDir\bin\createdb.exe -U postgres traider_db" -ForegroundColor White
Write-Host ""
