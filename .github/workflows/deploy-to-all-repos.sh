#!/bin/bash
# =============================================================================
# DEPLOY NOTION-SYNC WORKFLOW TO ALL 12 TAG IT REPOS
# =============================================================================
# Usage: ./deploy-to-all-repos.sh [--dry-run]
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
WORKSPACE_ROOT="${WORKSPACE_ROOT:-C:/tagcode}"
SOURCE_WORKFLOW="$WORKSPACE_ROOT/tagit-governance/.github/workflows/notion-sync.yml"
DRY_RUN=false

# All 12 TAG IT repositories
REPOS=(
    "tagit-contracts"
    "tagit-l2"
    "tagit-bridge"
    "tagit-services"
    "tagit-indexer"
    "tagit-security"
    "tagit-dashboard"
    "tagit-mobile"
    "tagit-sdk"
    "tagit-hardware"
    "tagit-docs"
    "tagit-governance"
)

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validation
if [ ! -f "$SOURCE_WORKFLOW" ]; then
    log_error "Source workflow not found: $SOURCE_WORKFLOW"
    exit 1
fi

log_info "=== TAG IT Network - Notion Sync Deployment ==="
log_info "Source: $SOURCE_WORKFLOW"
log_info "Workspace: $WORKSPACE_ROOT"
log_info "Repositories: ${#REPOS[@]}"
if [ "$DRY_RUN" = true ]; then
    log_warning "DRY RUN MODE - No files will be modified"
fi
echo ""

# Deploy to each repo
DEPLOYED=0
SKIPPED=0
FAILED=0

for repo in "${REPOS[@]}"; do
    echo "-----------------------------------"
    log_info "Processing: $repo"

    REPO_PATH="$WORKSPACE_ROOT/$repo"
    WORKFLOWS_DIR="$REPO_PATH/.github/workflows"
    TARGET_FILE="$WORKFLOWS_DIR/notion-sync.yml"

    # Check if repo exists
    if [ ! -d "$REPO_PATH" ]; then
        log_warning "Repository not found: $REPO_PATH"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    # Create workflows directory if needed
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$WORKFLOWS_DIR"
    else
        log_info "Would create: $WORKFLOWS_DIR"
    fi

    # Check if workflow already exists
    if [ -f "$TARGET_FILE" ]; then
        log_warning "Workflow already exists: $TARGET_FILE"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipped: $repo"
            SKIPPED=$((SKIPPED + 1))
            continue
        fi
    fi

    # Copy workflow file
    if [ "$DRY_RUN" = false ]; then
        if cp "$SOURCE_WORKFLOW" "$TARGET_FILE"; then
            log_success "Deployed to: $repo"
            DEPLOYED=$((DEPLOYED + 1))

            # Check if repo is a git repo
            if [ -d "$REPO_PATH/.git" ]; then
                cd "$REPO_PATH"

                # Check if there are changes
                if git diff --quiet .github/workflows/notion-sync.yml 2>/dev/null; then
                    log_info "No changes detected (file identical)"
                else
                    log_info "Changes detected, ready to commit"
                fi

                cd "$WORKSPACE_ROOT"
            fi
        else
            log_error "Failed to deploy to: $repo"
            FAILED=$((FAILED + 1))
        fi
    else
        log_info "Would copy to: $TARGET_FILE"
        DEPLOYED=$((DEPLOYED + 1))
    fi
done

# Summary
echo ""
echo "==================================="
log_info "=== DEPLOYMENT SUMMARY ==="
log_success "Deployed: $DEPLOYED"
log_warning "Skipped: $SKIPPED"
if [ $FAILED -gt 0 ]; then
    log_error "Failed: $FAILED"
fi
echo "==================================="

if [ "$DRY_RUN" = true ]; then
    echo ""
    log_warning "DRY RUN COMPLETE - No files were modified"
    log_info "Run without --dry-run to perform actual deployment"
fi

# Next steps
if [ $DEPLOYED -gt 0 ] && [ "$DRY_RUN" = false ]; then
    echo ""
    log_info "=== NEXT STEPS ==="
    echo "1. Review changes in each repository"
    echo "2. Commit and push:"
    echo "   git add .github/workflows/notion-sync.yml"
    echo "   git commit -m \"feat: Add GitHub ↔ Notion real-time sync\""
    echo "   git push"
    echo ""
    echo "3. Configure secrets for each repo:"
    echo "   gh secret set NOTION_API_KEY --repo TAG-IT-NETWORK/<repo>"
    echo "   gh secret set GITHUB_WEBHOOK_SECRET --repo TAG-IT-NETWORK/<repo>"
    echo ""
    echo "4. Test with manual trigger:"
    echo "   gh workflow run notion-sync.yml --repo TAG-IT-NETWORK/<repo>"
fi

exit 0
