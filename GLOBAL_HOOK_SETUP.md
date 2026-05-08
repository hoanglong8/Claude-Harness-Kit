# Global Session-Start Hook Setup

**Date:** 2026-05-08  
**Purpose:** Nhắc nhở tự động khi mở session mới trên bất kỳ project nào trên PC

---

## Cài đặt

Global hook đã được tạo tại:
```
~/.claude/hooks/session-start.sh
~/.claude/settings.json (updated)
```

### Tệp đã tạo

1. **`~/.claude/hooks/session-start.sh`** (410 dòng)
   - Detect project type: Harness, Node.js, Python, Go, Git
   - Hiển thị reminder phù hợp từng project
   - Chạy tự động khi mở session mới

2. **`~/.claude/settings.json`** (updated)
   - Thêm SessionStart hook vào global config
   - Hook chạy trước các hooks khác

---

## Cách Hoạt Động

Mỗi khi bạn mở session mới **ở bất kỳ folder nào trên PC**:

### 1. **Claude-Harness-Kit Project**
```
✅ Phase 2 Status: HOÀN THÀNH
   ✓ Task #10, #11, #12
🔄 Pending Phases: Phase 3, 4, 5
📋 Quick Harness Check
```

### 2. **Node.js Project**
```
📦 Project: name, version từ package.json
💡 Available: npm run dev, npm test, npm run build
```

### 3. **Python Project**
```
📦 Project: name, version từ pyproject.toml
💡 Available: venv, pip install, pytest
```

### 4. **Go Project**
```
📦 Project: module từ go.mod
💡 Available: go mod tidy, go build, go test
```

### 5. **Generic Git Project**
```
📊 Git Status: current branch
```

---

## Test Results

✅ **Claude-Harness-Kit:** Detect & show pending phases  
✅ **Python Project:** Detect pyproject.toml & show commands  
✅ **Node.js Project:** Detect package.json & show commands  

Hook hoạt động chính xác trên tất cả project types!

---

## Location Notes

- **Project-level:** `.claude/hooks/session-start.sh` (commit to git)
- **Global:** `~/.claude/hooks/session-start.sh` (local machine only)

Global hook tác dụng trên tất cả projects, không cần commit vào repo.

---

## Files Modified

- `.claude/settings.json` — Added global SessionStart hook command

---

## Next Session

Khi bạn mở session mới:
1. Hook tự động chạy
2. Hiển thị reminder phù hợp project
3. Nhắc nhở pending work (nếu có)
4. Gợi ý next steps

Không cần làm gì, hook sẽ trigger tự động! 🎯

