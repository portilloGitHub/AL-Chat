# AL-Chat Deployment Workflow

## Workflow Overview

1. **Local Development** - Work and test locally
2. **Push to Master** - Commit and push to master branch
3. **Push to Staging** - Merge master to staging with version tag

## Step-by-Step Process

### Step 1: Local Development and Testing

Work on your local machine and test:

```powershell
# Make changes, test locally
# When ready to commit:
git add .
git commit -m "Your commit message"
```

### Step 2: Push to Master Branch

```powershell
# Make sure you're on master
git checkout master

# Push to master
git push origin master
```

### Step 3: Push to Staging with Version Tag

**Option A: Use script (recommended):**
```powershell
.\scripts\push-to-staging.ps1 [version]
```

**Examples:**
```powershell
# Auto-increment patch version (v0.1.0 -> v0.1.1)
.\scripts\push-to-staging.ps1

# Specify version manually
.\scripts\push-to-staging.ps1 0.2.0
```

**Option B: Manual:**
```powershell
# Switch to staging
git checkout staging

# Merge master
git merge master

# Tag with version
git tag -a v0.1.0 -m "Release v0.1.0 - Staging deployment"

# Push staging and tag
git push origin staging
git push origin v0.1.0
```

### Step 4: Deploy to Staging

After pushing to staging:

```powershell
# Build and push Docker images
.\scripts\deploy-full.ps1 staging

# Then SSH to EC2 and deploy containers
# (see FULL_STAGING_WORKFLOW.md for EC2 deployment commands)
```

## Version Tagging

Version tags follow semantic versioning:
- `v0.1.0` - Major.Minor.Patch
- Increment:
  - **Patch** (0.1.0 → 0.1.1): Bug fixes, small changes
  - **Minor** (0.1.0 → 0.2.0): New features, backwards compatible
  - **Major** (0.1.0 → 1.0.0): Breaking changes

**Auto-increment:** If you don't specify a version, the script will:
1. Find the latest tag (e.g., `v0.1.0`)
2. Increment the patch version (→ `v0.1.1`)

## Complete Workflow Example

```powershell
# 1. Make changes and test locally
# ... make code changes ...

# 2. Commit and push to master
git add .
git commit -m "Add new feature"
git push origin master

# 3. Push to staging with version tag
.\scripts\push-to-staging.ps1 0.2.0

# 4. Deploy to staging
.\scripts\deploy-full.ps1 staging

# 5. SSH to EC2 and deploy containers
# ... deploy commands ...
```

## Viewing Tags

```powershell
# List all tags
git tag

# List tags matching pattern
git tag -l "v0.*"

# Show tag details
git show v0.1.0
```

## Notes

- **Master branch:** Your main development branch
- **Staging branch:** Mirrors master but tagged with versions for tracking
- **Tags:** Used to track which version is deployed to staging
- **Never commit directly to staging:** Always merge from master

## Quick Reference

```powershell
# Complete workflow
git checkout master
git add .
git commit -m "Changes"
git push origin master
.\scripts\push-to-staging.ps1
.\scripts\deploy-full.ps1 staging
```
