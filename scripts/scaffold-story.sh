#!/usr/bin/env bash
#
# scaffold-story.sh
# Auto-create story files from templates
#
# Usage:
#   ./scripts/scaffold-story.sh "STORY-001" "User login" normal
#   ./scripts/scaffold-story.sh "STORY-002" "Payment integration" high-risk
#   ./scripts/scaffold-story.sh "STORY-003" "Fix typo" tiny
#
# Arguments:
#   $1 - Story ID (e.g., STORY-001, US-042)
#   $2 - Story title (quoted string)
#   $3 - Lane: tiny, normal, high-risk (default: normal)
#
# Created: 2026-05-08
# Part of: Claude-Harness-Kit Phase 2

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Usage function
usage() {
    cat << EOF
${BLUE}scaffold-story.sh${NC} - Auto-create story files from templates

Usage:
  ./scripts/scaffold-story.sh STORY-ID "Story Title" [lane]

Arguments:
  STORY-ID     Story identifier (e.g., STORY-001, US-042)
  Story Title  Human-readable title (use quotes)
  lane         tiny | normal | high-risk (default: normal)

Examples:
  ./scripts/scaffold-story.sh "STORY-001" "User login" normal
  ./scripts/scaffold-story.sh "STORY-002" "Payment integration" high-risk
  ./scripts/scaffold-story.sh "STORY-003" "Fix typo" tiny

Lanes:
  tiny       0-1 risk flags → no story file, patch directly
  normal     2-3 risk flags → single story file
  high-risk  4+ flags or hard gate → 4-file packet

Output:
  tiny:       No file created (reminder message only)
  normal:     docs/stories/STORY-ID-title.md
  high-risk:  docs/stories/STORY-ID-title/
                ├── overview.md
                ├── design.md
                ├── execplan.md
                └── validation.md

EOF
    exit 1
}

# Validate prerequisites
validate_prereqs() {
    log_info "Validating prerequisites..."

    # Check if in project root (has docs/ folder)
    if [[ ! -d "docs" ]]; then
        log_error "docs/ folder not found. Are you in project root?"
        log_info "Run this script from the root of your project where docs/ exists."
        exit 1
    fi

    # Check if templates exist
    if [[ ! -d "docs/templates" ]]; then
        log_error "docs/templates/ not found. CE framework not initialized?"
        log_info "Run /harness-init with CE framework option first."
        exit 1
    fi

    # Check if stories folder exists
    if [[ ! -d "docs/stories" ]]; then
        log_warning "docs/stories/ not found, creating..."
        mkdir -p docs/stories
    fi

    log_success "Prerequisites OK"
}

# Sanitize filename
sanitize_filename() {
    local title="$1"
    # Convert to lowercase, replace spaces with hyphens, remove special chars
    echo "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g'
}

# Create tiny lane story (no file, just reminder)
create_tiny_story() {
    local story_id="$1"
    local title="$2"

    log_info "Lane: TINY (0-1 risk flags)"
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  TINY LANE: No story file needed${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Story: [$story_id] $title"
    echo ""
    echo "Instructions:"
    echo "  1. Patch directly (no story file required)"
    echo "  2. Update docs/TEST_MATRIX.md with proof links"
    echo "  3. Commit with message: 'fix($story_id): $title'"
    echo ""
    echo "Example:"
    echo "  git commit -m 'fix($story_id): $title"
    echo ""
    echo "  Updated TEST_MATRIX.md:'"
    echo ""
    log_success "Tiny lane workflow displayed"
}

# Create normal lane story (single file)
create_normal_story() {
    local story_id="$1"
    local title="$2"
    local template="docs/templates/story.md"

    if [[ ! -f "$template" ]]; then
        log_error "Template not found: $template"
        exit 1
    fi

    log_info "Lane: NORMAL (2-3 risk flags)"

    # Generate filename
    local sanitized_title=$(sanitize_filename "$title")
    local filename="docs/stories/${story_id}-${sanitized_title}.md"

    # Check if file already exists
    if [[ -f "$filename" ]]; then
        log_error "Story file already exists: $filename"
        log_info "Use a different story ID or delete the existing file first."
        exit 1
    fi

    log_info "Creating story file: $filename"

    # Copy template and customize
    cp "$template" "$filename"

    # Replace placeholders
    sed -i "s/\[STORY-ID\]/${story_id}/g" "$filename"
    sed -i "s/Story Title/${title}/g" "$filename"

    log_success "Created: $filename"

    # Show next steps
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  NORMAL LANE: Story file created${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Edit $filename"
    echo "  2. Fill in Context, Requirements, Design Notes"
    echo "  3. List risk flags (from FEATURE_INTAKE.md)"
    echo "  4. Execute story"
    echo "  5. Update product docs (docs/product/)"
    echo "  6. Update TEST_MATRIX.md with proof links"
    echo "  7. Mark story as done"
    echo ""
    log_info "Open file: vim $filename"
}

# Create high-risk lane story (4-file packet)
create_highrisk_story() {
    local story_id="$1"
    local title="$2"
    local template_dir="docs/templates/high-risk-story"

    if [[ ! -d "$template_dir" ]]; then
        log_error "High-risk templates not found: $template_dir"
        exit 1
    fi

    log_info "Lane: HIGH-RISK (4+ flags or hard gate)"

    # Generate folder name
    local sanitized_title=$(sanitize_filename "$title")
    local folder="docs/stories/${story_id}-${sanitized_title}"

    # Check if folder already exists
    if [[ -d "$folder" ]]; then
        log_error "Story folder already exists: $folder"
        log_info "Use a different story ID or delete the existing folder first."
        exit 1
    fi

    log_info "Creating story packet: $folder"

    # Create folder
    mkdir -p "$folder"

    # Copy all 4 templates
    local files=("overview.md" "design.md" "execplan.md" "validation.md")
    for file in "${files[@]}"; do
        if [[ ! -f "$template_dir/$file" ]]; then
            log_warning "Template missing: $template_dir/$file, skipping..."
            continue
        fi

        cp "$template_dir/$file" "$folder/$file"

        # Replace placeholders
        sed -i "s/\[STORY-ID\]/${story_id}/g" "$folder/$file"
        sed -i "s/Overview/${title}/g" "$folder/$file" 2>/dev/null || true
        sed -i "s/Design/${title} Design/g" "$folder/$file" 2>/dev/null || true
        sed -i "s/Execution Plan/${title} Execution Plan/g" "$folder/$file" 2>/dev/null || true
        sed -i "s/Validation/${title} Validation/g" "$folder/$file" 2>/dev/null || true

        log_success "  Created: $folder/$file"
    done

    log_success "Created high-risk packet: $folder"

    # Show next steps
    echo ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}  HIGH-RISK LANE: 4-file packet created${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Packet structure:"
    echo "  $folder/"
    echo "    ├── overview.md     — Problem, impact, constraints"
    echo "    ├── design.md       — Architecture, data model, API, security"
    echo "    ├── execplan.md     — Phases, rollback, deployment, monitoring"
    echo "    └── validation.md   — Test strategy, proof, acceptance criteria"
    echo ""
    echo "Next steps:"
    echo "  1. Fill in all 4 files (start with overview.md)"
    echo "  2. List risk flags and hard gates"
    echo "  3. Review design with team"
    echo "  4. Execute phases incrementally"
    echo "  5. Update product docs + TEST_MATRIX.md"
    echo "  6. Create decision record if breaking change (docs/decisions/)"
    echo "  7. Mark story as done"
    echo ""
    log_info "Open folder: cd $folder && ls"
}

# Main script
main() {
    # Parse arguments
    if [[ $# -lt 2 ]]; then
        log_error "Missing required arguments"
        usage
    fi

    local story_id="$1"
    local title="$2"
    local lane="${3:-normal}"  # Default to normal

    # Validate lane
    if [[ ! "$lane" =~ ^(tiny|normal|high-risk)$ ]]; then
        log_error "Invalid lane: $lane"
        log_info "Valid lanes: tiny, normal, high-risk"
        exit 1
    fi

    # Validate story ID format (basic check)
    if [[ ! "$story_id" =~ ^[A-Z]+-[0-9]+$ ]] && [[ ! "$story_id" =~ ^[A-Z]+[0-9]+$ ]]; then
        log_warning "Story ID format: $story_id"
        log_info "Recommended format: STORY-001 or US-042"
        echo ""
        read -p "Continue anyway? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            log_info "Cancelled by user"
            exit 0
        fi
    fi

    # Show summary
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  Story Scaffold${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Story ID: $story_id"
    echo "Title:    $title"
    echo "Lane:     $lane"
    echo ""

    # Validate prerequisites
    validate_prereqs

    # Create story based on lane
    case "$lane" in
        tiny)
            create_tiny_story "$story_id" "$title"
            ;;
        normal)
            create_normal_story "$story_id" "$title"
            ;;
        high-risk)
            create_highrisk_story "$story_id" "$title"
            ;;
        *)
            log_error "Unknown lane: $lane"
            exit 1
            ;;
    esac

    echo ""
    log_success "Scaffold complete!"
    echo ""
}

# Run main
main "$@"
