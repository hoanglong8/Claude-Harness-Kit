import streamlit as st
import pandas as pd
from rapidfuzz import fuzz
from unidecode import unidecode
import re
from io import BytesIO
import logging
import pdfplumber

# Logging setup
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

st.set_page_config(page_title="AI Reconciliation Agent", layout="wide")

st.title("🤖 AI Reconciliation Agent – Đối soát phí chung cư")

# -----------------------
# Utils
# -----------------------
def normalize(text):
    """Normalize text: lowercase + remove diacritics."""
    if pd.isna(text):
        return ""
    return unidecode(str(text).lower().strip())

def extract_apartment(desc):
    """Extract apartment code from description (e.g., 'A001' or 'a001')."""
    match = re.search(r'(a\d{3})', desc.lower())
    return match.group(1).upper() if match else None

def fuzzy_match(desc, apartments, min_score=50):
    """
    Fuzzy match description to apartment list.
    Returns (apartment_code, confidence_score_0to1).
    """
    if not apartments:
        return None, 0.0

    best = None
    best_score = 0

    for apt in apartments:
        score = fuzz.partial_ratio(apt.lower(), desc.lower())
        if score > best_score:
            best_score = score
            best = apt

    # Only return match if score >= min_score, else no match
    if best_score >= min_score:
        return best, best_score / 100
    return None, best_score / 100

def validate_fee_file(df):
    """Validate fee file has correct columns and data types."""
    try:
        if len(df.columns) < 2:
            raise ValueError("File phí phải có ít nhất 2 cột (Apartment, Expected)")

        df.columns = ["Apartment", "Expected"]

        # Ensure Apartment is string, Expected is numeric
        df["Apartment"] = df["Apartment"].astype(str).str.upper().str.strip()
        df["Expected"] = pd.to_numeric(df["Expected"], errors='coerce')

        if df["Expected"].isna().any():
            st.warning("⚠️ Phát hiện cột Expected có giá trị không phải số → chuyển thành 0")
            df["Expected"] = df["Expected"].fillna(0)

        return df
    except Exception as e:
        raise ValueError(f"Lỗi đọc file phí: {str(e)}")

def validate_bank_file(df):
    """Validate bank statement file has correct columns and data types."""
    try:
        if len(df.columns) < 3:
            raise ValueError("File sao kê phải có ít nhất 3 cột (Date, Description, Credit)")

        # Only take first 5 columns, rename them
        if len(df.columns) > 5:
            df = df.iloc[:, :5]  # Take only first 5 columns

        df.columns = ["Date", "Description", "Credit", "Balance", "Ref"][:len(df.columns)]

        # Validate Date column (if exists)
        if "Date" in df.columns:
            try:
                df["Date"] = pd.to_datetime(df["Date"], errors='coerce')
            except:
                pass  # Skip if date parsing fails

        # Ensure Description is string
        if "Description" in df.columns:
            df["Description"] = df["Description"].astype(str)

        # Ensure Credit is numeric (REQUIRED)
        if "Credit" not in df.columns:
            raise ValueError("File sao kê phải có cột 'Credit' (cột thứ 3)")

        # Clean Credit column: remove commas, spaces, convert to numeric
        def clean_numeric(val):
            if pd.isna(val):
                return 0
            try:
                # Remove whitespace, commas, currency symbols
                cleaned = str(val).strip().replace(',', '').replace('.', '').replace('₫', '').replace('VND', '').strip()
                return float(cleaned) if cleaned else 0
            except:
                return 0

        df["Credit"] = df["Credit"].apply(clean_numeric)

        # Remove rows with 0 or negative credit
        df = df[df["Credit"] > 0].reset_index(drop=True)

        if len(df) == 0:
            st.error("❌ Không có giao dịch nào có số tiền > 0. Kiểm tra file sao kê có đúng format không.")
            raise ValueError("Không có giao dịch hợp lệ")

        return df
    except Exception as e:
        raise ValueError(f"Lỗi đọc file sao kê: {str(e)}")


def extract_bank_data_from_pdf(pdf_file):
    """Extract bank statement data from PDF using pdfplumber."""
    try:
        with pdfplumber.open(pdf_file) as pdf:
            all_tables = []

            # Extract tables from all pages
            for page_num, page in enumerate(pdf.pages):
                tables = page.extract_tables()
                if tables:
                    for table in tables:
                        all_tables.append(table)

            if not all_tables:
                raise ValueError("Không tìm thấy table nào trong PDF")

            # Merge all tables
            all_rows = []
            for table in all_tables:
                all_rows.extend(table)

            if len(all_rows) < 2:
                raise ValueError("PDF table quá nhỏ (ít nhất 2 dòng)")

            # First row = header, rest = data
            headers = all_rows[0]
            data_rows = all_rows[1:]

            # Create DataFrame
            df = pd.DataFrame(data_rows, columns=headers)

            logger.info(f"✅ Extracted {len(df)} rows from PDF with {len(headers)} columns")

            return df
    except Exception as e:
        raise ValueError(f"Lỗi đọc PDF: {str(e)}")

# -----------------------
# Upload & Caching
# -----------------------
st.sidebar.header("📤 Upload dữ liệu")

fee_file = st.sidebar.file_uploader("File phí chung cư (.xlsx)", type=["xlsx"], help="Cột: Apartment | Expected")

# Bank file can be .xlsx or .pdf
bank_file_format = st.sidebar.radio("Format file sao kê:", ["Excel (.xlsx)", "PDF (.pdf)"], horizontal=True)

if bank_file_format == "Excel (.xlsx)":
    bank_file = st.sidebar.file_uploader("File sao kê ngân hàng (.xlsx)", type=["xlsx"], help="Cột: Date | Description | Credit | (Balance) | (Ref)")
else:
    bank_file = st.sidebar.file_uploader("File sao kê ngân hàng (.pdf)", type=["pdf"], help="PDF phải có table với cột: Date | Description | Credit")

if fee_file and bank_file:
    try:
        # -----------------------
        # Load & Validate data
        # -----------------------
        with st.spinner("⏳ Đang xử lý dữ liệu..."):
            # Load fee file (always Excel)
            df_fee = pd.read_excel(fee_file)
            df_fee = validate_fee_file(df_fee)

            # Load bank file (Excel or PDF)
            if bank_file_format == "PDF (.pdf)":
                df_bank = extract_bank_data_from_pdf(bank_file)
            else:
                df_bank = pd.read_excel(bank_file)

            df_bank = validate_bank_file(df_bank)

            logger.info(f"✅ Load thành công: {len(df_fee)} căn hộ, {len(df_bank)} giao dịch")

        apartments = df_fee["Apartment"].tolist()

        # -----------------------
        # AI Matching
        # -----------------------
        st.info(f"🤖 Đang match {len(df_bank)} giao dịch với {len(apartments)} căn hộ...")

        results = []

        for _, row in df_bank.iterrows():
            desc = normalize(row["Description"])

            # Step 1: Try regex extract
            apt = extract_apartment(desc)
            confidence = 1.0 if apt else 0.0

            # Step 2: If regex fails, try fuzzy match
            if not apt:
                apt, confidence = fuzzy_match(desc, apartments, min_score=50)

            results.append({
                "Date": row["Date"],
                "Description": row["Description"],
                "Credit": row["Credit"],
                "Matched_Apartment": apt if apt else "UNKNOWN",
                "Confidence": round(confidence, 2)
            })

        df_tx = pd.DataFrame(results)
        logger.info(f"✅ Matching xong: {(df_tx['Confidence'] >= 0.8).sum()} high-confidence matches")

        # -----------------------
        # Aggregation (group by apartment, sum credit)
        # -----------------------
        # Filter out UNKNOWN matches (low confidence)
        df_tx_matched = df_tx[df_tx["Matched_Apartment"] != "UNKNOWN"]

        summary = df_tx_matched.groupby("Matched_Apartment")["Credit"].sum().reset_index()
        summary.columns = ["Apartment", "Paid"]
        summary["Apartment"] = summary["Apartment"].str.upper().str.strip()

        # Merge with fee data (left join: giữ tất cả căn hộ từ fee file)
        df_final = df_fee.merge(summary, on="Apartment", how="left")
        df_final["Paid"] = df_final["Paid"].fillna(0)

        # -----------------------
        # Classification
        # -----------------------
        def classify(row):
            if row["Paid"] == 0:
                return "❌ NO_PAYMENT"
            elif abs(row["Paid"] - row["Expected"]) < 0.01:  # Allow 0.01 tolerance for float comparison
                return "✅ MATCHED"
            elif row["Paid"] < row["Expected"]:
                return "⚠️ UNDERPAID"
            else:
                return "📈 OVERPAID"

        df_final["Status"] = df_final.apply(classify, axis=1)

        # Add difference column
        df_final["Difference"] = df_final["Paid"] - df_final["Expected"]

        logger.info(f"Classification: {df_final['Status'].value_counts().to_dict()}")

        # -----------------------
        # Dashboard
        # -----------------------
        st.subheader("📊 Dashboard Tổng Quan")

        col1, col2, col3, col4 = st.columns(4)

        with col1:
            st.metric("📦 Tổng căn hộ", len(df_final))
        with col2:
            matched = (df_final["Status"] == "✅ MATCHED").sum()
            st.metric("✅ Đã thanh toán", matched, f"{matched/len(df_final)*100:.0f}%")
        with col3:
            underpaid = (df_final["Status"] == "⚠️ UNDERPAID").sum()
            st.metric("⚠️ Thiếu tiền", underpaid, f"{underpaid/len(df_final)*100:.0f}%")
        with col4:
            no_payment = (df_final["Status"] == "❌ NO_PAYMENT").sum()
            st.metric("❌ Chưa trả", no_payment, f"{no_payment/len(df_final)*100:.0f}%")

        st.divider()

        # -----------------------
        # Summary Statistics
        # -----------------------
        col1, col2, col3 = st.columns(3)
        with col1:
            total_expected = df_final["Expected"].sum()
            st.metric("💰 Tổng phí dự kiến", f"{total_expected:,.0f} VND")
        with col2:
            total_paid = df_final["Paid"].sum()
            st.metric("💵 Tổng tiền nhận", f"{total_paid:,.0f} VND")
        with col3:
            gap = total_expected - total_paid
            st.metric("📊 Chênh lệch", f"{gap:,.0f} VND", delta=f"{gap/total_expected*100:.1f}%" if total_expected > 0 else "")

        st.divider()

        # -----------------------
        # Table results
        # -----------------------
        st.subheader("📋 Chi tiết đối soát từng căn hộ")

        # Format display columns
        df_display = df_final.copy()
        df_display["Expected"] = df_display["Expected"].apply(lambda x: f"{x:,.0f}")
        df_display["Paid"] = df_display["Paid"].apply(lambda x: f"{x:,.0f}")
        df_display["Difference"] = df_display["Difference"].apply(lambda x: f"{x:+,.0f}")

        st.dataframe(df_display[["Apartment", "Expected", "Paid", "Difference", "Status"]],
                     use_container_width=True, hide_index=True)

        # -----------------------
        # Unmatched / Low Confidence Transactions
        # -----------------------
        st.subheader("🔍 Giao dịch cần kiểm tra lại (Confidence < 80%)")

        unmatched_tx = df_tx[df_tx["Confidence"] < 0.8].copy()

        if len(unmatched_tx) > 0:
            unmatched_tx["Confidence"] = (unmatched_tx["Confidence"] * 100).round(0).astype(int).astype(str) + "%"
            st.warning(f"⚠️ Có {len(unmatched_tx)} giao dịch chưa match rõ")
            st.dataframe(unmatched_tx[["Date", "Description", "Credit", "Matched_Apartment", "Confidence"]],
                        use_container_width=True, hide_index=True)
        else:
            st.success("✅ Tất cả giao dịch đều match rõ ràng!")

        # -----------------------
        # Export to Excel
        # -----------------------
        st.subheader("⬇️ Tải xuống kết quả")

        def to_excel(df1, df2):
            output = BytesIO()
            with pd.ExcelWriter(output, engine='openpyxl') as writer:
                # Sheet 1: Summary
                df1.to_excel(writer, sheet_name='Reconciliation', index=False)
                # Sheet 2: Transactions
                df2.to_excel(writer, sheet_name='Transactions', index=False)
            output.seek(0)
            return output.getvalue()

        excel_data = to_excel(df_final, df_tx)

        st.download_button(
            label="📥 Tải Excel kết quả đối soát",
            data=excel_data,
            file_name="reconciliation_result.xlsx",
            mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        )

        st.divider()
        st.success("🎉 Đối soát hoàn tất! Kiểm tra kết quả ở trên.")

    except Exception as e:
        st.error(f"❌ Lỗi xử lý: {str(e)}")
        logger.exception(f"Processing error: {e}")

else:
    st.info("👈 Vui lòng upload 2 file Excel để bắt đầu.")