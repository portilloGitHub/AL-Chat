# Add Security Group Rule for AL-Chat Backend Port 5000
# Usage: .\scripts\add-security-group-rule.ps1

$ErrorActionPreference = "Stop"

$STAGING_IP = "3.145.42.104"
$PORT = 5000

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Adding Security Group Rule for Port $PORT" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Find the EC2 instance and get its Security Group
Write-Host "[Step 1] Finding EC2 instance and Security Group..." -ForegroundColor Yellow

$instanceInfo = aws ec2 describe-instances `
    --filters "Name=ip-address,Values=$STAGING_IP" `
    --query "Reservations[0].Instances[0].[InstanceId,SecurityGroups[0].GroupId,SecurityGroups[0].GroupName]" `
    --output text 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to find EC2 instance" -ForegroundColor Red
    Write-Host $instanceInfo -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Check AWS CLI is configured: aws configure list" -ForegroundColor Gray
    Write-Host "  2. Verify instance IP: $STAGING_IP" -ForegroundColor Gray
    Write-Host "  3. Check AWS credentials and region" -ForegroundColor Gray
    exit 1
}

$instanceInfoArray = $instanceInfo -split "`t"
$instanceId = $instanceInfoArray[0]
$securityGroupId = $instanceInfoArray[1]
$securityGroupName = $instanceInfoArray[2]

if ([string]::IsNullOrWhiteSpace($securityGroupId)) {
    Write-Host "[ERROR] Could not find Security Group ID" -ForegroundColor Red
    Write-Host "Instance Info: $instanceInfo" -ForegroundColor Yellow
    exit 1
}

Write-Host "[OK] Found instance and security group" -ForegroundColor Green
Write-Host "   Instance ID: $instanceId" -ForegroundColor Gray
Write-Host "   Security Group ID: $securityGroupId" -ForegroundColor Gray
Write-Host "   Security Group Name: $securityGroupName" -ForegroundColor Gray
Write-Host ""

# Step 2: Check if rule already exists
Write-Host "[Step 2] Checking if rule already exists..." -ForegroundColor Yellow

$sgInfo = aws ec2 describe-security-groups `
    --group-ids $securityGroupId `
    --output json 2>&1 | ConvertFrom-Json

if ($LASTEXITCODE -eq 0) {
    $existingRule = $sgInfo.SecurityGroups[0].IpPermissions | Where-Object {
        $_.FromPort -eq $PORT -and $_.ToPort -eq $PORT -and $_.IpProtocol -eq "tcp"
    }
    
    if ($existingRule) {
        Write-Host "[INFO] Rule for port $PORT already exists" -ForegroundColor Yellow
        Write-Host "   Rule found in security group" -ForegroundColor Gray
        Write-Host ""
        Write-Host "[OK] No action needed - rule already exists" -ForegroundColor Green
        exit 0
    }
}

Write-Host "[OK] Rule does not exist - will create it" -ForegroundColor Green
Write-Host ""

# Step 3: Add the security group rule
Write-Host "[Step 3] Adding security group rule..." -ForegroundColor Yellow
Write-Host "   Port: $PORT" -ForegroundColor Gray
Write-Host "   Protocol: TCP" -ForegroundColor Gray
Write-Host "   Source: 0.0.0.0/0 (all IPs)" -ForegroundColor Gray
Write-Host ""

$result = aws ec2 authorize-security-group-ingress `
    --group-id $securityGroupId `
    --protocol tcp `
    --port $PORT `
    --cidr 0.0.0.0/0 `
    --output json 2>&1

if ($LASTEXITCODE -ne 0) {
    # Check if it's a duplicate rule error
    if ($result -match "already exists" -or $result -match "InvalidPermission.Duplicate") {
        Write-Host "[INFO] Rule already exists (duplicate)" -ForegroundColor Yellow
        Write-Host "[OK] Port $PORT is already allowed" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Failed to add security group rule" -ForegroundColor Red
        Write-Host $result -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "[OK] Security group rule added successfully" -ForegroundColor Green
    Write-Host "   Result: $result" -ForegroundColor Gray
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "[SUCCESS] Security Group Rule Added" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Security Group: $securityGroupName ($securityGroupId)" -ForegroundColor White
Write-Host "Port: $PORT (TCP)" -ForegroundColor White
Write-Host "Source: 0.0.0.0/0" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Test connection: curl http://$STAGING_IP`:$PORT/api/health" -ForegroundColor Cyan
Write-Host "  2. Redeploy if needed: ./scripts/deploy-to-staging.sh" -ForegroundColor Cyan
Write-Host ""
