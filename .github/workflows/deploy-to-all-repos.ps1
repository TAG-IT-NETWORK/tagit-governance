# =============================================================================
# DEPLOY NOTION-SYNC WORKFLOW TO ALL 12 TAG IT REPOS (PowerShell)
# =============================================================================
# Usage: .\deploy-to-all-repos.ps1 [-DryRun]
# =============================================================================

param(
    [switch]$DryRun
)

# Configuration
$WorkspaceRoot = if ($env:WORKSPACE_ROOT) { $env:WORKSPACE_ROOT } else { "C:\tagcode" }
$SourceWorkflow = Join-Path $WorkspaceRoot "tagit-governance\.github\workflows\notion-sync.yml"

# All 12 TAG IT repositories
$Repos = @(
    "tagit-contracts",
    "tagit-l2",
    "tagit-bridge",
    "tagit-services",
    "tagit-indexer",
    "tagit-security",
    "tagit-dashboard",
    "tagit-mobile",
    "tagit-sdk",
    "tagit-hardware",
    "tagit-docs",
    "tagit-governance"
)

# Functions
function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Success { param($Message) Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

# Validation
if (-not (Test-Path $SourceWorkflow)) {
    Write-Error "Source workflow not found: $SourceWorkflow"
    exit 1
}

Write-Info "=== TAG IT Network - Notion Sync Deployment ==="
Write-Info "Source: $SourceWorkflow"
Write-Info "Workspace: $WorkspaceRoot"
Write-Info "Repositories: $($Repos.Count)"
if ($DryRun) {
    Write-Warning "DRY RUN MODE - No files will be modified"
}
Write-Host ""

# Deploy to each repo
$Deployed = 0
$Skipped = 0
$Failed = 0

foreach ($repo in $Repos) {
    Write-Host "-----------------------------------"
    Write-Info "Processing: $repo"

    $RepoPath = Join-Path $WorkspaceRoot $repo
    $WorkflowsDir = Join-Path $RepoPath ".github\workflows"
    $TargetFile = Join-Path $WorkflowsDir "notion-sync.yml"

    # Check if repo exists
    if (-not (Test-Path $RepoPath)) {
        Write-Warning "Repository not found: $RepoPath"
        $Skipped++
        continue
    }

    # Create workflows directory if needed
    if (-not $DryRun) {
        if (-not (Test-Path $WorkflowsDir)) {
            New-Item -ItemType Directory -Path $WorkflowsDir -Force | Out-Null
        }
    } else {
        Write-Info "Would create: $WorkflowsDir"
    }

    # Check if workflow already exists
    if (Test-Path $TargetFile) {
        Write-Warning "Workflow already exists: $TargetFile"
        $Overwrite = Read-Host "Overwrite? (y/N)"
        if ($Overwrite -ne "y" -and $Overwrite -ne "Y") {
            Write-Info "Skipped: $repo"
            $Skipped++
            continue
        }
    }

    # Copy workflow file
    if (-not $DryRun) {
        try {
            Copy-Item $SourceWorkflow $TargetFile -Force
            Write-Success "Deployed to: $repo"
            $Deployed++

            # Check if repo is a git repo
            if (Test-Path (Join-Path $RepoPath ".git")) {
                Push-Location $RepoPath

                # Check if there are changes
                $GitDiff = git diff --quiet .github\workflows\notion-sync.yml 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Info "No changes detected (file identical)"
                } else {
                    Write-Info "Changes detected, ready to commit"
                }

                Pop-Location
            }
        } catch {
            Write-Error "Failed to deploy to: $repo - $_"
            $Failed++
        }
    } else {
        Write-Info "Would copy to: $TargetFile"
        $Deployed++
    }
}

# Summary
Write-Host ""
Write-Host "==================================="
Write-Info "=== DEPLOYMENT SUMMARY ==="
Write-Success "Deployed: $Deployed"
Write-Warning "Skipped: $Skipped"
if ($Failed -gt 0) {
    Write-Error "Failed: $Failed"
}
Write-Host "==================================="

if ($DryRun) {
    Write-Host ""
    Write-Warning "DRY RUN COMPLETE - No files were modified"
    Write-Info "Run without -DryRun to perform actual deployment"
}

# Next steps
if ($Deployed -gt 0 -and -not $DryRun) {
    Write-Host ""
    Write-Info "=== NEXT STEPS ==="
    Write-Host "1. Review changes in each repository"
    Write-Host "2. Commit and push:"
    Write-Host "   git add .github/workflows/notion-sync.yml"
    Write-Host '   git commit -m "feat: Add GitHub ↔ Notion real-time sync"'
    Write-Host "   git push"
    Write-Host ""
    Write-Host "3. Configure secrets for each repo:"
    Write-Host "   gh secret set NOTION_API_KEY --repo TAG-IT-NETWORK/<repo>"
    Write-Host "   gh secret set GITHUB_WEBHOOK_SECRET --repo TAG-IT-NETWORK/<repo>"
    Write-Host ""
    Write-Host "4. Test with manual trigger:"
    Write-Host "   gh workflow run notion-sync.yml --repo TAG-IT-NETWORK/<repo>"
}

exit 0
