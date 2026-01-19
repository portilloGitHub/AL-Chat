# Versioning Schema for AL-Chat

## Version Format

**Format:** `vx.x.x-alchat-staging`

- **v** - Version prefix
- **x.x.x** - Semantic versioning (Major.Minor.Patch)
- **-alchat-staging** - Project identifier and environment

## Semantic Versioning

- **Major (x.0.0)**: Breaking changes, major architecture changes
  - Example: `v2.0.0-alchat-staging` - Complete rewrite or major API changes
  
- **Minor (0.x.0)**: New features, backwards compatible
  - Example: `v1.1.0-alchat-staging` - New API endpoints, new features
  
- **Patch (0.0.x)**: Bug fixes, backwards compatible
  - Example: `v1.0.1-alchat-staging` - Bug fixes, minor improvements

## Release Process

### Creating a Release Tag

```bash
# Tag current commit
git tag -a v1.0.0-alchat-staging -m "Release v1.0.0-alchat-staging - Description"

# Push tag to GitHub
git push origin v1.0.0-alchat-staging
```

### Version History

- **v1.0.2-alchat-staging** - Hotfix: Security Group automation
  - Added AWS CLI scripts to automate Security Group rule creation
  - Added container restart scripts for staging management
  - Added troubleshooting documentation for connection issues
  - Fixes connection timeout by automating port 5000 Security Group rule
  - Scripts: add-security-group-rule.ps1/sh, restart-staging.sh/ps1

- **v1.0.1-alchat-staging** - Fix staging port configuration
  - Changed staging port from 5001 to 5000 (matches main website)
  - Updated all deployment scripts for port 5000
  - Added staging integration documentation
  - Fixes connection issue with main website

- **v1.0.0-alchat-staging** - Backend-only API service
  - Removed frontend/GUI components
  - Integrated with Papita API for credentials
  - Updated Docker and deployment scripts
  - All GUI handled by main website project

## Best Practices

1. **Tag after major milestones**: Tag when significant changes are complete
2. **Use descriptive messages**: Include what changed in the tag message
3. **Tag on staging branch**: All releases are tagged on staging
4. **Merge to master**: After tagging, merge staging to master
5. **Document changes**: Update this file with version history

## Example Workflow

```bash
# 1. Make changes on staging branch
git checkout staging
# ... make changes ...

# 2. Commit changes
git add .
git commit -m "Add new feature"

# 3. Create version tag
git tag -a v1.1.0-alchat-staging -m "Release v1.1.0-alchat-staging - New feature"

# 4. Push tag
git push origin v1.1.0-alchat-staging

# 5. Merge to master
git checkout master
git merge staging
git push origin master
```

## Version Comparison

When comparing versions, use semantic versioning rules:
- `v1.0.0` < `v1.0.1` < `v1.1.0` < `v2.0.0`
- Always compare the numeric part (x.x.x), ignore the suffix

## Notes

- All versions use the `-alchat-staging` suffix for consistency
- Tags are created on the staging branch
- After tagging, merge to master to keep branches synchronized
- Use GitHub Releases feature to create release notes from tags
