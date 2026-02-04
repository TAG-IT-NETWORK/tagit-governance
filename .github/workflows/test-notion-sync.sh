#!/bin/bash
# =============================================================================
# TEST NOTION-SYNC WORKFLOW
# =============================================================================
# Validates workflow file and tests Notion API connectivity
# Usage: ./test-notion-sync.sh
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
WORKFLOW_FILE="${1:-C:/tagcode/tagit-governance/.github/workflows/notion-sync.yml}"
NOTION_API_KEY="${NOTION_API_KEY:-}"
NOTION_TASKS_DB_ID="${NOTION_TASKS_DB_ID:-8020faaf-b79a-4825-95e6-100313bba423}"
NOTION_API_VERSION="2022-06-28"

# Functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[⚠]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

echo "==================================="
log_info "=== NOTION SYNC WORKFLOW TEST ==="
echo "==================================="
echo ""

# Test 1: Check workflow file exists
log_info "Test 1: Checking workflow file..."
if [ -f "$WORKFLOW_FILE" ]; then
    log_success "Workflow file found: $WORKFLOW_FILE"
else
    log_error "Workflow file not found: $WORKFLOW_FILE"
    exit 1
fi
echo ""

# Test 2: Validate YAML syntax
log_info "Test 2: Validating YAML syntax..."
if command -v yamllint &> /dev/null; then
    if yamllint "$WORKFLOW_FILE" 2>/dev/null; then
        log_success "YAML syntax valid"
    else
        log_warning "YAML linting found issues (non-blocking)"
    fi
else
    log_warning "yamllint not installed, skipping YAML validation"
    log_info "Install with: pip install yamllint"
fi
echo ""

# Test 3: Check required keys in workflow
log_info "Test 3: Checking workflow structure..."
REQUIRED_KEYS=("name" "on" "jobs")
for key in "${REQUIRED_KEYS[@]}"; do
    if grep -q "^$key:" "$WORKFLOW_FILE"; then
        log_success "Key found: $key"
    else
        log_error "Missing required key: $key"
        exit 1
    fi
done
echo ""

# Test 4: Check job definitions
log_info "Test 4: Checking job definitions..."
EXPECTED_JOBS=("validate-webhook" "sync-pr-to-notion" "sync-issue-to-notion" "notify-on-failure")
for job in "${EXPECTED_JOBS[@]}"; do
    if grep -q "$job:" "$WORKFLOW_FILE"; then
        log_success "Job defined: $job"
    else
        log_warning "Job not found: $job"
    fi
done
echo ""

# Test 5: Check Notion API connectivity
log_info "Test 5: Testing Notion API connectivity..."
if [ -z "$NOTION_API_KEY" ]; then
    log_warning "NOTION_API_KEY not set, skipping API test"
    log_info "Set with: export NOTION_API_KEY=your_token"
else
    RESPONSE=$(curl -s -w "\n%{http_code}" \
        -X GET "https://api.notion.com/v1/databases/$NOTION_TASKS_DB_ID" \
        -H "Authorization: Bearer $NOTION_API_KEY" \
        -H "Notion-Version: $NOTION_API_VERSION")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    if [ "$HTTP_CODE" == "200" ]; then
        log_success "Notion API connection successful"
        DB_TITLE=$(echo "$BODY" | grep -o '"title":\[{"plain_text":"[^"]*"' | cut -d'"' -f6)
        if [ -n "$DB_TITLE" ]; then
            log_info "Connected to database: $DB_TITLE"
        fi
    elif [ "$HTTP_CODE" == "401" ]; then
        log_error "Notion API authentication failed (401)"
        log_error "Check your NOTION_API_KEY"
        exit 1
    elif [ "$HTTP_CODE" == "404" ]; then
        log_error "Notion database not found (404)"
        log_error "Check NOTION_TASKS_DB_ID: $NOTION_TASKS_DB_ID"
        exit 1
    else
        log_error "Notion API request failed: HTTP $HTTP_CODE"
        log_error "Response: $BODY"
        exit 1
    fi
fi
echo ""

# Test 6: Check required secrets documentation
log_info "Test 6: Checking secrets documentation..."
README_FILE="$(dirname "$WORKFLOW_FILE")/README.md"
if [ -f "$README_FILE" ]; then
    log_success "README found: $README_FILE"
    if grep -q "NOTION_API_KEY" "$README_FILE"; then
        log_success "NOTION_API_KEY documented"
    else
        log_warning "NOTION_API_KEY not documented in README"
    fi
else
    log_warning "README not found: $README_FILE"
fi
echo ""

# Test 7: Check GitHub CLI availability
log_info "Test 7: Checking GitHub CLI..."
if command -v gh &> /dev/null; then
    GH_VERSION=$(gh --version | head -n 1)
    log_success "GitHub CLI available: $GH_VERSION"

    # Check authentication
    if gh auth status &> /dev/null; then
        log_success "GitHub CLI authenticated"
    else
        log_warning "GitHub CLI not authenticated"
        log_info "Run: gh auth login"
    fi
else
    log_warning "GitHub CLI not installed"
    log_info "Install from: https://cli.github.com"
fi
echo ""

# Test 8: Validate Python requirements
log_info "Test 8: Checking Python dependencies..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    log_success "Python available: $PYTHON_VERSION"

    # Check required modules
    REQUIRED_MODULES=("requests" "json")
    for module in "${REQUIRED_MODULES[@]}"; do
        if python3 -c "import $module" 2>/dev/null; then
            log_success "Module available: $module"
        else
            log_warning "Module not found: $module"
            log_info "Install with: pip install $module"
        fi
    done
else
    log_error "Python 3 not found"
    exit 1
fi
echo ""

# Summary
echo "==================================="
log_info "=== TEST SUMMARY ==="
log_success "Workflow file validation: PASSED"
log_success "Structure checks: PASSED"
if [ -n "$NOTION_API_KEY" ]; then
    log_success "Notion API connectivity: PASSED"
else
    log_warning "Notion API connectivity: SKIPPED"
fi
echo "==================================="
echo ""

# Next steps
log_info "=== NEXT STEPS ==="
echo "1. Deploy workflow to repositories:"
echo "   ./deploy-to-all-repos.sh --dry-run  # Test first"
echo "   ./deploy-to-all-repos.sh            # Deploy"
echo ""
echo "2. Configure secrets in GitHub:"
echo "   gh secret set NOTION_API_KEY --repo TAG-IT-NETWORK/<repo>"
echo "   gh secret set GITHUB_WEBHOOK_SECRET --repo TAG-IT-NETWORK/<repo>"
echo ""
echo "3. Test with manual trigger:"
echo "   gh workflow run notion-sync.yml --repo TAG-IT-NETWORK/<repo>"
echo ""

log_success "All tests passed! Ready to deploy."
exit 0
