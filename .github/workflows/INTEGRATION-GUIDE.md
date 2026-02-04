# Notion Sync Integration Guide

## Quick Start (5 Minutes)

### Step 1: Get Notion API Key (2 min)

1. Go to: https://www.notion.so/my-integrations
2. Click **"+ New integration"**
3. Settings:
   - **Name**: `TAG IT GitHub Sync`
   - **Workspace**: `TAG IT Network Workspace`
   - **Capabilities**: ✅ Read content, ✅ Update content
4. Submit → **Copy the token**

### Step 2: Share Database with Integration (1 min)

1. Open **TAG IT Network Tasks** database in Notion
2. Click **"..."** → **"Connect to"** → Select **"TAG IT GitHub Sync"**
3. Confirm access

### Step 3: Configure GitHub Secrets (2 min)

```bash
# Set Notion API key
gh secret set NOTION_API_KEY --repo TAG-IT-NETWORK/tagit-contracts

# Paste your token when prompted
```

Optional webhook secret for enhanced security:
```bash
# Generate secret
SECRET=$(openssl rand -hex 32)

# Set secret
gh secret set GITHUB_WEBHOOK_SECRET --repo TAG-IT-NETWORK/tagit-contracts --body "$SECRET"
```

### Step 4: Deploy Workflow

**Option A: Single Repository**
```bash
cd C:/tagcode/tagit-governance
cp .github/workflows/notion-sync.yml ../tagit-contracts/.github/workflows/
cd ../tagit-contracts
git add .github/workflows/notion-sync.yml
git commit -m "feat: Add GitHub ↔ Notion real-time sync"
git push
```

**Option B: All 12 Repositories (Automated)**
```bash
cd C:/tagcode/tagit-governance/.github/workflows
./deploy-to-all-repos.sh --dry-run  # Preview changes
./deploy-to-all-repos.sh            # Deploy
```

### Step 5: Verify Installation

```bash
# Check workflow exists
gh workflow list --repo TAG-IT-NETWORK/tagit-contracts | grep "Notion Sync"

# Test with manual trigger
gh workflow run notion-sync.yml --repo TAG-IT-NETWORK/tagit-contracts -f test_mode=true

# View run status
gh run list --workflow=notion-sync.yml --repo TAG-IT-NETWORK/tagit-contracts
```

## How It Works

### Trigger Flow

```
GitHub PR Event (opened/closed/merged)
    │
    ├─► Webhook → GitHub Actions
    │
    ├─► Validate HMAC signature
    │
    ├─► Extract PR metadata
    │   (number, title, state, author, URL)
    │
    ├─► Map GitHub state → Notion status
    │   opened → "In Review"
    │   merged → "Complete"
    │   closed → "Cancelled"
    │
    ├─► Search Notion for task
    │   Filter: PR Link = {PR URL}
    │
    └─► Update Notion task
        Status: {mapped status}
        Notes: Append output
```

### Status Mapping Reference

| GitHub Action | PR State | Notion Status |
|---------------|----------|---------------|
| `opened` | open | **In Review** |
| `ready_for_review` | open | **In Review** |
| `draft` | open | **In Progress** |
| `closed` (merged) | closed | **Complete** |
| `closed` (not merged) | closed | **Cancelled** |
| `synchronize` | open | **In Progress** |

### Notion Database Requirements

Your Notion Tasks database must have these fields:

| Field Name | Type | Required | Description |
|------------|------|----------|-------------|
| **Task** | Title | ✅ Yes | Task name/title |
| **Status** | Status | ✅ Yes | Current status (Not Started, In Progress, In Review, Complete, etc.) |
| **PR Link** | URL | ✅ Yes | GitHub PR URL (used for matching) |
| **Notes** | Rich Text | Recommended | Instructions + agent output |
| **Repo** | Select | Recommended | Target repository name |
| **Type** | Select | Optional | Task type (Feature, Bug, etc.) |
| **Priority** | Select | Optional | P0/P1/P2/P3 |

## Testing Checklist

### Pre-Deployment Testing

- [ ] Run test script: `./test-notion-sync.sh`
- [ ] Validate YAML syntax
- [ ] Check Notion API connectivity
- [ ] Verify secrets are set

### Post-Deployment Testing

- [ ] Manual trigger test (test mode)
  ```bash
  gh workflow run notion-sync.yml -f test_mode=true
  ```

- [ ] Create test PR
  ```bash
  git checkout -b test/notion-sync
  echo "test" > test.txt
  git add test.txt
  git commit -m "test: Notion sync"
  git push -u origin test/notion-sync
  gh pr create --title "TEST: Notion Sync" --body "Testing sync"
  ```

- [ ] Verify in Notion:
  - Task created or updated
  - Status changed to "In Review"
  - PR Link populated

- [ ] Merge PR
  ```bash
  gh pr merge --squash
  ```

- [ ] Verify status changed to "Complete"

- [ ] Clean up
  ```bash
  git checkout main
  git branch -D test/notion-sync
  ```

## Troubleshooting

### Problem: "NOTION_API_KEY not configured"

**Solution**: Set the secret in GitHub repository settings.
```bash
gh secret set NOTION_API_KEY --repo TAG-IT-NETWORK/<repo>
```

### Problem: "No existing task found"

**Cause**: Task doesn't have PR Link field set, or URL doesn't match.

**Solution**:
1. Check task in Notion has PR Link field
2. Ensure PR Link exactly matches GitHub PR URL
3. Or create new task with correct PR Link

### Problem: "Rate limited"

**Cause**: Too many requests to Notion API (limit: 3/second).

**Solution**: Workflow automatically retries after rate limit expires. No action needed.

### Problem: "Workflow not triggering"

**Checks**:
1. Is workflow file committed and pushed?
   ```bash
   git log --oneline | grep "notion-sync"
   ```

2. Are secrets configured?
   ```bash
   gh secret list --repo TAG-IT-NETWORK/<repo>
   ```

3. Is workflow enabled?
   ```bash
   gh workflow list --repo TAG-IT-NETWORK/<repo>
   ```

4. Check workflow runs:
   ```bash
   gh run list --workflow=notion-sync.yml --repo TAG-IT-NETWORK/<repo> --limit 5
   ```

### Problem: "Webhook signature validation failed"

**Solution**:
1. Regenerate webhook secret:
   ```bash
   openssl rand -hex 32
   ```

2. Update in GitHub:
   ```bash
   gh secret set GITHUB_WEBHOOK_SECRET --repo TAG-IT-NETWORK/<repo>
   ```

## Deployment to All 12 Repos

### Automated Deployment

```bash
cd C:/tagcode/tagit-governance/.github/workflows

# Dry run (preview)
./deploy-to-all-repos.sh --dry-run

# Deploy
./deploy-to-all-repos.sh

# Or PowerShell on Windows
.\deploy-to-all-repos.ps1 -DryRun
.\deploy-to-all-repos.ps1
```

### Batch Secret Configuration

```bash
# Set NOTION_API_KEY for all repos
for repo in tagit-contracts tagit-l2 tagit-bridge tagit-services \
            tagit-indexer tagit-security tagit-dashboard tagit-mobile \
            tagit-sdk tagit-hardware tagit-docs tagit-governance; do
  echo "Setting secrets for $repo..."
  gh secret set NOTION_API_KEY --repo TAG-IT-NETWORK/$repo
  # Paste token when prompted
done
```

### Verify All Deployments

```bash
# Check all workflows
for repo in tagit-contracts tagit-l2 tagit-bridge tagit-services \
            tagit-indexer tagit-security tagit-dashboard tagit-mobile \
            tagit-sdk tagit-hardware tagit-docs tagit-governance; do
  echo "=== $repo ==="
  gh workflow list --repo TAG-IT-NETWORK/$repo | grep "Notion Sync" || echo "Not found"
done
```

## Architecture Diagrams

### High-Level Flow

```
┌──────────────┐
│   GitHub     │
│   (PR Event) │
└──────┬───────┘
       │
       │ Webhook
       │
       ▼
┌─────────────────────────┐
│  GitHub Actions Runner  │
│  ┌───────────────────┐  │
│  │ Validate Webhook  │  │
│  └─────────┬─────────┘  │
│            │             │
│  ┌─────────▼─────────┐  │
│  │ Extract Metadata  │  │
│  │ - PR #            │  │
│  │ - Title           │  │
│  │ - State           │  │
│  │ - Author          │  │
│  │ - URL             │  │
│  └─────────┬─────────┘  │
│            │             │
│  ┌─────────▼─────────┐  │
│  │ Search Notion DB  │  │
│  │ by PR Link        │  │
│  └─────────┬─────────┘  │
│            │             │
│  ┌─────────▼─────────┐  │
│  │ Update Status     │  │
│  └───────────────────┘  │
└─────────────────────────┘
       │
       │ Notion API
       │
       ▼
┌──────────────┐
│   Notion     │
│  Tasks DB    │
└──────────────┘
```

### Error Handling Flow

```
┌─────────────┐
│ API Request │
└──────┬──────┘
       │
       ├─► Success (200) → Continue
       │
       ├─► Rate Limited (429)
       │   └─► Wait Retry-After seconds
       │       └─► Retry
       │
       ├─► Auth Error (401)
       │   └─► Log error
       │       └─► Exit
       │
       └─► Other Error
           └─► Retry (max 3 times)
               └─► If still fails → Log & Exit
```

## Monitoring & Maintenance

### Daily Checks

```bash
# Check failed runs in last 24h
gh run list --workflow=notion-sync.yml --status=failure --created=$(date -d '24 hours ago' +%Y-%m-%d) --repo TAG-IT-NETWORK/tagit-contracts

# View logs for failed run
gh run view <run_id> --log
```

### Weekly Review

- [ ] Review failure rate
- [ ] Check for rate limit issues
- [ ] Verify all repos have workflow enabled
- [ ] Test manual trigger on one repo

### Monthly Maintenance

- [ ] Rotate Notion API key (recommended every 90 days)
- [ ] Update workflow if GitHub Actions or Notion API changes
- [ ] Review and update status mappings if needed

## Security Best Practices

1. **Secrets Management**
   - Never commit secrets to git
   - Use GitHub encrypted secrets
   - Rotate API keys every 90 days
   - Audit secret access logs monthly

2. **Webhook Validation**
   - Always use HMAC signature validation in production
   - Regenerate webhook secret if compromised
   - Monitor for validation failures

3. **Notion Permissions**
   - Integration should have minimal permissions
   - Only **Read** and **Update** (no Insert/Delete)
   - Regularly audit integration access

4. **Access Control**
   - Limit who can modify workflow files
   - Use branch protection on main/master
   - Require PR reviews for workflow changes

## Performance Optimization

### Current Performance

- **Trigger latency**: < 5 seconds
- **Execution time**: 30-60 seconds
- **API calls per event**: 2 (search + update)
- **Concurrent limit**: GitHub Actions default

### Optimization Tips

1. **Reduce API Calls**
   - Cache Notion page IDs (if possible)
   - Batch updates (if processing multiple events)

2. **Improve Speed**
   - Use Python instead of bash/curl where possible
   - Parallel processing for multiple repos
   - Optimize retry delays

3. **Cost Reduction**
   - Use `ubuntu-latest` (cheapest runner)
   - Skip unnecessary steps with conditionals
   - Cache dependencies (pip packages)

## FAQ

**Q: Can I customize the status mappings?**

A: Yes! Edit the "Determine Notion status" step in `notion-sync.yml`:
```yaml
- name: Determine Notion status
  id: notion_status
  run: |
    if [ "${{ steps.pr_metadata.outputs.pr_merged }}" == "true" ]; then
      echo "status=Your Custom Status" >> $GITHUB_OUTPUT
    fi
```

**Q: Can I sync to multiple Notion databases?**

A: Yes, modify the `NOTION_TASKS_DB_ID` env var or parameterize by repo.

**Q: Does this work with private repositories?**

A: Yes! The workflow works with both public and private repos.

**Q: Can I sync from Notion back to GitHub?**

A: Not in this version. This is **GitHub → Notion** only. Bidirectional sync requires additional webhook setup in Notion.

**Q: What happens if Notion is down?**

A: The workflow will retry 3 times with exponential backoff, then fail gracefully with logs.

## Support

- **Documentation**: See README.md in this directory
- **Test Script**: Run `./test-notion-sync.sh` for diagnostics
- **GitHub Issues**: Report issues with `notion-sync` label
- **Contact**: TAG IT Network team

---

**Version**: 1.0
**Last Updated**: 2026-02-03
**Author**: TAG IT Network | Sage AI Engine
