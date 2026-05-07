#!/usr/bin/env bash
#
# session-start.sh
# Auto-trigger khi bắt đầu session mới trong Claude-Harness-Kit
# Nhắc nhở pending work, check status harness
#
# Created: 2026-05-08

set -uo pipefail

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if in Claude-Harness-Kit project
if [[ ! -f "AGENTS.md" || ! -d "docs" ]]; then
    exit 0  # Not a harness project, skip
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Claude-Harness-Kit Session Start${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 1. Show Phase 2 completion status
echo -e "${GREEN}✅ Phase 2 Status: HOÀN THÀNH${NC}"
echo "   ✓ Task #10: harness-init.skill CE integration"
echo "   ✓ Task #11: scripts/scaffold-story.sh"
echo "   ✓ Task #12: scripts/validate-harness.sh"
echo ""

# 2. Show pending phases
echo -e "${YELLOW}🔄 Pending Phases:${NC}"
echo "   • Phase 3: CI/CD integration (.github/workflows/harness-check.yml)"
echo "   • Phase 4: Stack-specific templates (Node.js, Python, Go)"
echo "   • Phase 5: Domain guides (API Design, Observability, Security)"
echo ""

# 3. Quick harness validation
if [[ -f "scripts/validate-harness.sh" ]]; then
    echo -e "${BLUE}📋 Quick Harness Check:${NC}"
    bash scripts/validate-harness.sh 2>/dev/null | tail -5
    echo ""
fi

# 4. Memory reminder
if [[ -f ".claude/projects/C--Users-Admin--claude--claude-Claude-Harness-Kit/memory/phase2_status.md" ]]; then
    echo -e "${BLUE}📄 Full Status: memory/phase2_status.md${NC}"
    echo ""
fi

# 5. Git status summary
if git rev-parse --git-dir > /dev/null 2>&1; then
    local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    local ahead=$(git rev-list --count origin/main..HEAD 2>/dev/null || echo "0")

    if [[ "$ahead" -gt 0 ]]; then
        echo -e "${YELLOW}📊 Git Status:${NC}"
        echo "   Branch: $branch"
        echo "   Commits ahead of main: $ahead"
        echo ""
    fi
fi

echo -e "${BLUE}💡 Next Steps:${NC}"
echo "   1. Check pending phases above"
echo "   2. Choose Phase 3, 4, 5 or other work"
echo "   3. Run: /task-list"
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
