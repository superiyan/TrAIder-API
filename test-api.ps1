# Test API Connection

Write-Host "`nTesting TrAIder API..." -ForegroundColor Cyan
Write-Host "========================`n" -ForegroundColor Cyan

# Try port 5000
Write-Host "Checking port 5000..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri "http://127.0.0.1:5000/health" -TimeoutSec 5
    
    Write-Host "`n✅ SUCCESS! API is working!" -ForegroundColor Green
    Write-Host "`nServer URL: http://localhost:5000" -ForegroundColor Cyan
    Write-Host "Health Check: http://localhost:5000/health" -ForegroundColor Cyan
    Write-Host "API Base: http://localhost:5000/api/v1" -ForegroundColor Cyan
    Write-Host "`nResponse:" -ForegroundColor White
    $response | ConvertTo-Json
    Write-Host "`n✅ Your API is ready to use!`n" -ForegroundColor Green
    
} catch {
    Write-Host "`n❌ Cannot connect to server" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "`nPossible issues:" -ForegroundColor Yellow
    Write-Host "  1. Server not running (check if 'npm run dev' is active)" -ForegroundColor Gray
    Write-Host "  2. Firewall blocking connection" -ForegroundColor Gray
    Write-Host "  3. Port in use by another process`n" -ForegroundColor Gray
    
    # Check if port is listening
    Write-Host "Checking if port 5000 is listening..." -ForegroundColor Yellow
    $listening = netstat -ano | findstr :5000
    if ($listening) {
        Write-Host "Port 5000 is active:" -ForegroundColor Green
        Write-Host $listening -ForegroundColor Gray
    } else {
        Write-Host "Port 5000 is NOT listening - server might not be running" -ForegroundColor Red
    }
}

Write-Host ""
