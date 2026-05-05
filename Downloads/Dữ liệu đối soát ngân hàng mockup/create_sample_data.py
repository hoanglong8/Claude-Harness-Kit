#!/usr/bin/env python
# -*- coding: utf-8 -*-
import pandas as pd
import os
import sys

# Force UTF-8 encoding on Windows
if sys.platform.startswith('win'):
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# Create input folder
os.makedirs("input", exist_ok=True)

# ========================================
# 1. Sample Apartment Fees File
# ========================================
apartments = [f"A{i:03d}" for i in range(1, 11)]  # A001 to A010
expected_fee = 3000000  # 3 triệu/tháng

df_fees = pd.DataFrame({
    "Apartment": apartments,
    "Expected": [expected_fee] * len(apartments)
})

df_fees.to_excel("input/apartment_fees.xlsx", index=False)
print(f"✅ Created: input/apartment_fees.xlsx ({len(df_fees)} rows)")

# ========================================
# 2. Sample Bank Statement File
# ========================================
transactions = [
    ("2026-04-01", "CHUYEN KHOAN - CAN A001 - TRAN MINH ANH", 3000000, 103000000, "TRF100001"),
    ("2026-04-02", "Transfer apartment A002 May Thu Ha", 3000000, 106000000, "TRF100002"),
    ("2026-04-03", "Phi chung cu can A003", 3000000, 109000000, "TRF100003"),
    ("2026-04-04", "A004 thanh toan phi", 3000000, 112000000, "TRF100004"),
    ("2026-04-05", "Apartment A005 monthly fee", 3000000, 115000000, "TRF100005"),
    ("2026-04-06", "A006 - Chi tiet 2.5 trieu", 2500000, 117500000, "TRF100006"),
    ("2026-04-07", "A007 - Chi tiet 3.5 trieu", 3500000, 121000000, "TRF100007"),
    ("2026-04-08", "A008 - Lan 1 - 1.5 trieu", 1500000, 122500000, "TRF100008"),
    ("2026-04-09", "A008 - Lan 2 - 1.5 trieu", 1500000, 124000000, "TRF100009"),
    ("2026-04-10", "Khach hang Le Ba The thanh toan A010", 3000000, 127000000, "TRF100010"),
    ("2026-04-11", "Phuong Tran sent money", 2500000, 129500000, "TRF100011"),
]

df_bank = pd.DataFrame(transactions, columns=["Date", "Description", "Credit", "Balance", "Ref"])
df_bank.to_excel("input/bank_statement.xlsx", index=False)
print(f"✅ Created: input/bank_statement.xlsx ({len(df_bank)} rows)")

print("\n📊 Sample Data Summary:")
print(f"   - Apartments: A001 to A010 (mỗi căn 3,000,000 VND)")
print(f"   - Transactions: {len(df_bank)} giao dịch")
print(f"   - Scenarios: Normal, Underpaid, Overpaid, Multiple, Fuzzy match, Unpaid (A009)")
print("\n✅ Ready to test!")
