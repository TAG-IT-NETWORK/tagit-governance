# GitHub Actions: Notion Sync Workflow

## Overview

The `notion-sync.yml` workflow provides **real-time bidirectional sync** between GitHub events (PRs, Issues) and the Notion Tasks database for TAG IT Network.

## Features

✅ **Webhook-triggered updates** - Automatically syncs on PR/Issue events
✅ **HMAC signature validation** - Secure webhook authentication
✅ **Retry logic** - Handles rate limits and transient failures
✅ **Error handling** - Comprehensive error logging and recovery
✅ **Test mode** - Manual testing without actual updates
✅ **Status mapping** - Intelligent GitHub → Notion status translation

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    GITHUB ↔ NOTION SYNC                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   GitHub Event (PR/Issue)                                        │
│         │                                                        │
│         ├─► Webhook Validation (HMAC)                            │
│         │                                                        │
│         ├─► Extract Metadata                                     │
│         │   (PR #, title, state, author, repo)                   │
│         │                                                        │
│         ├─► Map Status                                           │
│         │   (GitHub state → Notion status)                       │
│         │                                                        │
│         ├─► Search Notion DB                                     │
│         │   (Find task by PR Link URL)                           │
│         │                                                        │
│         └─► Update Notion Task                                   │
│             (Status, Notes, metadata)                            │
│                                                                  │
│   [Retry Logic: 3 attempts, 5s delay]                           │
│   [Rate Limit Handling: Respect Retry-After header]             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Status Mapping

| GitHub Event | GitHub State | Notion Status |
|--------------|--------------|---------------|
| PR opened | open | In Review |
| PR ready_for_review | open | In Review |
| PR draft | open | In Progress |
| PR merged | closed (merged=true) | Complete |
| PR closed (not merged) | closed | Cancelled |
| Issue opened | open | Not Started |
| Issue assigned | open | In Progress |
| Issue closed | closed | Complete |

## Setup Instructions

### 1. Configure Secrets

Add the following secrets to your GitHub repository:

**Settings → Secrets and variables → Actions → New repository secret**

| Secret Name | Description | Required |
|-------------|-------------|----------|
| `NOTION_API_KEY` | Notion integration token | ✅ Yes |
| `GITHUB_WEBHOOK_SECRET` | HMAC secret for webhook validation | Recommended |

#### Getting Notion API Key

1. Go to [https://www.notion.so/my-integrations](https://www.notion.so/my-integrations)
2. Click **"+ New integration"**
3. Name: `TAG IT GitHub Sync`
4. Associated workspace: `TAG IT Network Workspace`
5. Capabilities: **Read content**, **Update content** (no Insert)
6. Submit → Copy the **Internal Integration Token**

#### Share Database with Integration

1. Open the **TAG IT Network Tasks** database in Notion
2. Click **"..."** (top right) → **"Connect to"**
3. Select **"TAG IT GitHub Sync"** integration
4. Confirm access

#### Generating Webhook Secret (Optional)

```bash
# Generate a secure random secret
openssl rand -hex 32
```

Save this value as `GITHUB_WEBHOOK_SECRET` in GitHub secrets.

### 2. Deploy to Repository

Copy `.github/workflows/notion-sync.yml` to your target repository:

```bash
# From tagit-governance
cp .github/workflows/notion-sync.yml /path/to/target-repo/.github/workflows/

# Commit and push
cd /path/to/target-repo
git add .github/workflows/notion-sync.yml
git commit -m "feat: Add GitHub ↔ Notion real-time sync

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
git push
```

### 3. Verify Installation

1. **Check workflow file**:
   ```bash
   gh workflow list
   ```
   Should show: `Notion Sync - GitHub ↔ Notion Real-Time`

2. **Test with manual trigger**:
   ```bash
   gh workflow run notion-sync.yml --input test_mode=true
   ```

3. **Check run status**:
   ```bash
   gh run list --workflow=notion-sync.yml
   ```

### 4. Deploy Across All 12 Repos

Use the provided automation script:

```bash
# From C:\tagcode\_automation
./scripts/deploy-notion-sync.sh

# Or manually for each repo:
for repo in tagit-contracts tagit-l2 tagit-bridge tagit-services \
            tagit-indexer tagit-security tagit-dashboard tagit-mobile \
            tagit-sdk tagit-hardware tagit-docs tagit-governance; do
  cp ../tagit-governance/.github/workflows/notion-sync.yml ../$repo/.github/workflows/
  echo "Deployed to $repo"
done
```

## Testing

### Manual Test (No Updates)

```bash
gh workflow run notion-sync.yml --input test_mode=true
```

This will:
- ✅ Validate secrets
- ✅ Search Notion for matching tasks
- ✅ Log what would be updated
- ❌ **NOT** make actual changes

### Live Test with PR

1. Create a test branch:
   ```bash
   git checkout -b test/notion-sync
   echo "test" > test.txt
   git add test.txt
   git commit -m "test: Notion sync"
   git push -u origin test/notion-sync
   ```

2. Create PR:
   ```bash
   gh pr create --title "TEST: Notion Sync" --body "Testing real-time sync"
   ```

3. Verify in Notion:
   - Task should appear or update with status **"In Review"**
   - PR Link field should contain the PR URL

4. Merge PR:
   ```bash
   gh pr merge --squash
   ```

5. Verify status changed to **"Complete"** in Notion

### Debug Failed Runs

```bash
# View recent runs
gh run list --workflow=notion-sync.yml --limit 5

# View specific run
gh run view <run_id>

# Download logs
gh run view <run_id> --log > notion-sync.log
```

## Webhook Signature Validation

The workflow validates GitHub webhook signatures using HMAC-SHA256:

1. **GitHub** sends `X-Hub-Signature-256` header with HMAC of payload
2. **Workflow** calculates HMAC using `GITHUB_WEBHOOK_SECRET`
3. **Compare** signatures to ensure authenticity

If `GITHUB_WEBHOOK_SECRET` is not configured, validation is skipped (not recommended for production).

## Error Handling

### Retry Logic

- **Max retries**: 3 attempts
- **Retry delay**: 5 seconds
- **Exponential backoff**: Optional (can be configured)

### Rate Limiting

- **Detection**: Checks for HTTP 429 status
- **Response**: Waits for `Retry-After` header duration
- **Fallback**: 5-second default wait

### Failure Notifications

On repeated failures, the workflow can:
1. Log detailed error information
2. Create GitHub issue (disabled by default)
3. Send Slack notification (if configured)

Enable auto-issue creation by changing:
```yaml
- name: Create issue on repeated failures
  if: false  # Change to true
```

## Performance

| Metric | Value |
|--------|-------|
| **Trigger latency** | < 5 seconds (GitHub webhook delay) |
| **Execution time** | 30-60 seconds (typical) |
| **Notion API calls** | 2 per event (search + update) |
| **Rate limit** | 3 requests/second (Notion limit) |

## Troubleshooting

### Issue: "NOTION_API_KEY not configured"

**Solution**: Add Notion integration token to GitHub secrets.

```bash
gh secret set NOTION_API_KEY
# Paste token when prompted
```

### Issue: "No existing task found"

**Cause**: Notion task doesn't have PR Link field populated.

**Solution**:
1. Ensure `notion_openhands_agent.py` creates PR Link when creating PR
2. Or manually add PR URL to task's PR Link field in Notion

### Issue: "Rate limited"

**Cause**: Too many requests to Notion API.

**Solution**:
- Workflow automatically handles this with `Retry-After` header
- Check logs to verify retry is working
- Consider adding delays between deployments across repos

### Issue: "Webhook validation failed"

**Cause**: `GITHUB_WEBHOOK_SECRET` mismatch or not configured.

**Solution**:
- Verify secret is correctly set in GitHub
- Regenerate secret if needed
- Or disable validation (not recommended)

## Monitoring

### View Workflow Status

```bash
# All repos
gh workflow list --repo TAG-IT-NETWORK/tagit-contracts
gh workflow list --repo TAG-IT-NETWORK/tagit-dashboard
# ... repeat for all 12 repos

# Or use gh CLI to query all at once
for repo in $(gh repo list TAG-IT-NETWORK --limit 100 --json name -q '.[].name'); do
  echo "=== $repo ==="
  gh workflow list --repo TAG-IT-NETWORK/$repo | grep "Notion Sync"
done
```

### Check Recent Runs

```bash
gh run list --workflow=notion-sync.yml --limit 10 --json conclusion,status,createdAt
```

### Success Metrics

Track these metrics over time:
- **Success rate**: % of successful syncs
- **Average duration**: Time to complete sync
- **Retry rate**: % of syncs requiring retries
- **Error types**: Common failure patterns

## Security Considerations

1. **Secrets Management**
   - Never commit secrets to git
   - Rotate `NOTION_API_KEY` every 90 days
   - Use GitHub encrypted secrets

2. **Webhook Validation**
   - Always use `GITHUB_WEBHOOK_SECRET` in production
   - Regenerate secret if compromised
   - Monitor for validation failures

3. **Notion Permissions**
   - Integration should have minimal permissions
   - Only **Read** and **Update** capabilities
   - No **Insert** or **Delete** permissions

4. **Rate Limiting**
   - Respect Notion API limits (3 req/s)
   - Implement exponential backoff
   - Monitor for rate limit errors

## Future Enhancements

- [ ] Bidirectional sync (Notion → GitHub)
- [ ] Slack notifications on status changes
- [ ] Dashboard for sync metrics
- [ ] Support for GitHub Projects
- [ ] Custom field mappings
- [ ] Conflict resolution strategies

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Notion API Reference](https://developers.notion.com/reference/intro)
- [GitHub Webhooks](https://docs.github.com/en/webhooks)
- [HMAC Signature Validation](https://docs.github.com/en/webhooks/using-webhooks/validating-webhook-deliveries)

## Support

For issues or questions:
1. Check logs: `gh run view <run_id> --log`
2. Review [Troubleshooting](#troubleshooting) section
3. Open issue: `gh issue create --title "Notion Sync: <issue>" --label automation`

---

**Version**: 1.0
**Last Updated**: 2026-02-03
**Author**: TAG IT Network | Sage AI Engine
**Repository**: tagit-governance
