# 📘 PHẦN 1 — USE CASE TÀI LIỆU (CHO KHÁCH HÀNG)

## 1. Tổng quan bài toán

### Bối cảnh

Ban quản lý chung cư / doanh nghiệp quản lý tài sản:

* Thu phí hàng tháng từ cư dân
* Nhận tiền qua chuyển khoản ngân hàng
* Kế toán phải đối soát:

  * Ai đã trả
  * Ai chưa trả
  * Ai trả thiếu / dư

---

### Pain hiện tại

| Vấn đề                            | Tác động               |
| --------------------------------- | ---------------------- |
| Đối soát thủ công Excel           | 2–4h/ngày              |
| Nội dung chuyển khoản không chuẩn | khó match              |
| Sai sót                           | ảnh hưởng tài chính    |
| Không scale                       | càng nhiều căn càng vỡ |

---

## 2. Use Case chính

### UC1 — Đối soát thanh toán phí chung cư

**Input:**

* File phí (Expected)
* File sao kê ngân hàng

**Output:**

* Danh sách:

  * Đã thanh toán
  * Chưa thanh toán
  * Thiếu / dư tiền

---

### UC2 — Phát hiện giao dịch không xác định

**Vấn đề:**

* Người chuyển không ghi căn hộ

**AI xử lý:**

* Fuzzy matching
* Suggest căn hộ với confidence

---

### UC3 — Phát hiện bất thường (Anomaly)

* Một căn trả nhiều lần
* Trả dư tiền
* Giao dịch không thuộc danh sách căn hộ

---

### UC4 — Tự động hóa đối soát hàng tháng

* Upload file
* Click 1 lần
* Xuất báo cáo

---

## 3. Giá trị mang lại

### ROI cho khách

* ⏱ Giảm 80–90% thời gian đối soát
* 🎯 Giảm sai sót thủ công
* 📊 Chuẩn hóa dữ liệu

---

## 4. Điểm khác biệt (USP)

Không chỉ là Excel tool:

👉 Có AI:

* Fuzzy matching
* Confidence score
* Gợi ý match

---

# 📙 PHẦN 2 — TECHNICAL DOCUMENT

## 1. Kiến trúc tổng thể

```
User (Upload Excel)
        ↓
Frontend (Streamlit)
        ↓
Processing Layer (pandas)
        ↓
AI Matching (fuzzy logic)
        ↓
Aggregation + Classification
        ↓
Output (Dashboard + Excel)
```

---

## 2. Tech Stack

| Layer           | Công nghệ |
| --------------- | --------- |
| UI              | Streamlit |
| Data Processing | pandas    |
| Excel IO        | openpyxl  |
| AI Matching     | RapidFuzz |
| Text Normalize  | Unidecode |

---

## 3. Cấu trúc dữ liệu

### 3.1 File phí chung cư

| Column    | Type   |
| --------- | ------ |
| Apartment | string |
| Expected  | number |

---

### 3.2 File sao kê ngân hàng

| Column      | Type   |
| ----------- | ------ |
| Date        | date   |
| Description | string |
| Credit      | number |
| Balance     | number |
| Ref         | string |

---

## 4. Logic xử lý

### 4.1 Normalize dữ liệu

* Lowercase
* Remove dấu tiếng Việt
* Clean text

---

### 4.2 Extract căn hộ (Regex)

```regex
(A\d{3})
```

---

### 4.3 Fuzzy Matching

```python
score = fuzz.partial_ratio(apartment, description)
```

---

### 4.4 Aggregation

```python
group by apartment → sum(Credit)
```

---

### 4.5 Classification

| Status     | Logic            |
| ---------- | ---------------- |
| MATCHED    | Paid == Expected |
| UNDERPAID  | Paid < Expected  |
| OVERPAID   | Paid > Expected  |
| NO_PAYMENT | Paid == 0        |

---

## 5. Cài đặt môi trường

### 5.1 Yêu cầu

* Python >= 3.9

---

### 5.2 Cài thư viện

```bash
pip install streamlit pandas openpyxl rapidfuzz unidecode
```

---

## 6. Cấu trúc project

```
reconciliation-demo/
│
├── app.py
├── input/
│   ├── apartment_fees.xlsx
│   └── bank_statement.xlsx
└── output/
```

---

## 7. Chạy ứng dụng

```bash
streamlit run app.py
```

Truy cập:

```
http://localhost:8501
```

---

## 8. Flow demo với khách

### Bước 1 — Upload

* File phí
* File sao kê

---

### Bước 2 — AI xử lý

Narrative:

> “Hệ thống AI đang tự động đọc và đối soát dữ liệu…”

---

### Bước 3 — Hiển thị kết quả

* Dashboard:

  * Tổng căn hộ
  * Số matched
  * Số lỗi

---

### Bước 4 — Drill-down

* Xem unmatched
* Show confidence

---

### Bước 5 — Export

* Download Excel

---

## 9. Giới hạn hiện tại

* Chưa xử lý:

  * nhiều giao dịch / 1 căn
  * sai định dạng phức tạp
* Chưa có:

  * learning loop
  * model training

---

## 10. Roadmap nâng cấp

### Phase 1

* Rule-based + fuzzy (hiện tại)

---

### Phase 2

* Confidence scoring nâng cao
* Pattern learning theo khách

---

### Phase 3

* AI Agent:

  * tự học
  * tự tối ưu matching

---

# 🎯 KẾT LUẬN

Bạn đang có:

* 1 demo chạy được
* 1 use case rõ ràng
* 1 câu chuyện bán hàng tốt

👉 Điều bạn cần làm tiếp:

* Demo cho 2–3 khách
* Lấy feedback
* Chốt pilot
