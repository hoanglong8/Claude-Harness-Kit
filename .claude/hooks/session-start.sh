#!/usr/bin/env bash
#
# session-start.sh (GLOBAL)
# Auto-trigger khi bắt đầu session mới trên bất kỳ project nào
# Detect project type và hiển thị reminder phù hợp
#
# Created: 2026-05-08

set -uo pipefail

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Detect project type
if [[ -f "AGENTS.md" && -d "docs" && -f "CLAUDE.md" ]]; then
    # Claude-Harness-Kit project
    echo -e "${BLUE}  Claude-Harness-Kit Session Start${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Phase 2 status
    echo -e "${GREEN}✅ Phase 2 Status: HOÀN THÀNH${NC}"
    echo "   ✓ Task #10: harness-init.skill CE integration"
    echo "   ✓ Task #11: scripts/scaffold-story.sh"
    echo "   ✓ Task #12: scripts/validate-harness.sh"
    echo ""

    # Pending phases
    echo -e "${YELLOW}🔄 Pending Phases:${NC}"
    echo "   • Phase 3: CI/CD integration (.github/workflows/harness-check.yml)"
    echo "   • Phase 4: Stack-specific templates (Node.js, Python, Go)"
    echo "   • Phase 5: Domain guides (API Design, Observability, Security)"
    echo ""

    # Quick harness validation
    if [[ -f "scripts/validate-harness.sh" ]]; then
        echo -e "${BLUE}📋 Quick Harness Check:${NC}"
        bash scripts/validate-harness.sh 2>/dev/null | tail -5
        echo ""
    fi

elif [[ -d "node_modules" || -f "package.json" ]]; then
    # Node.js/JavaScript project
    echo -e "${BLUE}  Node.js Project Session Start${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    if [[ -f "package.json" ]]; then
        echo -e "${BLUE}📦 Project Info:${NC}"
        grep -E '"name"|"version"' package.json | head -2 | sed 's/^/   /'
        echo ""
    fi

    echo -e "${YELLOW}💡 Available Commands:${NC}"
    echo "   • npm run dev    — Start development server"
    echo "   • npm test       — Run tests"
    echo "   • npm run build  — Build for production"
    echo ""

elif [[ -f "pyproject.toml" || -f "requirements.txt" || -d "venv" || -d ".venv" ]]; then
    # Python project
    echo -e "${BLUE}  Python Project Session Start${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    if [[ -f "pyproject.toml" ]]; then
        echo -e "${BLUE}📦 Project Info:${NC}"
        grep -E "^name|^version" pyproject.toml | head -2 | sed 's/^/   /'
        echo ""
    fi

    echo -e "${YELLOW}💡 Available Commands:${NC}"
    echo "   • python -m venv venv  — Create virtual environment"
    echo "   • pip install -r requirements.txt"
    echo "   • python -m pytest      — Run tests"
    echo ""

elif [[ -f "go.mod" ]]; then
    # Go project
    echo -e "${BLUE}  Go Project Session Start${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    echo -e "${BLUE}📦 Project Info:${NC}"
    head -1 go.mod | sed 's/^/   /'
    echo ""

    echo -e "${YELLOW}💡 Available Commands:${NC}"
    echo "   • go mod tidy    — Sync dependencies"
    echo "   • go build       — Build binary"
    echo "   • go test ./...  — Run tests"
    echo ""

elif [[ -f ".git/config" ]]; then
    # Generic git project
    echo -e "${BLUE}  Git Project Session Start${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    echo -e "${BLUE}📊 Git Status:${NC}"
    echo "   Branch: $branch"
    echo ""

else
    # Unknown project type
    echo -e "${BLUE}  Session Start${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
fi

# Common reminders for all projects
echo -e "${YELLOW}🎯 Global Reminders:${NC}"
echo "   📄 Check: CLAUDE.md for project rules"
echo "   💾 Use: /memory to manage project knowledge"
echo "   📋 Use: /task-list to track work"
echo "   🔍 Use: /review or /security-review for code checks"
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
