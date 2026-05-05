# 🤖 AI Reconciliation Agent — Hệ thống đối soát phí chung cư tự động

## 📋 Giới thiệu

Hệ thống AI tự động đối soát phí chung cư bằng cách:
- 📊 So sánh danh sách phí dự kiến với sao kê ngân hàng
- 🧠 Sử dụng AI (Fuzzy Matching) để tìm ra căn hộ khi mô tả chuyển khoản không chuẩn
- 📈 Phân loại: Đã thanh toán, Thiếu tiền, Dư tiền, Chưa trả
- 📥 Xuất báo cáo Excel chi tiết

---

## 🚀 Cài đặt & Chạy

### 1. Cài đặt dependencies

```bash
pip install -r requirements.txt
```

### 2. Chạy ứng dụng

```bash
streamlit run app.py
```

Ứng dụng sẽ tự động mở ở `http://localhost:8501`

---

## 📂 Cấu trúc tệp

```
reconciliation-demo/
├── app.py                      # Ứng dụng Streamlit chính
├── requirements.txt            # Dependencies
├── README.md                   # File này
├── create_sample_data.py       # Script tạo sample data
├── input/                      # Thư mục chứa file input
│   ├── apartment_fees.xlsx     # Danh sách phí (mẫu)
│   └── bank_statement.xlsx     # Sao kê ngân hàng (mẫu)
└── output/                     # Thư mục output (sinh tự động)
```

---

## 📊 Hướng dẫn sử dụng

### Bước 1: Chuẩn bị dữ liệu

**File Phí Chung Cư** (`apartment_fees.xlsx`):
| Apartment | Expected |
|-----------|----------|
| A001      | 3000000  |
| A002      | 3000000  |
| ...       | ...      |

**File Sao Kê Ngân Hàng** (`bank_statement.xlsx`):
| Date       | Description                          | Credit   | Balance | Ref     |
|------------|--------------------------------------|----------|---------|---------|
| 2026-04-01 | CHUYEN KHOAN - CAN A001 - TRAN M...  | 3000000  | ...     | TRF001  |
| 2026-04-02 | Transfer apartment A002 May Thu Ha   | 3000000  | ...     | TRF002  |

### Bước 2: Upload file

- Nhấp vào **"File phí chung cư"** và chọn file `apartment_fees.xlsx`
- Nhấp vào **"File sao kê ngân hàng"** và chọn file `bank_statement.xlsx`

### Bước 3: Xem kết quả

Hệ thống sẽ tự động:
1. ✅ Match giao dịch với căn hộ
2. 📊 Tính tổng tiền từng căn hộ
3. 🔍 Phân loại trạng thái (Đã trả, Thiếu, Dư, Chưa trả)
4. ⚠️ Hiển thị giao dịch cần kiểm tra (confidence < 80%)

### Bước 4: Tải báo cáo

- Nhấp **"📥 Tải Excel kết quả đối soát"** để download
- Excel có 2 sheet:
  - **Reconciliation**: Tóm tắt từng căn hộ
  - **Transactions**: Chi tiết tất cả giao dịch

---

## 🧠 Cách AI hoạt động

### 1. **Regex Extraction** (Confidence = 100%)
Nếu mô tả giao dịch chứa mã căn hộ như "A001":
```
"CHUYEN KHOAN CAN A001" → Trích xuất "A001" → Match ngay
```

### 2. **Fuzzy Matching** (Confidence < 100%)
Nếu không tìm được mã căn hộ, so sánh mô tả với tất cả căn hộ:
```
"Khach hang Le Ba The thanh toan" → So sánh với A001, A002, ..., A010
→ Tìm ra căn hộ nào match nhất → Gợi ý kèm confidence score
```

---

## 🎯 Các scenario demo

File sample data đã chuẩn bị sẵn cho các scenario:

| Scenario | Apartment | Status | Note |
|----------|-----------|--------|------|
| Normal match | A001–A005 | ✅ MATCHED | Phí đầy đủ, mô tả rõ |
| Underpaid | A006 | ⚠️ UNDERPAID | Chỉ trả 2.5M thay vì 3M |
| Overpaid | A007 | 📈 OVERPAID | Trả 3.5M thay vì 3M |
| Multiple payments | A008 | ✅ MATCHED | 2 lần thanh toán (1.5M + 1.5M) |
| Fuzzy match | A010 | ~ (Gợi ý) | Mô tả không rõ, cần xác nhận |
| No payment | A009 | ❌ NO_PAYMENT | Chưa thanh toán |

---

## ⚙️ Cấu hình & Tùy chỉnh

### Thay đổi confidence threshold

Mở `app.py`, tìm dòng:
```python
unmatched_tx = df_tx[df_tx["Confidence"] < 0.8]
```

Thay `0.8` bằng giá trị khác (0.0–1.0):
- `0.5` = Chỉ hiển thị giao dịch < 50% confidence
- `0.9` = Hiển thị cả giao dịch > 90% confidence

### Thay đổi fuzzy match min score

Mở `app.py`, tìm dòng:
```python
apt, confidence = fuzzy_match(desc, apartments, min_score=50)
```

Thay `50` bằng giá trị khác (0–100):
- `30` = Cho phép match "yếu" hơn
- `80` = Chỉ cho phép match "mạnh"

---

## 🐛 Troubleshooting

### ❌ "ModuleNotFoundError: No module named 'streamlit'"
**Giải pháp:**
```bash
pip install -r requirements.txt
```

### ❌ "File not found" khi upload
**Giải pháp:** Đảm bảo file tồn tại và có định dạng `.xlsx`

### ❌ "KeyError" hoặc lỗi cột
**Giải pháp:** Kiểm tra file input có đúng số cột theo hướng dẫn

### ❌ Ứng dụng chạy chậm
**Giải pháp:** Dữ liệu lớn quá? Chia nhỏ file input (< 1000 giao dịch/lần)

---

## 📞 Hỗ trợ

Liên hệ Delivery Center Director — Nguyễn Hoàng Long
- Email: hoanglong208@gmail.com
- Company: FOXAI (fox.ai.vn)

---

## 📄 Ghi chú quan trọng

- ⚠️ Sample data chỉ dùng để demo — thay bằng dữ liệu thực
- 🔒 Không lưu file upload → dữ liệu an toàn trên máy local
- 📊 Báo cáo Excel tạo tự động → có thể dùng trực tiếp
- 🔄 Có thể upload file mới bất cứ lúc nào

---

**Happy Reconciliation! 🎉**
