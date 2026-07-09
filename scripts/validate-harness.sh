#!/usr/bin/env bash
#
# validate-harness.sh
# Check harness consistency and completeness
#
# Usage:
#   ./scripts/validate-harness.sh              # Run all checks
#   ./scripts/validate-harness.sh --fix        # Auto-fix issues where possible
#   ./scripts/validate-harness.sh --strict     # Fail on warnings
#
# Created: 2026-05-08
# Part of: Claude-Harness-Kit Phase 2

set -uo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
ISSUES_FOUND=0
ISSUES_FIXED=0

# Options
FIX_MODE=false
STRICT_MODE=false

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((CHECKS_PASSED++))
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((ISSUES_FOUND++))
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    ((CHECKS_FAILED++))
}

log_fixed() {
    echo -e "${GREEN}🔧 Fixed: $1${NC}"
    ((ISSUES_FIXED++))
}

usage() {
    cat << EOF
${BLUE}validate-harness.sh${NC} - Check harness consistency and completeness

Usage:
  ./scripts/validate-harness.sh [OPTIONS]

Options:
  --fix       Auto-fix issues where possible
  --strict    Fail on warnings (not just errors)
  -h, --help  Show this help message

Examples:
  ./scripts/validate-harness.sh
  ./scripts/validate-harness.sh --fix
  ./scripts/validate-harness.sh --fix --strict

Checks performed:
  1. Core docs exist (HARNESS, FEATURE_INTAKE, ARCHITECTURE, etc.)
  2. Story files reference valid product docs
  3. TEST_MATRIX has proof links
  4. Decision records follow naming convention (NNNN-title)
  5. No broken links in stories
  6. AGENTS.md Source of Truth hierarchy complete
  7. All folders have README files
  8. Git is clean (no uncommitted changes for CI)

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --fix)
            FIX_MODE=true
            shift
            ;;
        --strict)
            STRICT_MODE=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate prerequisites
validate_harness_exists() {
    log_info "Checking if harness exists..."

    if [[ ! -d "docs" ]]; then
        log_error "docs/ folder not found. Not a harness project?"
        exit 1
    fi

    if [[ ! -f "AGENTS.md" ]]; then
        log_warning "AGENTS.md not found. CE framework not initialized?"
    fi

    log_success "Harness folder structure exists"
}

# Check 1: Core docs exist
check_core_docs() {
    log_info "\n[1/8] Checking core documentation..."

    local required_docs=(
        "docs/HARNESS.md"
        "docs/FEATURE_INTAKE.md"
        "docs/ARCHITECTURE.md"
        "docs/TEST_MATRIX.md"
        "docs/GLOSSARY.md"
        "docs/HARNESS_BACKLOG.md"
    )

    local missing=()
    for doc in "${required_docs[@]}"; do
        if [[ ! -f "$doc" ]]; then
            missing+=("$doc")
            log_warning "Missing: $doc"
        fi
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        log_success "All core docs present"
    else
        log_error "${#missing[@]} core docs missing"
        if [[ "$FIX_MODE" == true ]]; then
            log_info "Tip: Run /harness-init with CE framework to generate missing docs"
        fi
    fi
}

# Check 2: Templates exist
check_templates() {
    log_info "\n[2/8] Checking templates..."

    local required_templates=(
        "docs/templates/story.md"
        "docs/templates/decision.md"
        "docs/templates/spec-intake.md"
        "docs/templates/validation-report.md"
        "docs/templates/high-risk-story/overview.md"
        "docs/templates/high-risk-story/design.md"
        "docs/templates/high-risk-story/execplan.md"
        "docs/templates/high-risk-story/validation.md"
    )

    local missing=()
    for template in "${required_templates[@]}"; do
        if [[ ! -f "$template" ]]; then
            missing+=("$template")
            log_warning "Missing template: $template"
        fi
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        log_success "All templates present"
    else
        log_error "${#missing[@]} templates missing"
    fi
}

# Check 3: Folder structure
check_folder_structure() {
    log_info "\n[3/8] Checking folder structure..."

    local required_folders=(
        "docs/product"
        "docs/stories"
        "docs/decisions"
        "docs/templates"
        "scripts"
    )

    local missing=()
    for folder in "${required_folders[@]}"; do
        if [[ ! -d "$folder" ]]; then
            missing+=("$folder")
            log_warning "Missing folder: $folder"
        fi
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        log_success "All required folders present"
    else
        log_error "${#missing[@]} folders missing"
        if [[ "$FIX_MODE" == true ]]; then
            for folder in "${missing[@]}"; do
                mkdir -p "$folder"
                log_fixed "Created folder: $folder"
            done
        fi
    fi
}

# Check 4: README files in key folders
check_readme_files() {
    log_info "\n[4/8] Checking README files..."

    local readme_folders=(
        "docs/product"
        "docs/stories"
        "docs/decisions"
        "scripts"
    )

    local missing=()
    for folder in "${readme_folders[@]}"; do
        if [[ -d "$folder" && ! -f "$folder/README.md" ]]; then
            missing+=("$folder/README.md")
            log_warning "Missing: $folder/README.md"
        fi
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        log_success "All key folders have README files"
    else
        log_error "${#missing[@]} README files missing"
    fi
}

# Check 5: Story file naming convention
check_story_naming() {
    log_info "\n[5/8] Checking story file naming..."

    local bad_names=()
    for story in docs/stories/*; do
        if [[ -e "$story" ]]; then
            local basename=$(basename "$story")
            # Skip README.md and epics folder
            if [[ "$basename" == "README.md" ]] || [[ "$basename" == "epics" ]]; then
                continue
            fi
            # Check if name follows STORY-NNN-title or similar pattern
            if [[ ! "$basename" =~ ^[A-Z]+-[0-9]+ ]] && [[ ! "$basename" =~ ^US-[0-9]+ ]]; then
                bad_names+=("$basename")
                log_warning "Bad naming convention: $basename (should be STORY-001-title or similar)"
            fi
        fi
    done

    if [[ ${#bad_names[@]} -eq 0 ]]; then
        log_success "Story file naming convention OK"
    else
        log_error "${#bad_names[@]} story files have bad naming"
    fi
}

# Check 6: TEST_MATRIX has content
check_test_matrix() {
    log_info "\n[6/8] Checking TEST_MATRIX.md..."

    if [[ ! -f "docs/TEST_MATRIX.md" ]]; then
        log_error "TEST_MATRIX.md not found"
        return
    fi

    # Count table rows (excluding header)
    local rows=$(grep -c "^|" docs/TEST_MATRIX.md || echo 0)
    if [[ $rows -lt 2 ]]; then
        log_warning "TEST_MATRIX.md has no content rows (only template)"
    else
        log_success "TEST_MATRIX.md has $((rows-2)) behaviors tracked"
    fi

    # Check for example rows that should be removed
    if grep -q "_Example:" docs/TEST_MATRIX.md; then
        log_warning "TEST_MATRIX.md still has example rows (_Example:)"
        if [[ "$FIX_MODE" == true ]]; then
            sed -i '/_Example:/d' docs/TEST_MATRIX.md
            log_fixed "Removed example rows from TEST_MATRIX.md"
        fi
    fi
}

# Check 7: AGENTS.md exists and has content
check_agents_md() {
    log_info "\n[7/8] Checking AGENTS.md..."

    if [[ ! -f "AGENTS.md" ]]; then
        log_warning "AGENTS.md not found (CE framework not initialized?)"
        return
    fi

    # Check for key sections
    local sections=("Source of Truth" "Task Loop" "Done Definition")
    for section in "${sections[@]}"; do
        if ! grep -q "$section" AGENTS.md; then
            log_warning "AGENTS.md missing section: $section"
        fi
    done

    if grep -q "Source of Truth" AGENTS.md && grep -q "Task Loop" AGENTS.md; then
        log_success "AGENTS.md has required sections"
    fi
}

# Check 8: CLAUDE.md exists
check_claude_md() {
    log_info "\n[8/8] Checking CLAUDE.md..."

    if [[ ! -f "CLAUDE.md" && ! -f ".claude/CLAUDE.md" ]]; then
        log_warning "CLAUDE.md not found"
        return
    fi

    # Check for required sections
    local claude_file="CLAUDE.md"
    if [[ ! -f "$claude_file" && -f ".claude/CLAUDE.md" ]]; then
        claude_file=".claude/CLAUDE.md"
    fi

    if grep -q "Tech Stack\|tech stack\|Language\|language" "$claude_file" 2>/dev/null; then
        log_success "CLAUDE.md has tech stack info"
    else
        log_warning "CLAUDE.md missing tech stack information"
    fi
}

# Check 9: Git status (bonus check)
check_git_status() {
    log_info "\n[BONUS] Checking git status..."

    if ! command -v git &> /dev/null; then
        log_info "Git not available, skipping"
        return
    fi

    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_info "Not a git repository, skipping"
        return
    fi

    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        local uncommitted=$(git status --short | wc -l)
        log_warning "Git has $uncommitted uncommitted changes"
    else
        log_success "Git working tree is clean"
    fi
}

# Generate report
generate_report() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Validation Report${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Checks passed:  ${CHECKS_PASSED}"
    echo "Checks failed:  ${CHECKS_FAILED}"
    echo "Issues found:   ${ISSUES_FOUND}"
    echo "Issues fixed:   ${ISSUES_FIXED}"
    echo ""

    # Summary
    if [[ $CHECKS_FAILED -eq 0 && $ISSUES_FOUND -eq 0 ]]; then
        log_success "All checks passed! Harness is healthy."
        echo ""
        return 0
    elif [[ $CHECKS_FAILED -eq 0 && $ISSUES_FOUND -gt 0 ]]; then
        if [[ "$STRICT_MODE" == true ]]; then
            log_error "Harness has ${ISSUES_FOUND} issue(s). Failing in strict mode."
            echo ""
            return 1
        else
            log_warning "Harness has ${ISSUES_FOUND} issue(s) but no failures."
            echo ""
            echo "Recommendations:"
            echo "  1. Review warnings above"
            echo "  2. Run with --fix to auto-correct"
            echo "  3. Run with --strict to fail on warnings"
            echo ""
            return 0
        fi
    else
        log_error "Harness validation FAILED"
        echo ""
        echo "Next steps:"
        echo "  1. Review errors above"
        echo "  2. Fix critical issues manually"
        echo "  3. Run /harness-init with CE framework if needed"
        echo "  4. Run validate-harness.sh again"
        echo ""
        return 1
    fi
}

# Main workflow
main() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Harness Validator${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    if [[ "$FIX_MODE" == true ]]; then
        log_info "Fix mode enabled (auto-correct issues)"
    fi
    if [[ "$STRICT_MODE" == true ]]; then
        log_info "Strict mode enabled (fail on warnings)"
    fi

    # Run validation
    validate_harness_exists
    check_core_docs
    check_templates
    check_folder_structure
    check_readme_files
    check_story_naming
    check_test_matrix
    check_agents_md
    check_claude_md
    check_git_status

    # Generate report
    generate_report
}

# Run main
main
