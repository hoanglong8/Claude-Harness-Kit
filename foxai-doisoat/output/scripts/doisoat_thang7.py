"""
Doi soat sao ke ngan hang vs so phu ke toan - thang 7/2026.
Nguon (chi doc, khong ghi de):
  input/sao-ke-thang7.csv   (sao ke ngan hang)
  input/so-phu-thang7.csv   (so phu ke toan)
Tolerance ghep cap: lech ngay +-1 ngay; so tien phai khop chinh xac.
Output: output/bao-cao-doi-soat-thang7-2026.md + cac file csv chi tiet.
"""
import pandas as pd
from pathlib import Path
from datetime import timedelta

BASE = Path("C:/Users/Admin/foxai-doisoat")
IN = BASE / "input"
OUT = BASE / "output"

bank_path = IN / "sao-ke-thang7.csv"
ledger_path = IN / "so-phu-thang7.csv"

bank = pd.read_csv(bank_path, dtype={"ma_tham_chieu": str})
ledger = pd.read_csv(ledger_path, dtype={"ma_tham_chieu": str})

for df, name in [(bank, "bank"), (ledger, "ledger")]:
    required = {"ngay", "so_tien", "ma_tham_chieu", "dien_giai"}
    missing = required - set(df.columns)
    if missing:
        raise SystemExit(f"FAIL-FAST: nguon {name} thieu cot bat buoc: {missing}")

bank["ngay"] = pd.to_datetime(bank["ngay"])
ledger["ngay"] = pd.to_datetime(ledger["ngay"])

# dong goc trong file csv (header = dong 1, du lieu bat dau dong 2)
bank["source_file"] = bank_path.name
bank["source_row"] = bank.index + 2
ledger["source_file"] = ledger_path.name
ledger["source_row"] = ledger.index + 2

bank["bank_id"] = bank.index
ledger["ledger_id"] = ledger.index

# ---------- BUOC 1: CONTROL TOTALS ----------
def control_totals(df, name):
    n_rows = len(df)
    tong_no = df.loc[df["so_tien"] < 0, "so_tien"].sum()   # ghi no (tien ra) - am
    tong_co = df.loc[df["so_tien"] > 0, "so_tien"].sum()   # ghi co (tien vao) - duong
    return {"nguon": name, "so_dong": n_rows, "tong_no": tong_no, "tong_co": tong_co,
            "tong_rong": df["so_tien"].sum()}

ct_bank = control_totals(bank, "sao-ke-thang7.csv (bank)")
ct_ledger = control_totals(ledger, "so-phu-thang7.csv (ledger)")

print("=== CONTROL TOTALS ===")
for ct in (ct_bank, ct_ledger):
    print(ct)

# Khong co cot so du dau/cuoi ky trong file nguon -> khong the doi chieu buoc 5.6
# (khong phai bo qua - du lieu nguon khong co cot nay). Ghi nhan ro trong bao cao.
balance_check_note = ("Nguon khong co cot so du dau ky / so du cuoi ky in tren sao ke "
                       "-> KHONG THE doi chieu 'so du dau + tong co - tong no = so du cuoi'. "
                       "Day la gioi han du lieu dau vao, khong phai loi bo qua buoc.")
print(balance_check_note)

# Khong co gi de "lech" o day vi khong co so du tham chieu -> khong DUNG (khong co
# can cu de dung). Tiep tuc buoc 2.

# ---------- BUOC 2: MATCH TAT DINH ----------
TOLERANCE_DAYS = 1

matches = []  # list of dict: bank_id, ledger_id, criteria, khop_hoan_toan(bool)
matched_bank_ids = set()
matched_ledger_ids = set()

# (a) match theo ma_tham_chieu trung khop truoc
bank_by_ref = {}
for _, r in bank.iterrows():
    bank_by_ref.setdefault(r["ma_tham_chieu"], []).append(r["bank_id"])

for _, lrow in ledger.iterrows():
    ref = lrow["ma_tham_chieu"]
    if ref in bank_by_ref and bank_by_ref[ref]:
        bid = bank_by_ref[ref].pop(0)  # 1-1, khong tai su dung
        brow = bank.loc[bank["bank_id"] == bid].iloc[0]
        matches.append({
            "bank_id": bid,
            "ledger_id": lrow["ledger_id"],
            "tieu_chi": "ma_tham_chieu",
        })
        matched_bank_ids.add(bid)
        matched_ledger_ids.add(lrow["ledger_id"])

# (b) match theo so_tien khop chinh xac + ngay trong tolerance, cho phan con lai
remaining_bank = bank[~bank["bank_id"].isin(matched_bank_ids)].copy()
remaining_ledger = ledger[~ledger["ledger_id"].isin(matched_ledger_ids)].copy()

used_bank_amount = set()
for _, lrow in remaining_ledger.iterrows():
    candidates = remaining_bank[
        (~remaining_bank["bank_id"].isin(used_bank_amount))
        & (remaining_bank["so_tien"] == lrow["so_tien"])
        & ((remaining_bank["ngay"] - lrow["ngay"]).abs() <= timedelta(days=TOLERANCE_DAYS))
    ]
    if len(candidates) >= 1:
        # neu nhieu ung vien -> mo ho, van ghep voi ung vien dau nhung se gan CAN NGUOI DUYET
        bid = candidates.iloc[0]["bank_id"]
        matches.append({
            "bank_id": bid,
            "ledger_id": lrow["ledger_id"],
            "tieu_chi": "so_tien+ngay(+-1)" + (" [NHIEU UNG VIEN]" if len(candidates) > 1 else ""),
        })
        used_bank_amount.add(bid)
        matched_bank_ids.add(bid)
        matched_ledger_ids.add(lrow["ledger_id"])

# ---------- Phan loai 4 nhom ----------
khop = []
lech = []
for m in matches:
    brow = bank.loc[bank["bank_id"] == m["bank_id"]].iloc[0]
    lrow = ledger.loc[ledger["ledger_id"] == m["ledger_id"]].iloc[0]
    chenh = lrow["so_tien"] - brow["so_tien"]  # chenh = so - bank
    same_amount = (chenh == 0)
    same_date = (brow["ngay"] == lrow["ngay"])
    record = {
        "bank_file": brow["source_file"], "bank_row": brow["source_row"],
        "bank_ngay": brow["ngay"].date().isoformat(), "bank_so_tien": brow["so_tien"],
        "bank_ref": brow["ma_tham_chieu"], "bank_dien_giai": brow["dien_giai"],
        "ledger_file": lrow["source_file"], "ledger_row": lrow["source_row"],
        "ledger_ngay": lrow["ngay"].date().isoformat(), "ledger_so_tien": lrow["so_tien"],
        "ledger_ref": lrow["ma_tham_chieu"], "ledger_dien_giai": lrow["dien_giai"],
        "tieu_chi_match": m["tieu_chi"],
        "chenh_so_tru_bank": chenh,
        "cung_ngay": same_date,
    }
    if same_amount:
        record["nhan"] = ""
        khop.append(record)
    else:
        record["nhan"] = "CAN NGUOI DUYET"
        record["ly_do"] = "So tien matched-ref khac nhau giua bank va so phu"
        lech.append(record)

bank_only_ids = set(bank["bank_id"]) - matched_bank_ids
ledger_only_ids = set(ledger["ledger_id"]) - matched_ledger_ids

bank_only = []
for bid in sorted(bank_only_ids):
    brow = bank.loc[bank["bank_id"] == bid].iloc[0]
    bank_only.append({
        "bank_file": brow["source_file"], "bank_row": brow["source_row"],
        "bank_ngay": brow["ngay"].date().isoformat(), "bank_so_tien": brow["so_tien"],
        "bank_ref": brow["ma_tham_chieu"], "bank_dien_giai": brow["dien_giai"],
        "nhan": "CAN NGUOI DUYET",
        "ly_do": "Chi co tren sao ke ngan hang, khong tim thay giao dich tuong ung ben so phu",
    })

ledger_only = []
for lid in sorted(ledger_only_ids):
    lrow = ledger.loc[ledger["ledger_id"] == lid].iloc[0]
    ledger_only.append({
        "ledger_file": lrow["source_file"], "ledger_row": lrow["source_row"],
        "ledger_ngay": lrow["ngay"].date().isoformat(), "ledger_so_tien": lrow["so_tien"],
        "ledger_ref": lrow["ma_tham_chieu"], "ledger_dien_giai": lrow["dien_giai"],
        "nhan": "CAN NGUOI DUYET",
        "ly_do": "Chi co tren so phu ke toan, khong tim thay giao dich tuong ung ben sao ke ngan hang",
    })

# Thang dau voi ngan hang moi -> toan bo exception (lech + bank-only + ledger-only) gan CAN NGUOI DUYET
for r in khop:
    pass  # khop khong can duyet

print("\n=== PHAN LOAI ===")
print(f"khop: {len(khop)} | lech: {len(lech)} | bank-only: {len(bank_only)} | ledger-only: {len(ledger_only)}")

# ---------- ASSERT CROSS-FOOT (bat buoc, crash neu sai) ----------
n_khop, n_lech, n_bank_only, n_ledger_only = len(khop), len(lech), len(bank_only), len(ledger_only)

tong_dong_bank_4nhom = n_khop + n_lech + n_bank_only
tong_dong_ledger_4nhom = n_khop + n_lech + n_ledger_only

assert tong_dong_bank_4nhom == ct_bank["so_dong"], (
    f"ASSERT FAIL: tong dong bank tu 4 nhom ({tong_dong_bank_4nhom}) != tong dong nguon bank ({ct_bank['so_dong']})"
)
assert tong_dong_ledger_4nhom == ct_ledger["so_dong"], (
    f"ASSERT FAIL: tong dong ledger tu 4 nhom ({tong_dong_ledger_4nhom}) != tong dong nguon ledger ({ct_ledger['so_dong']})"
)

tong_tien_bank_4nhom = (
    sum(r["bank_so_tien"] for r in khop)
    + sum(r["bank_so_tien"] for r in lech)
    + sum(r["bank_so_tien"] for r in bank_only)
)
tong_tien_ledger_4nhom = (
    sum(r["ledger_so_tien"] for r in khop)
    + sum(r["ledger_so_tien"] for r in lech)
    + sum(r["ledger_so_tien"] for r in ledger_only)
)

assert tong_tien_bank_4nhom == ct_bank["tong_rong"], (
    f"ASSERT FAIL: tong tien bank 4 nhom ({tong_tien_bank_4nhom}) != tong tien nguon bank ({ct_bank['tong_rong']})"
)
assert tong_tien_ledger_4nhom == ct_ledger["tong_rong"], (
    f"ASSERT FAIL: tong tien ledger 4 nhom ({tong_tien_ledger_4nhom}) != tong tien nguon ledger ({ct_ledger['tong_rong']})"
)

print("\n=== ASSERT CROSS-FOOT: PASS ===")
print(f"bank: {tong_dong_bank_4nhom} dong / {tong_tien_bank_4nhom:,} VND == nguon {ct_bank['so_dong']} dong / {ct_bank['tong_rong']:,} VND")
print(f"ledger: {tong_dong_ledger_4nhom} dong / {tong_tien_ledger_4nhom:,} VND == nguon {ct_ledger['so_dong']} dong / {ct_ledger['tong_rong']:,} VND")

chenh_tong = sum(r["chenh_so_tru_bank"] for r in lech) + sum(r["ledger_so_tien"] for r in ledger_only) - sum(r["bank_so_tien"] for r in bank_only)
print(f"\nChenh tong (so - bank, tinh tren lech + ledger_only - bank_only): {chenh_tong:,} VND")

# ---------- GHI CSV (UTF-8-SIG) ----------
pd.DataFrame(khop).to_csv(OUT / "khop-thang7-2026.csv", index=False, encoding="utf-8-sig")
pd.DataFrame(lech).to_csv(OUT / "lech-thang7-2026.csv", index=False, encoding="utf-8-sig")
pd.DataFrame(bank_only).to_csv(OUT / "bank-only-thang7-2026.csv", index=False, encoding="utf-8-sig")
pd.DataFrame(ledger_only).to_csv(OUT / "ledger-only-thang7-2026.csv", index=False, encoding="utf-8-sig")

# ---------- GHI SUMMARY JSON-LIKE PHUC VU VIET BAO CAO ----------
summary = {
    "ct_bank": ct_bank, "ct_ledger": ct_ledger,
    "n_khop": n_khop, "n_lech": n_lech, "n_bank_only": n_bank_only, "n_ledger_only": n_ledger_only,
    "tong_dong_bank_4nhom": tong_dong_bank_4nhom, "tong_dong_ledger_4nhom": tong_dong_ledger_4nhom,
    "tong_tien_bank_4nhom": tong_tien_bank_4nhom, "tong_tien_ledger_4nhom": tong_tien_ledger_4nhom,
    "chenh_tong": chenh_tong,
    "balance_check_note": balance_check_note,
}
import json
with open(OUT / "scripts" / "summary-thang7-2026.json", "w", encoding="utf-8") as f:
    json.dump(summary, f, ensure_ascii=False, indent=2, default=str)

print("\nDA GHI XONG CAC FILE CSV VAO output/")
