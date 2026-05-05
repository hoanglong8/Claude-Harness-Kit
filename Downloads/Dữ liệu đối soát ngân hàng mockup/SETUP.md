# ⚡ Quick Start — Setup và Demo cho Khách Hàng

## 🎯 Mục tiêu
Chạy app Streamlit localhost để demo AI Reconciliation Agent với khách hàng **trong 5 phút**.

---

## 📋 Yêu cầu
- **Python 3.9+** (kiểm tra: `python --version`)
- **Windows / Mac / Linux** (không yêu cầu)
- **Excel** (optional, chỉ để xem output)

---

## 🚀 Hướng dẫn từng bước

### Step 1: Cài dependencies

```bash
# Vào thư mục project
cd "C:\Users\Admin\Downloads\Dữ liệu đối soát ngân hàng mockup"

# Cài các thư viện cần thiết
pip install -r requirements.txt
```

**⏱️ Thời gian:** ~2 phút

**Output mong đợi:**
```
Successfully installed streamlit-1.35.0 pandas-2.1.4 openpyxl-3.11.0 ...
```

---

### Step 2: Chuẩn bị sample data

Sample data đã sẵn trong thư mục `input/`:
- ✅ `input/apartment_fees.xlsx` — 10 căn hộ A001–A010
- ✅ `input/bank_statement.xlsx` — 11 giao dịch demo

Nếu chưa có, chạy:
```bash
python create_sample_data.py
```

---

### Step 3: Chạy ứng dụng

```bash
streamlit run app.py
```

**Output mong đợi:**
```
Streamlit app running on http://localhost:8501
```

**Trình duyệt sẽ tự động mở** (nếu không, vào http://localhost:8501 manually)

---

## 📱 Sử dụng app

### Upload dữ liệu
1. Nhấn **"File phí chung cư"** → Chọn `input/apartment_fees.xlsx`
2. Nhấn **"File sao kê ngân hàng"** → Chọn `input/bank_statement.xlsx`

### Xem kết quả (tự động)
- 📊 Dashboard tóm tắt (tổng căn, matched, underpaid, etc.)
- 📋 Bảng chi tiết từng căn hộ (Status, Paid, Expected, Difference)
- 🔍 Giao dịch cần kiểm tra (Confidence < 80%)

### Download báo cáo
- Nhấp **"📥 Tải Excel kết quả đối soát"**
- File download: `reconciliation_result.xlsx` (2 sheet)

---

## 🎬 Demo Narrative cho Khách

**Bước 1 — Intro (30s)**
> "Hôm nay tôi demo cho bạn **AI Reconciliation Agent** — hệ thống tự động đối soát phí chung cư sử dụng AI.
> Thay vì Excel thủ công mất 2–4 giờ, chúng ta chỉ cần upload 2 file và click once → xong ngay! 🚀"

**Bước 2 — Upload (20s)**
> "Đây là file phí dự kiến — 10 căn hộ A001–A010, mỗi căn 3 triệu/tháng.
> Đây là sao kê ngân hàng — 11 giao dịch tháng này."
> 
> *(Upload cả 2 file)*

**Bước 3 — Matching (10s)**
> "Hệ thống AI đang xử lý... Nó tự động:
> - Tìm mã căn hộ trong mô tả giao dịch (Regex)
> - Nếu không tìm được, dùng **Fuzzy Matching** để gợi ý căn hộ khả năng cao nhất
> - Ghi confidence score để bạn kiểm tra lại"

**Bước 4 — Kết quả (20s)**
> "Xem dashboard — 10 căn, 5 căn đã thanh toán, 1 căn thiếu tiền, 1 căn dư, 1 chưa trả, 2 căn cần kiểm tra lại.
> Tất cả chi tiết ở bảng dưới — bạn có thể filter, sort, export Excel ngay."

**Bước 5 — Export (10s)**
> "Tải báo cáo Excel — có 2 sheet:
> - Sheet 1: Tóm tắt từng căn (Ready dùng)
> - Sheet 2: Chi tiết giao dịch (Audit trail)"

**Bước 6 — Q&A (Flexible)**
> "Hệ thống có thể mở rộng: learning loop, auto-suggest, webhook integration vào SAP B1, etc. Chúng ta cần gì?"

---

## 🎯 Các scenario để demo

### Scenario A — "Ai đã trả phí?"
1. Upload file
2. Nhìn dashboard → "5 căn đã trả, 1 chưa trả"
3. Download báo cáo → Gửi thư nhắc họ

### Scenario B — "Có giao dịch lạ không?"
1. Upload file
2. Scroll xuống → "🔍 Giao dịch cần kiểm tra"
3. Xem confidence score → "Cái này chỉ 45% match, không chắc chắn"

### Scenario C — "Có bao nhiêu tiền lệch?"
1. Upload file
2. Nhìn dashboard → "Thiếu 3,500,000 VND so với dự kiến"
3. Xem bảng → "Căn A006 trả 2.5M, dự kiến 3M → Thiếu 500k"

---

## 🔧 Customization (sau demo)

### Thay đổi confidence threshold
Sửa trong `app.py`:
```python
unmatched_tx = df_tx[df_tx["Confidence"] < 0.8]  # Thay 0.8 = 80%
```

### Thay đổi regex pattern (mã căn hộ)
Sửa trong `app.py`:
```python
match = re.search(r'(a\d{3})', desc.lower())  # "A001" format
```

### Thêm cột mới (e.g., "Người trả")
Sửa trong `app.py`, mục "Aggregation":
```python
summary = df_tx_matched.groupby(["Matched_Apartment", "Payer"]).agg({...})
```

---

## ⚠️ Lưu ý quan trọng

- ✅ **Data an toàn**: File upload KHÔNG được lưu → Chỉ xử lý trong memory
- ✅ **Localhost**: Chạy local máy → Không cần internet
- ✅ **Excel tự động**: Báo cáo Excel tạo ngay, không cần template
- ✅ **Extensible**: Dễ thêm tính năng (ML, webhook, schedule, etc.)

---

## 🆘 Troubleshooting

| Vấn đề | Giải pháp |
|-------|----------|
| `ModuleNotFoundError` | Chạy `pip install -r requirements.txt` |
| Ứng dụng không mở trình duyệt | Vào `http://localhost:8501` manually |
| Upload file lỗi | Kiểm tra file `.xlsx`, không phải `.csv` |
| Dashboard không hiển thị | Đợi 3–5 giây để Streamlit tính toán |
| Báo cáo Excel blank | File có thể không đúng cột, xem error message |

---

## 📞 Contact

**Delivery Center Director**
- Name: Nguyễn Hoàng Long
- Email: hoanglong208@gmail.com
- Company: FOXAI (fox.ai.vn)

---

**Ready to demo! 🎉**
