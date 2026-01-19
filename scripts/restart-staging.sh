#!/bin/bash
# Restart AL-Chat Backend on EC2 Staging
# Usage: Run this script to restart the backend container on EC2

set -e

SSH_KEY="$HOME/.ssh/papita-ec2-key.pem"
STAGING_IP="3.145.42.104"
STAGING_USER="ubuntu"

if [ ! -f "$SSH_KEY" ]; then
    echo "SSH key not found: $SSH_KEY"
    exit 1
fi

echo "Restarting AL-Chat backend on EC2 staging..."
echo ""

# Restart script to run on EC2
RESTART_SCRIPT=$(cat <<'RESTART_EOF'
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
RESTART_EOF
)

# Execute restart script on EC2
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ${STAGING_USER}@${STAGING_IP} "bash -s" <<< "$RESTART_SCRIPT"

if [ $? -ne 0 ]; then
    echo ""
    echo "[ERROR] Restart failed"
    exit 1
fi

echo ""
echo "[OK] Backend restarted successfully"
