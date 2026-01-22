# Install Node.js Portable (No Admin Required)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Installing Node.js (Portable)" -ForegroundColor Cyan
Write-Host " No Administrator Rights Required" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$nodeVersion = "v20.18.1"
$nodeUrl = "https://nodejs.org/dist/$nodeVersion/node-$nodeVersion-win-x64.zip"
$nodeZip = "$env:TEMP\node.zip"
$nodeDir = "$env:USERPROFILE\nodejs"

Write-Host "Downloading Node.js $nodeVersion..." -ForegroundColor Yellow
Write-Host "URL: $nodeUrl" -ForegroundColor Gray

try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $nodeUrl -OutFile $nodeZip -UseBasicParsing
    Write-Host "Download complete!" -ForegroundColor Green
} catch {
    Write-Host "Download failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Extracting Node.js..." -ForegroundColor Yellow

# Remove old installation if exists
if (Test-Path $nodeDir) {
    Remove-Item $nodeDir -Recurse -Force
}

# Extract
Expand-Archive -Path $nodeZip -DestinationPath $env:TEMP -Force
$extractedFolder = "$env:TEMP\node-$nodeVersion-win-x64"
Move-Item $extractedFolder $nodeDir -Force

# Cleanup
Remove-Item $nodeZip -Force

Write-Host "Node.js installed to: $nodeDir" -ForegroundColor Green
Write-Host ""

# Add to User PATH
Write-Host "Adding Node.js to your PATH..." -ForegroundColor Yellow
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$nodeDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$nodeDir", "User")
    Write-Host "Added to PATH!" -ForegroundColor Green
} else {
    Write-Host "Already in PATH!" -ForegroundColor Green
}

# Update current session PATH
$env:Path = "$env:Path;$nodeDir"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host " Node.js Installation Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""

# Verify installation
Write-Host "Verifying installation..." -ForegroundColor Yellow
& "$nodeDir\node.exe" --version
& "$nodeDir\npm.cmd" --version

Write-Host ""
Write-Host "Node.js is ready to use!" -ForegroundColor Green
Write-Host ""
Write-Host "Current session is updated. For new terminals, restart them." -ForegroundColor Gray
Write-Host ""
