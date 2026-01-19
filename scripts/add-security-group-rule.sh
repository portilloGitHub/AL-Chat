#!/bin/bash
# Add Security Group Rule for AL-Chat Backend Port 5000
# Usage: ./scripts/add-security-group-rule.sh

set -e

STAGING_IP="3.145.42.104"
PORT=5000

echo ""
echo "============================================================"
echo "Adding Security Group Rule for Port $PORT"
echo "============================================================"
echo ""

# Step 1: Find the EC2 instance and get its Security Group
echo "[Step 1] Finding EC2 instance and Security Group..."

INSTANCE_INFO=$(aws ec2 describe-instances \
    --filters "Name=ip-address,Values=$STAGING_IP" \
    --query "Reservations[0].Instances[0].[InstanceId,SecurityGroups[0].GroupId,SecurityGroups[0].GroupName]" \
    --output text 2>&1)

if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to find EC2 instance"
    echo "$INSTANCE_INFO"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check AWS CLI is configured: aws configure list"
    echo "  2. Verify instance IP: $STAGING_IP"
    echo "  3. Check AWS credentials and region"
    exit 1
fi

read -r INSTANCE_ID SECURITY_GROUP_ID SECURITY_GROUP_NAME <<< "$INSTANCE_INFO"

if [ -z "$SECURITY_GROUP_ID" ]; then
    echo "[ERROR] Could not find Security Group ID"
    echo "Instance Info: $INSTANCE_INFO"
    exit 1
fi

echo "[OK] Found instance and security group"
echo "   Instance ID: $INSTANCE_ID"
echo "   Security Group ID: $SECURITY_GROUP_ID"
echo "   Security Group Name: $SECURITY_GROUP_NAME"
echo ""

# Step 2: Check if rule already exists
echo "[Step 2] Checking if rule already exists..."

EXISTING_RULES=$(aws ec2 describe-security-groups \
    --group-ids "$SECURITY_GROUP_ID" \
    --query "SecurityGroups[0].IpPermissions[?FromPort==\`$PORT\` && ToPort==\`$PORT\` && IpProtocol==\`"tcp\`"]" \
    --output json 2>&1)

if [ $? -eq 0 ]; then
    RULE_COUNT=$(echo "$EXISTING_RULES" | jq '. | length' 2>/dev/null || echo "0")
    if [ "$RULE_COUNT" -gt 0 ]; then
        echo "[INFO] Rule for port $PORT already exists"
        echo "   Rule: $EXISTING_RULES"
        echo ""
        echo "[OK] No action needed - rule already exists"
        exit 0
    fi
fi

echo "[OK] Rule does not exist - will create it"
echo ""

# Step 3: Add the security group rule
echo "[Step 3] Adding security group rule..."
echo "   Port: $PORT"
echo "   Protocol: TCP"
echo "   Source: 0.0.0.0/0 (all IPs)"
echo ""

RESULT=$(aws ec2 authorize-security-group-ingress \
    --group-id "$SECURITY_GROUP_ID" \
    --protocol tcp \
    --port $PORT \
    --cidr 0.0.0.0/0 \
    --output json 2>&1)

EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    # Check if it's a duplicate rule error
    if echo "$RESULT" | grep -q "already exists\|InvalidPermission.Duplicate"; then
        echo "[INFO] Rule already exists (duplicate)"
        echo "[OK] Port $PORT is already allowed"
    else
        echo "[ERROR] Failed to add security group rule"
        echo "$RESULT"
        exit 1
    fi
else
    echo "[OK] Security group rule added successfully"
    echo "   Result: $RESULT"
fi

echo ""
echo "============================================================"
echo "[SUCCESS] Security Group Rule Added"
echo "============================================================"
echo ""
echo "Security Group: $SECURITY_GROUP_NAME ($SECURITY_GROUP_ID)"
echo "Port: $PORT (TCP)"
echo "Source: 0.0.0.0/0"
echo ""
echo "Next Steps:"
echo "  1. Test connection: curl http://$STAGING_IP:$PORT/api/health"
echo "  2. Redeploy if needed: ./scripts/deploy-to-staging.sh"
echo ""
