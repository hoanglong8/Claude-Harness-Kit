#!/usr/bin/env python
# -*- coding: utf-8 -*-
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.units import inch

# Sample bank statement data
data = [
    ["Date", "Description", "Credit", "Balance", "Ref"],
    ["2026-04-01", "CHUYEN KHOAN - CAN A001 - TRAN MINH ANH", "3000000", "103000000", "TRF100001"],
    ["2026-04-02", "Transfer apartment A002 May Thu Ha", "3000000", "106000000", "TRF100002"],
    ["2026-04-03", "Phi chung cu can A003", "3000000", "109000000", "TRF100003"],
    ["2026-04-04", "A004 thanh toan phi", "3000000", "112000000", "TRF100004"],
    ["2026-04-05", "Apartment A005 monthly fee", "3000000", "115000000", "TRF100005"],
    ["2026-04-06", "A006 - Chi tiet 2.5 trieu", "2500000", "117500000", "TRF100006"],
    ["2026-04-07", "A007 - Chi tiet 3.5 trieu", "3500000", "121000000", "TRF100007"],
    ["2026-04-08", "A008 - Lan 1 - 1.5 trieu", "1500000", "122500000", "TRF100008"],
    ["2026-04-09", "A008 - Lan 2 - 1.5 trieu", "1500000", "124000000", "TRF100009"],
    ["2026-04-10", "Khach hang Le Ba The thanh toan A010", "3000000", "127000000", "TRF100010"],
    ["2026-04-11", "Phuong Tran sent money", "2500000", "129500000", "TRF100011"],
]

# Create PDF
pdf_file = "input/bank_statement_sample.pdf"
doc = SimpleDocTemplate(pdf_file, pagesize=letter)
story = []

# Title
styles = getSampleStyleSheet()
title = Paragraph("NGÂN HÀNG ABC - SAO KÊ THÁNG 4/2026", styles['Heading1'])
story.append(title)
story.append(Spacer(1, 0.2 * inch))

# Table
table = Table(data, colWidths=[1.2*inch, 2.5*inch, 1.2*inch, 1.2*inch, 1*inch])
table.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
    ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
    ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
    ('FONTSIZE', (0, 0), (-1, 0), 10),
    ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
    ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
    ('GRID', (0, 0), (-1, -1), 1, colors.black)
]))

story.append(table)

# Build PDF
doc.build(story)
print(f"✅ Created: {pdf_file}")
print("\n📊 PDF Sample Data:")
print(f"   - Header: {len(data[0])} columns (Date, Description, Credit, Balance, Ref)")
print(f"   - Rows: {len(data)-1} transactions")
print(f"   - Ready to test with app!")
