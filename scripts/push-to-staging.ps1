# Push to staging branch with version tag
# Usage: .\scripts\push-to-staging.ps1 [version]
# Example: .\scripts\push-to-staging.ps1 0.1.0
# If version not provided, will increment patch version automatically

param(
    [Parameter(Position=0)]
    [string]$Version = ""
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Push to Staging with Version Tag" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Check if we're on master branch
$currentBranch = git branch --show-current
if ($currentBranch -ne "master") {
    Write-Host "Warning: You're not on master branch (currently on: $currentBranch)" -ForegroundColor Yellow
    $response = Read-Host "Do you want to continue? (y/n)"
    if ($response -ne "y") {
        Write-Host "Aborted" -ForegroundColor Red
        exit 0
    }
}

# Check if there are uncommitted changes
$status = git status --porcelain
if ($status) {
    Write-Host "Error: You have uncommitted changes. Please commit them first." -ForegroundColor Red
    Write-Host ""
    Write-Host "Uncommitted files:" -ForegroundColor Yellow
    git status --short
    exit 1
}

# Get latest tag version if not provided
if ([string]::IsNullOrWhiteSpace($Version)) {
    Write-Host "No version provided. Checking for latest tag..." -ForegroundColor Yellow
    
    $latestTag = git tag --sort=-version:refname | Select-Object -First 1
    
    if ($latestTag -and $latestTag -match "^v?(\d+)\.(\d+)\.(\d+)$") {
        $major = [int]$matches[1]
        $minor = [int]$matches[2]
        $patch = [int]$matches[3]
        $patch++
        $Version = "v$major.$minor.$patch"
        Write-Host "Incrementing patch version: $Version" -ForegroundColor Green
    } else {
        Write-Host "No existing version tag found. Using v0.1.0" -ForegroundColor Yellow
        $Version = "v0.1.0"
    }
} else {
    # Ensure version starts with 'v'
    if (-not $Version.StartsWith("v")) {
        $Version = "v$Version"
    }
}

Write-Host ""
Write-Host "Version: $Version" -ForegroundColor White
Write-Host ""

# Ensure master is up to date
Write-Host "Step 1: Ensuring master is up to date..." -ForegroundColor Yellow
git fetch origin master

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to fetch from origin" -ForegroundColor Red
    exit 1
}

Write-Host "Step 2: Switching to staging branch..." -ForegroundColor Yellow
git checkout staging

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to switch to staging branch" -ForegroundColor Red
    Write-Host "Make sure staging branch exists" -ForegroundColor Yellow
    exit 1
}

Write-Host "Step 3: Merging master into staging..." -ForegroundColor Yellow
git merge master --no-edit

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Merge failed. Resolve conflicts and try again." -ForegroundColor Red
    exit 1
}

Write-Host "Step 4: Pushing staging branch to origin..." -ForegroundColor Yellow
git push origin staging

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to push staging branch" -ForegroundColor Red
    exit 1
}

Write-Host "Step 5: Creating and pushing version tag..." -ForegroundColor Yellow
git tag -a $Version -m "Release $Version - Staging deployment"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to create tag" -ForegroundColor Red
    exit 1
}

git push origin $Version

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to push tag" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Push to Staging Complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Version Tag: $Version" -ForegroundColor White
Write-Host "Branch: staging" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Build and push Docker images:" -ForegroundColor Gray
Write-Host "      .\scripts\deploy-full.ps1 staging" -ForegroundColor Cyan
Write-Host ""
Write-Host "   2. Deploy to EC2 staging (SSH to EC2 and run deployment commands)" -ForegroundColor Gray
Write-Host ""
