#!/bin/bash
# Script to setup global Harness Engineering template
# Run this ONCE to setup ~/.claude/.template/

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Harness Engineering Template Setup${NC}"
echo ""

# ============================================================
# STEP 1: Check if ~/.claude exists
# ============================================================

if [ ! -d ~/.claude ]; then
    echo -e "${YELLOW}⚠️  ~/.claude/ does not exist${NC}"
    mkdir -p ~/.claude
    echo -e "${GREEN}✅ Created ~/.claude/${NC}"
fi

# ============================================================
# STEP 2: Backup existing template if it exists
# ============================================================

if [ -d ~/.claude/.template ]; then
    BACKUP_DIR="$HOME/.claude/.template.backup.$(date +%Y%m%d-%H%M%S)"
    echo -e "${YELLOW}⚠️  ~/.claude/.template/ already exists${NC}"
    echo "   Backing up to: $BACKUP_DIR"
    mv ~/.claude/.template "$BACKUP_DIR"
    echo -e "${GREEN}✅ Backup created${NC}"
fi

# ============================================================
# STEP 3: Copy template from this workspace
# ============================================================

TEMPLATE_SOURCE="$(dirname "$0")"

if [ ! -d "$TEMPLATE_SOURCE" ]; then
    echo -e "${YELLOW}❌ Template source not found: $TEMPLATE_SOURCE${NC}"
    echo "   Please run this script from the workspace root"
    exit 1
fi

echo ""
echo -e "${BLUE}📋 Copying template from: $TEMPLATE_SOURCE${NC}"
cp -r "$TEMPLATE_SOURCE" ~/.claude/.template
echo -e "${GREEN}✅ Template copied to ~/.claude/.template/${NC}"

# ============================================================
# STEP 4: Make shell scripts executable
# ============================================================

echo ""
echo -e "${BLUE}🔧 Setting permissions on hook scripts${NC}"
chmod +x ~/.claude/.template/.github/workflows/*.sh 2>/dev/null || true
chmod +x ~/.claude/.template/observability/*.sh 2>/dev/null || true
echo -e "${GREEN}✅ Shell scripts are executable${NC}"

# ============================================================
# STEP 5: Create .gitignore in template
# ============================================================

echo ""
echo -e "${BLUE}📝 Creating .gitignore for logs & credentials${NC}"
# Already created by Write tool, just verify
if [ -f ~/.claude/.template/.gitignore ]; then
    echo -e "${GREEN}✅ .gitignore configured${NC}"
fi

# ============================================================
# STEP 6: Verify structure
# ============================================================

echo ""
echo -e "${BLUE}✔️ Verifying template structure${NC}"

declare -a REQUIRED_FILES=(
    ".claude/.template/CLAUDE.md"
    ".claude/.template/MEMORY.md"
    ".claude/.template/settings.json"
    ".claude/.template/.github/workflows/pre-tool-guardrails.sh"
    ".claude/.template/.github/workflows/post-tool-audit.sh"
    ".claude/.template/memory/user-profile.md"
    ".claude/.template/memory/reference-vault.md"
    ".claude/.template/commands/setup-vault.md"
    ".claude/.template/commands/deploy.md"
    ".claude/.template/commands/standup.md"
    ".claude/.template/observability/cost-tracker.sh"
    ".claude/.template/logs/.gitkeep"
    ".claude/.template/.gitignore"
)

MISSING=0
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$HOME/$file" ]; then
        echo -e "${GREEN}✅${NC} $file"
    else
        echo -e "${YELLOW}⚠️${NC} Missing: $file"
        MISSING=$((MISSING + 1))
    fi
done

# ============================================================
# STEP 7: Summary & next steps
# ============================================================

echo ""
echo -e "${BLUE}════════════════════════════════════════════${NC}"

if [ $MISSING -eq 0 ]; then
    echo -e "${GREEN}✅ Setup complete!${NC}"
else
    echo -e "${YELLOW}⚠️ Setup complete but $MISSING files missing${NC}"
fi

echo ""
echo -e "${BLUE}📍 Template location: ~/.claude/.template/${NC}"
echo ""
echo -e "${BLUE}🎯 Next steps:${NC}"
echo "   1. For new projects, create .claude/harness-init skill (coming next)"
echo "   2. For existing projects, manually copy template:"
echo ""
echo "      cp -r ~/.claude/.template/ /path/to/project/.claude/"
echo ""
echo "   3. Customize project-specific settings:"
echo "      • CLAUDE.md → tech stack, constraints"
echo "      • settings.json → PROJECT_NAME, MCP_SERVER_NAME"
echo "      • MEMORY.md → vault URL, team links"
echo ""
echo "   4. Commit & push:"
echo "      git add .claude/"
echo "      git commit -m 'init: setup Harness Engineering'"
echo ""
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}✨ Harness Engineering template is now ready!${NC}"
echo ""
