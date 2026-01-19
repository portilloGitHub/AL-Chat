# Restart AL-Chat Backend on EC2 Staging
# Usage: .\scripts\restart-staging.ps1

$ErrorActionPreference = "Stop"

$SSH_KEY = Join-Path $env:USERPROFILE ".ssh\papita-ec2-key.pem"
$STAGING_IP = "3.145.42.104"
$STAGING_USER = "ubuntu"

if (-not (Test-Path $SSH_KEY)) {
    Write-Host "[ERROR] SSH key not found: $SSH_KEY" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Restarting AL-Chat Backend on EC2 Staging" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Restart script to run on EC2
$restartScript = @'
#!/bin/bash
set -e

echo "=========================================="
echo "Restarting AL-Chat Backend Container"
echo "=========================================="
echo ""

echo "[Step 1] Restarting container..."
docker restart al-chat-backend-staging

if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to restart container"
    exit 1
fi

echo ""
echo "[Step 2] Waiting for container to start..."
sleep 5

echo ""
echo "[Step 3] Checking container status..."
docker ps | grep al-chat-backend-staging || echo "[WARNING] Container not found in running list"

echo ""
echo "[Step 4] Checking logs (last 15 lines)..."
docker logs al-chat-backend-staging --tail 15

echo ""
echo "[Step 5] Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" http://localhost:5000/api/health)
HTTP_CODE=$(echo "$HEALTH_RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
RESPONSE_BODY=$(echo "$HEALTH_RESPONSE" | grep -v "HTTP_CODE")

if [ "$HTTP_CODE" = "200" ]; then
    echo "[OK] Backend is healthy"
    echo "Response: $RESPONSE_BODY"
else
    echo "[WARNING] Health check returned HTTP $HTTP_CODE"
    echo "Response: $RESPONSE_BODY"
fi

echo ""
echo "=========================================="
echo "Restart Complete!"
echo "=========================================="
'@

Write-Host "Connecting to EC2 and restarting container..." -ForegroundColor Yellow
Write-Host ""

# Fix SSH key permissions (if on Windows/WSL)
# Note: This might not work on Windows, but won't hurt
$null = icacls $SSH_KEY /inheritance:r /grant:r "$env:USERNAME`:R" 2>$null

# Execute restart script on EC2
$restartScript | ssh -i $SSH_KEY -o StrictHostKeyChecking=no ${STAGING_USER}@${STAGING_IP} "bash -s"

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "[ERROR] Restart failed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Check SSH key permissions" -ForegroundColor Gray
    Write-Host "  2. Verify EC2 instance is running" -ForegroundColor Gray
    Write-Host "  3. Check Security Group allows SSH (port 22)" -ForegroundColor Gray
    exit 1
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "[OK] Backend restarted successfully" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
