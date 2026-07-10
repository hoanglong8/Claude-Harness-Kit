#!/usr/bin/env bash
# fable-harness | Stop hook — cuong che rule 30 (verification before "done").
# Neu message cuoi cua luot tuyen bo hoan thanh ma luot khong co tool call tao bang chung → block.
# Can jq; neu thieu jq thi chuyen sang ban PowerShell (Windows), khong co ca hai thi thoat em.

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v jq >/dev/null 2>&1; then
  if command -v powershell.exe >/dev/null 2>&1; then
    exec powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "$DIR/fable_stop_verify.ps1" 2>/dev/null || echo "$DIR/fable_stop_verify.ps1")"
  fi
  exit 0
fi

input=$(cat)

# Chong vong lap: hook da block mot lan trong luot nay thi cho qua
[ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0

transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty')
[ -z "$transcript" ] || [ ! -f "$transcript" ] && exit 0

# Chi xet 400 dong cuoi transcript; luot hien tai = sau entry user cuoi khong phai tool_result
turn=$(tail -n 400 "$transcript" | jq -cs '
  ( [ range(0; length) as $i
      | select(.[$i].type == "user"
               and ((.[$i].message.content | type) == "string"
                    or ([.[$i].message.content[]? | select(.type == "tool_result")] | length) == 0))
      | $i ] | max // 0 ) as $start
  | .[$start:]')

has_evidence=$(printf '%s' "$turn" | jq -r '
  [ .[] | select(.type == "assistant") | .message.content[]?
    | select(.type == "tool_use" and (.name | test("^(Bash|PowerShell|Read|Agent|Skill|Workflow)$"))) ]
  | length > 0')

last_text=$(printf '%s' "$turn" | jq -r '
  [ .[] | select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text ]
  | last // ""')

[ -z "$last_text" ] && exit 0

# Model da tu khai trang thai chua kiem chung → khong can chan (giam false positive
# khi message chi NHAC toi tu "hoàn thành/kiểm chứng" trong ngu canh meta)
printf '%s' "$last_text" | grep -Piq 'chưa kiểm chứng|chua kiem chung|chưa chạy|chua chay|đã viết, chưa|da viet, chua' && exit 0

if printf '%s' "$last_text" | grep -Piq '(?<!(chưa|chua|không|khong)\s)(hoàn thành|hoan thanh|đã chạy được|da chay duoc|chạy thành công|tests?\s+pass(ed)?|đã kiểm chứng|da kiem chung)' \
   && [ "$has_evidence" = "false" ]; then
  jq -cn '{
    decision: "block",
    reason: "[fable-verify] Message cuối tuyên bố hoàn thành/chạy được nhưng lượt này không có tool call nào tạo ra bằng chứng (Bash/PowerShell/Read/Agent). Theo rule 30: hoặc chạy kiểm chứng ngay bây giờ và trích kết quả thực, hoặc hạ trạng thái xuống \"Đã viết, chưa chạy\" kèm mục \"Chưa kiểm chứng:\"."
  }'
fi
exit 0
