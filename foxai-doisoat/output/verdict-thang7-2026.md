VERDICT: PASS — Vòng 1/2

| # | Check | Kết quả | Bằng chứng (số liệu từ script) |
|---|-------|---------|--------------------------------|
| a | Đủ-đúng-1-lần | PASS | Bank: 10/10 dòng khớp, Ledger: 10/10 dòng khớp. Không sót, không trùng lặp, không dòng lạ |
| b | Cross-foot tổng | PASS | Khớp: 74.550.000 + Lệch: 15.000.000 + Bank-only: -220.000 = 89.330.000 (Bank source) ✓ · Khớp: 74.550.000 + Lệch: 15.500.000 + Ledger-only: -4.500.000 = 85.550.000 (Ledger source) ✓ |
| c | Chênh = sổ − bank | PASS | 1/1 dòng lệch: REF005 chênh = 15.500.000 − 15.000.000 = 500.000 (file ghi chenh_so_tru_bank = 500.000) ✓ |
| d | Fuzzy match 100% | PASS | 8/8 cặp khớp: mã_tham_chiếu (ma_tham_chieu) + cùng ngày (cung_ngay = True) + số tiền khớp chính xác · 1/1 cặp lệch: REF005, ngày khớp, tiêu chí match hợp lệ |

## Tóm tắt phát hiện

Báo cáo đối soát tháng 7/2026 **đầy đủ, chính xác và nhất quán** với file nguồn:
- Tất cả 20 giao dịch (10 bank + 10 ledger) được phân bổ đúng 1 lần.
- Tổng tiền từng nhóm cross-foot chính xác với nguồn (không sai lệch 1 đồng).
- Tiêu chí ghép cặp là mã tham chiếu (ma_tham_chieu), phù hợp dữ liệu.
- Các exception (lệch, bank-only, ledger-only) được ghi nhãn "CẦN NGƯỜI DUYỆT" đúng quy trình, không có sai lệch logic.

## Không phát hiện sai lệch nào

- Không thiếu giao dịch
- Không trùng lặp
- Không ghép sai cặp
- Không sai công thức chênh
- Không sai dấu hoặc giá trị số liệu

## BƯỚC TIẾP
**PASS → giao kế toán duyệt exception và cập nhật rules (nếu cần), rồi khóa kỳ.**
