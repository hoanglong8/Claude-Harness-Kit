# Kiến trúc Claude Code (verified 31/3/2026)

> Tách từ CLAUDE.md section 4 (2026-07-11) — tự nạp qua `~/.claude/rules/`.

| Thành phần | Chi tiết |
|-----------|---------|
| **QueryEngine** | ~46K LOC — xử lý API calls, streaming, caching |
| **Tool System** | 60+ tools; ~18 ẩn — chỉ xuất hiện khi gọi đúng tên |
| **Multi-agent** | COORDINATOR_MODE: 1 orchestrator điều phối N Claude workers |
| **Output retry** | Auto-inject "Resume directly" — max 3 lần, sau đó dừng |
| **Compaction** | Kích hoạt ~83.5% context; giữ code/task, mất convention |

**Tính năng chưa release (feature-flagged):**
KAIROS · ULTRAPLAN · VOICE_MODE · WEB_BROWSER_TOOL · COORDINATOR_MODE · WORKFLOW_SCRIPTS · PROACTIVE · SSH_REMOTE · MONITOR_TOOL · AGENT_TRIGGERS
