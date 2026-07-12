# Báo cáo đối soát ngân hàng — Tháng 7/2026

**Ngân hàng:** mẫu (chưa xác định tên cụ thể trong brief — UNVERIFIABLE, cần bổ sung nếu báo cáo dùng cho mục đích chính thức)
**Kỳ đối soát:** 07/2026
**Tolerance ghép cặp:** ±1 ngày; số tiền phải khớp chính xác (không dung sai số tiền — brief không định nghĩa dung sai riêng)
**rules.yaml:** chưa tồn tại — ngân hàng mới, tháng đầu tiên → toàn bộ exception gắn CẦN NGƯỜI DUYỆT theo quy định.

## 1. Tóm tắt

10 giao dịch mỗi nguồn — khớp 8 · lệch 1 · bank-only 1 · ledger-only 1 · chênh tổng −3.780.000 VND (sổ − bank, tính trên nhóm lệch + ledger-only − bank-only).

## 2. Control totals từng nguồn

| Nguồn | Số dòng | Tổng nợ (âm) | Tổng có (dương) | Tổng ròng |
|---|---|---|---|---|
| `sao-ke-thang7.csv` (bank) | 10 | −23.920.000 | 113.250.000 | 89.330.000 |
| `so-phu-thang7.csv` (ledger) | 10 | −28.200.000 | 113.750.000 | 85.550.000 |

**Đối chiếu số dư đầu/cuối kỳ in trên sao kê:** KHÔNG THỰC HIỆN ĐƯỢC. File `sao-ke-thang7.csv` chỉ có 4 cột (`ngay, so_tien, ma_tham_chieu, dien_giai`), không có cột số dư đầu kỳ/cuối kỳ. Đây là giới hạn của dữ liệu nguồn, không phải bước bị bỏ qua. Nếu ngân hàng cung cấp bản có số dư, cần chạy lại bước này trước khi coi báo cáo là đầy đủ theo blueprint.

Không có căn cứ để phát hiện lệch control-total giữa hai nguồn tại bước này (không có số dư tham chiếu độc lập) — chênh lệch tổng ròng giữa hai nguồn (89.330.000 vs 85.550.000, chênh 3.780.000) được giải thích đầy đủ ở bước match (mục 4), không phải lỗi ingest.

## 3. Bảng cross-foot (4 nhóm)

| Nhóm | Số dòng | Tổng tiền — phía bank | Tổng tiền — phía ledger |
|---|---|---|---|
| Khớp | 8 | 74.550.000 | 74.550.000 |
| Lệch | 1 | 15.000.000 | 15.500.000 |
| Bank-only | 1 | −220.000 | — |
| Ledger-only | 1 | — | −4.500.000 |
| **Tổng cộng dọc** | **10 / 10** | **89.330.000** | **85.550.000** |
| **Đối chiếu với tổng nguồn (mục 2)** | khớp (10 = 10) | khớp (89.330.000 = 89.330.000) | khớp (85.550.000 = 85.550.000) |

Assert cross-foot chạy trong script `output/scripts/doisoat_thang7.py` — kết quả runtime thực tế:
```
=== ASSERT CROSS-FOOT: PASS ===
bank: 10 dong / 89,330,000 VND == nguon 10 dong / 89,330,000 VND
ledger: 10 dong / 85,550,000 VND == nguon 10 dong / 85,550,000 VND
```

## 4. Bảng exception (lệch + bank-only + ledger-only) — tất cả CẦN NGƯỜI DUYỆT

Ghi chú: tháng đầu tiên với ngân hàng này (`rules.yaml` chưa tồn tại) → theo quy định, **toàn bộ exception** gắn nhãn CẦN NGƯỜI DUYỆT để kế toán hiệu chỉnh tolerance/rule, kể cả case có vẻ rõ ràng.

### 4.1. Lệch (matched theo ref, nhưng số tiền khác nhau)

| Trace bank | Trace ledger | Tiêu chí match | Bank (VND) | Sổ (VND) | Chênh = sổ − bank | Nhãn |
|---|---|---|---|---|---|---|
| `sao-ke-thang7.csv:6` (REF005, 08/07) | `so-phu-thang7.csv:6` (REF005, 08/07) | mã tham chiếu (REF005 khớp 2 bên) | 15.000.000 | 15.500.000 | +500.000 | CẦN NGƯỜI DUYỆT — số tiền cùng ref nhưng khác nhau, cần kế toán xác minh giao dịch nào đúng (khả năng: sổ phụ ghi nhầm số tiền, hoặc bank statement thiếu một khoản phụ trội 500.000 chưa cấn trừ) |

### 4.2. Bank-only (chỉ có trên sao kê ngân hàng)

| Trace bank | Ngày | Số tiền (VND) | Ref | Diễn giải | Nhãn |
|---|---|---|---|---|---|
| `sao-ke-thang7.csv:8` | 12/07 | −220.000 | PHINH07 | Phi quan ly tai khoan | CẦN NGƯỜI DUYỆT — khoản phí ngân hàng thu tự động, chưa thấy bút toán tương ứng bên sổ phụ; kế toán cần xác nhận đã hạch toán hay chưa bổ sung bút toán chi phí |

### 4.3. Ledger-only (chỉ có trên sổ phụ kế toán)

| Trace ledger | Ngày | Số tiền (VND) | Ref | Diễn giải | Nhãn |
|---|---|---|---|---|---|
| `so-phu-thang7.csv:11` | 30/07 | −4.500.000 | REF010 | Tam ung du an X | CẦN NGƯỜI DUYỆT — bút toán tạm ứng đã ghi sổ nhưng chưa xuất hiện trên sao kê ngân hàng tính đến hết kỳ; kế toán cần xác nhận giao dịch đã thực chi qua ngân hàng hay còn treo/chưa đến hạn giải ngân |

## 5. Nhóm khớp (8 giao dịch — tham khảo, không cần duyệt)

Tất cả 8 giao dịch khớp theo tiêu chí **mã tham chiếu trùng khớp** (REF001, REF002, REF003, REF004, REF006, REF007, REF008, REF009), cùng ngày, cùng số tiền tuyệt đối giữa hai nguồn. Chi tiết đầy đủ (trace file:dòng từng cặp) trong `output/khop-thang7-2026.csv`.

## 6. File output

| File | Nội dung |
|---|---|
| `output/bao-cao-doi-soat-thang7-2026.md` | Báo cáo này |
| `output/khop-thang7-2026.csv` | 8 dòng khớp, đầy đủ trace 2 nguồn + tiêu chí match |
| `output/lech-thang7-2026.csv` | 1 dòng lệch (REF005), trace 2 nguồn, chênh, nhãn CẦN NGƯỜI DUYỆT |
| `output/bank-only-thang7-2026.csv` | 1 dòng chỉ có bên bank (PHINH07) |
| `output/ledger-only-thang7-2026.csv` | 1 dòng chỉ có bên sổ phụ (REF010) |
| `output/scripts/doisoat_thang7.py` | Script Python đã chạy — chứa toàn bộ logic ingest, control totals, match, assert cross-foot |
| `output/scripts/summary-thang7-2026.json` | Số liệu tổng hợp máy đọc được, dùng cho verifier |

## 7. Đề xuất cập nhật rules.yaml (chỉ đề xuất — người duyệt mới ghi)

- Ngân hàng này dùng mã tham chiếu dạng `REF0xx` cho giao dịch thu/chi thường xuyên — có thể đặt làm tiêu chí match ưu tiên 1 mặc định cho ngân hàng này.
- Riêng phí ngân hàng tự động thường có mã dạng `PHINH<số>` (ví dụ `PHINH07`), không có bút toán tương ứng bên sổ phụ theo mẫu hiện tại — đề xuất kế toán xác nhận có nên tự động phân loại các mã `PHINH*` là "phí ngân hàng, chờ hạch toán bổ sung" thay vì CẦN NGƯỜI DUYỆT mỗi lần, sau khi đã xác nhận pattern này lặp lại ổn định qua ít nhất 2-3 kỳ.
- Không đề xuất tolerance số tiền (ví dụ dung sai làm tròn) ở kỳ này vì mẫu dữ liệu quá nhỏ (10 giao dịch/nguồn) để rút ra pattern đáng tin cậy.

## 8. Phát hiện thêm (ngoài phạm vi xử lý của agent này)

- Giao dịch REF005 lệch đúng 500.000 VND — chênh lệch tròn số, không phải sai số làm tròn nhỏ, nên khả năng cao là sai sót nhập liệu một bên (không phải lỗi hệ thống). Đề nghị kế toán đối chiếu lại chứng từ gốc của REF005 (Thu tiền khách hàng D, 08/07/2026).
- File nguồn không có cột số dư đầu kỳ/cuối kỳ trên sao kê — nếu ngân hàng có cung cấp thêm cột này ở bản gốc (ví dụ do xuất báo cáo rút gọn), nên xin lại bản đầy đủ để chạy được control-total balance-check theo đúng blueprint (bước bắt buộc, hiện đang UNVERIFIABLE do thiếu dữ liệu nguồn).

## 9. Trạng thái

Trạng thái: VERIFIED PASS (vòng 1/2) — xem output/verdict-thang7-2026.md. [Cập nhật 2026-07-12 sau verdict]
