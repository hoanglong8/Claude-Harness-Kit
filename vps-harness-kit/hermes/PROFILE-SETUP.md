# Tái tạo profile `foxai-qwen` trên VPS

> Kết nối Hermes tới LLM Qwen 3.6 nội bộ FOXAI (llama.cpp, OpenAI-compatible).
> Các lệnh dưới lấy từ `hermes` bản cài trên máy nguồn (2026-08-27). Bản trên VPS có thể khác — luôn chạy `hermes <lệnh> --help` để đối chiếu.

## Thông số endpoint (từ memory 2026-08-17 — XÁC NHẬN CÒN SỐNG TRƯỚC KHI DÙNG)

| Trường | Giá trị |
|---|---|
| base_url | `http://222.252.99.27:8035/v1` |
| model id | `qwen3.6-35b-a3b` |
| provider type | `custom` |
| api_mode | `chat_completions` |
| context_length | `262144` |
| tên biến key trong `.env` | `HERMES_CUSTOM_FOXAI_QWEN_API_KEY` |
| gateway loopback (nếu bật) | `http://127.0.0.1:8642/v1/chat/completions` |

Kiểm tra endpoint còn sống (thay `$KEY` bằng key thật, không lưu ra file):

```bash
curl -s http://222.252.99.27:8035/v1/models -H "Authorization: Bearer $KEY"
```

## Các bước

### 1. Wizard khởi tạo (chọn provider/model mặc định bất kỳ)

```bash
hermes setup
```

### 2. Tạo profile

```bash
hermes profile create foxai-qwen --clone \
  --description "Qwen 3.6 35B noi bo FOXAI qua llama.cpp"
```

`--clone` copy `config.yaml`, `.env`, `SOUL.md`, skills từ profile đang active. Bỏ `--clone` nếu muốn profile rỗng.

### 3. Đặt API key vào `.env` của profile (KHÔNG commit, KHÔNG in ra chat)

```bash
hermes config env-path          # in đường dẫn file .env đang dùng
# mở file đó, thêm dòng:
# HERMES_CUSTOM_FOXAI_QWEN_API_KEY=<key-that>
```

`.env` chỉ chứa secret (API key, token). Mọi cấu hình hành vi khác nằm ở `config.yaml`.

### 4. Trỏ model của profile sang Qwen nội bộ

Cách A — sửa `config.yaml` của profile (khối `model:` và `custom_providers:`), lấy mẫu trong `config.yaml.example` cùng thư mục này.

Cách B — chạy lại section model của wizard khi đang ở profile `foxai-qwen`:

```bash
hermes profile use foxai-qwen
hermes setup model
```

### 5. Kiểm chứng end-to-end

```bash
hermes profile use foxai-qwen
hermes chat -z "Trả lời đúng một từ: OK"
```

Nếu ra được câu trả lời từ model → profile chạy. `hermes doctor` để soát cấu hình/phụ thuộc.

## Gateway loopback (tùy chọn — chỉ khi cần agent/script khác trên VPS gọi vào)

```bash
hermes profile use foxai-qwen
hermes gateway run          # chạy foreground, cổng 8642 (loopback)
# hoặc chạy nền bền bỉ:
hermes gateway install      # tạo systemd unit trên Linux
```

Trên Linux `hermes gateway install` dùng systemd (khác Windows dùng Scheduled Task). Xác nhận bằng `hermes gateway status --deep`.

## Chưa kiểm chứng

- Toàn bộ quy trình này CHƯA chạy trên VPS Linux thật trong phiên soạn kit.
- Endpoint `222.252.99.27:8035` lấy từ memory 2026-08-17 — có thể đã đổi IP/cổng/model id.
- Cú pháp cờ của `hermes profile create` / `hermes setup model` theo bản trên máy nguồn; bản VPS có thể khác.
