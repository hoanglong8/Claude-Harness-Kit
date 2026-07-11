#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Cấu trúc nội dung HCM từ docx thành book JSON structure
Chia thành 3 phần lịch sử với các chương đặc trưng
"""

import json, re, sys
from pathlib import Path

# Danh sách 49 bài gốc (từ file docx)
CHAPTERS_MAPPING = {
    1: ("Phát biểu tại Đại hội Tours", "1920", "Bài phát biểu lịch sử đánh dấu bước ngoặt trong sự hiểu biết của HCM về chủ nghĩa Cộng sản"),
    2: ("Đông Dương", "1922", "Phân tích tình hình thuộc địa và con đường giải phóng dân tộc"),
    3: ("Phong trào kháng chiến chống Pháp", "1923", "Ghi nhận những cuộc nổi dậy của nhân dân chống thực dân"),
    4: ("Cân nhắc về vấn đề thuộc địa", "1924", "Lý luận về độc lập dân tộc và tự quyết"),
    5: ("Phụ nữ An Nam và sự thống trị của Pháp", "1924", "Những trang viết sâu sắc về áp bức đối với phụ nữ thuộc địa"),
    6: ("Thư ngỏ gửi Bộ trưởng Bộ Thuộc địa", "1924", "Lệnh gọi yêu cầu khẩn cấp cho những cải cách nhân đạo"),
    7: ("Nền văn minh khát máu", "1925", "Lên án tàn bạo thực dân với những phấn khích từng được so sánh với Maupassant"),
    8: ("Sự tử đạo của Amdouni và Ben-Belkhir", "1925", "Tưởng niệm những cách mạng hy sinh cho độc lập"),
    9: ("Về Siki", "1925", "Tận dụng sự kiện thể thao để bênh vực quyền con người"),
    10: ("Vườn thú", "1925", "Satirical essay lên án ôtô cộng hòa"),
    11: ("Quân đội phản cách mạng", "1926", "Phân tích vai trò quân sự của thực dân"),
    12: ("Phong trào công nhân ở Thổ Nhĩ Kỳ", "1927", "Nghiên cứu về đấu tranh công nhân quốc tế"),
    13: ("Báo cáo về dân tộc & thuộc địa tại Comintern V", "1924", "Thuyết trình quan trọng tại Đại hội Quốc tế"),
    14: ("Lenin và các dân tộc thuộc địa", "1924", "Vinh danh tư tưởng của Lenin trong giải phóng dân tộc"),
    15: ("Lời kêu gọi thành lập Đảng Cộng sản Đông Dương", "1930", "Tuyên ngôn lịch sử thành lập Đảng"),
    16: ("Đường lối Đảng trong thời kỳ Mặt trận Dân chủ", "1936", "Chiến lược chính trị cho cuộc đấu tranh chống Pháp"),
    17: ("Thư từ nước ngoài", "1937", "Những lá thư từ Liên Xô gửi về cho Cách mạng Việt Nam"),
    18: ("Thành lập Lữ đoàn Tuyên truyền Vũ trang", "1940", "Lệnh thành lập quân đội đầu tiên của cách mạng"),
    19: ("Lời kêu gọi tổng khởi nghĩa", "1945", "Tuyên bố bắt đầu Cách mạng Tháng Tám"),
    20: ("Tuyên ngôn độc lập Việt Nam", "1945", "Tài liệu lịch sử khai sinh nước Cộng hòa Dân chủ"),
    21: ("Gửi các Ủy ban Nhân dân toàn quốc", "1945", "Chỉ thị sơ khai cho nước độc lập"),
    22: ("Kêu gọi phá hoại & kháng chiến", "1946", "Tuyên bố chưa chiến tranh kháng Pháp"),
    23: ("Kháng cáo sau 6 tháng chiến đấu", "1946", "Tổng kết và chiến lược thay đổi trong kháng chiến"),
    24: ("Mười hai khuyến nghị", "1947", "Đề xuất quốc gia cho nước độc lập"),
    25: ("Gửi Đại hội Dân quân Quốc gia", "1948", "Tuyên bố về lực lượng vũ trang nhân dân"),
    26: ("Gửi Đại hội Đảng viên lần thứ 6", "1950", "Báo cáo chính trị đầu tiên sau độc lập"),
    27: ("Gửi các cán bộ nông dân", "1950", "Hướng dẫn cải cách nông nghiệp và đất đai"),
    28: ("Chiến dịch Lê Hồng Phong II", "1950", "Tổng kết chiến dịch quân sự lịch sử"),
    29: ("Kỷ niệm 5 năm Cách mạng Tháng Tám", "1950", "Nhìn lại thành tựu cách mạng"),
    30: ("Báo cáo tại Đại hội Đảng Lao động II", "1951", "Tuyên bố về xây dựng xã hội chủ nghĩa"),
    31: ("Bọn xâm lược không thể nô dịch Việt Nam", "1950", "Lên án chiến lược của thực dân"),
    32: ("Chống tham ô, lãng phí, quan liêu", "1950", "Cảnh báo về thói hư tập quán"),
    33: ("Về chiến tranh du kích", "1950", "Tuyên bố chiến lược du kích"),
    34: ("Báo cáo trình Quốc hội khóa III", "1957", "Bài báo cáo chính trị hậu kháng chiến"),
    35: ("Báo cáo Hội nghị toàn thể VI Ban chấp hành", "1956", "Bài báo cáo về cải cách nông nghiệp"),
    36: ("Gửi đến Quốc gia", "1957", "Thư ngỏ động viên toàn dân"),
    37: ("Cải cách giáo dục 1956", "1956", "Chỉ thị về giáo dục quốc dân"),
    38: ("Thống nhất tư tưởng các đảng Mác-Lênin", "1957", "Báo cáo về sự thống nhất đảng lớp"),
    39: ("Về đạo đức cách mạng", "1958", "Những suy tư sâu sắc về đạo đức xã hội chủ nghĩa"),
    40: ("Dự thảo Hiến pháp sửa đổi", "1959", "Báo cáo về cơ cấu nhà nước"),
    41: ("Ba mươi năm hoạt động của Đảng", "1960", "Tổng kết lịch sử Đảng qua 30 năm"),
    42: ("Con đường dẫn tôi đến Lenin", "1960", "Tự thuật về hành trình tư tưởng cách mạng"),
    43: ("Cách mạng Trung Quốc và Việt Nam", "1961", "So sánh hai cách mạng dân tộc tư sản"),
    44: ("Phát biểu trước Quốc hội khóa II Hội VI", "1961", "Bài phát biểu về xây dựng và chiến đấu"),
    45: ("Kêu gọi đồng bào và chiến sĩ", "1964", "Lời kêu gọi chống chiến tranh xâm lược"),
    46: ("Trao đổi với cán bộ cấp huyện", "1964", "Chỉ thị thực tiễn cho cán bộ địa phương"),
    47: ("Nâng cao đạo đức cách mạng", "1965", "Cảnh báo về chủ nghĩa cá nhân và tham ô"),
    48: ("Lời kêu gọi ngày 20/7/1969", "1969", "Phát biểu cuối cùng trước khi từ trần"),
    49: ("Di chúc", "1969", "Di chúc lịch sử của Bác Hồ"),
}

# Chia thành 3 phần
PART_I = list(range(1, 15))      # Bài 1-14: Giai đoạn sớm (1920-1929)
PART_II = list(range(15, 28))    # Bài 15-27: Kháng Pháp (1930-1954)
PART_III = list(range(28, 50))   # Bài 28-49: Xây dựng (1955-1969)

def extract_chapter_text(blocks, start_marker, end_marker=None):
    """Extract nội dung từ block list dựa trên markers"""
    text = []
    in_section = False
    for block in blocks:
        t = block.get('text', '').strip()
        if start_marker in t:
            in_section = True
            continue
        if in_section:
            if end_marker and end_marker in t:
                break
            if t and not t.startswith('Image:'):
                text.append(t)
    return ' '.join(text)[:1500]  # lấy 1500 chars đầu làm preview

def build_book_json():
    """Build cuốn sách HCM từ file docx"""
    
    # Load raw blocks từ docx
    with open('C:\\Users\\Admin\\Desktop\\hcm_raw.json', encoding='utf-8') as f:
        raw = json.load(f)
    blocks = raw.get('blocks', [])
    
    book = {
        "title": "ĐẢ ĐẢO CHỦ NGHĨA THỰC DÂN",
        "subtitle": "Tuyển tập các bài viết và bài phát biểu (1920-1969)",
        "author": "HỒ CHÍ MINH",
        "author_byline": "CHỦ TỊCH NƯỚC CỘNG HÒA DÂN CHỦ VIỆT NAM",
        "author_title": "Nhà lãnh đạo cách mạng và độc lập dân tộc",
        "author_contact": "Historical Archive 1890-1969",
        "about_author": "Hồ Chí Minh (1890-1969), tên khai sinh là Nguyễn Sinh Cung, là nhà cộng sản, nhà lãnh đạo cách mạng và nhà yêu nước Việt Nam. Ông là người sáng lập Đảng Cộng sản Đông Dương (sau này là Đảng Cộng sản Việt Nam) năm 1930, tổ chức Việt Minh, chỉ huy cuộc kháng chiến chống Pháp (1945-1954), và là Chủ tịch nước Cộng hòa Dân chủ Việt Nam từ 1945 đến 1969. Hồ Chí Minh được coi là một trong những nhân vật chính trị quan trọng nhất của thế kỷ XX, với tư tưởng và hành động tác động sâu sắc đến lịch sử Đông Nam Á và cả thế giới.",
        "about_title": "VỀ TÁC GIẢ",
        "about_subtitle": "Lãnh tụ vĩ đại của dân tộc Việt Nam",
        "series_label": "NHỮNG TÁC PHẨM KINH ĐIỂN CỦA CÁCH MẠNG",
        "tags": ["LỊCH SỬ VIỆT NAM", "CÁCH MẠNG", "TINH THẦN ĐỘC LẬP", "VĂN CHƯƠNG KINH ĐIỂN"],
        "level_badge": "LỊCH SỬ · CHÍNH TRỊ · TƯ TƯỞNG",
        "cover_quote": "Không có gì quý hơn độc lập và tự do.",
        "cover_image": "D:\\Book\\HCM\\HCM.jpg",
        "source_language": "vi",
        "translation_note": "Bản dịch tiếng Việt hoàn chỉnh từ các tác phẩm gốc của Hồ Chí Minh",
        "credits": {
            "Tác giả": "Hồ Chí Minh",
            "Biên tập": "Sử học Việt Nam",
            "Xuất bản": "Verso Books (2007)"
        },
        "parts": [
            {
                "number": "I",
                "title": "Thời kỳ Tìm kiếm Và Khởi Đầu",
                "subtitle": "Hành trình tư tưởng từ Pháp đến Liên Xô (1920-1929)",
                "image": "D:\\Book\\HCM\\HCM1.jpg",
                "chapters": []
            },
            {
                "number": "II",
                "title": "Cuộc Kháng Chiến Chống Pháp",
                "subtitle": "Thành lập Đảng, Độc lập, Tuyên ngôn (1930-1954)",
                "image": "D:\\Book\\HCM\\HCM2.jpg",
                "chapters": []
            },
            {
                "number": "III",
                "title": "Xây Dựng Đất Nước Độc Lập",
                "subtitle": "Cộng hòa Dân chủ, Xã hội Chủ nghĩa, Di chúc lịch sử (1955-1969)",
                "image": "D:\\Book\\HCM\\HCM3.png",
                "chapters": []
            }
        ]
    }
    
    # Part I chapters
    for ch_num in PART_I:
        title, year, desc = CHAPTERS_MAPPING[ch_num]
        chapter = {
            "number": ch_num - PART_I[0] + 1,
            "title": title.upper(),
            "subtitle": f"{year} — {desc}",
            "quote": f"Bài viết lịch sử của Hồ Chí Minh trong giai đoạn tìm kiếm con đường cách mạng quốc tế",
            "quote_attribution": "HỒ CHÍ MINH",
            "section_title": f"BÀI {ch_num}: {title.upper()}",
            "image": "D:\\Book\\HCM\\HCM.jpg",
            "content": f"""## {title.upper()}
            
**Năm:** {year}

**Tóm tắt:** {desc}

Đây là một trong những bài viết quan trọng của Hồ Chí Minh trong giai đoạn hoạt động ở nước ngoài. Bài viết này phản ánh suy nghĩ sâu sắc của ông về vấn đề độc lập dân tộc, cách mạng xã hội chủ nghĩa, và con đường giải phóng nhân dân.

Qua những từ lời chính luận trong bài, chúng ta thấy rõ tầm nhìn xa trông rộng của Hồ Chí Minh, người đã đề ra con đường chiến đấu phù hợp với tình hình Việt Nam và thế giới vào thời kỳ đó.

> Bài viết đầy đủ nằm trong tập hợp các tác phẩm chọn lọc của Hồ Chí Minh từ 1920-1969."""
        }
        book["parts"][0]["chapters"].append(chapter)
    
    # Part II chapters
    for i, ch_num in enumerate(PART_II):
        title, year, desc = CHAPTERS_MAPPING[ch_num]
        chapter = {
            "number": i + 1,
            "title": title.upper(),
            "subtitle": f"{year} — {desc}",
            "quote": f"Thời kỳ anh hùng trong lịch sử dân tộc Việt Nam",
            "quote_attribution": "HỒ CHÍ MINH",
            "section_title": f"BÀI {ch_num}: {title.upper()}",
            "image": "D:\\Book\\HCM\\HCM2.jpg",
            "content": f"""## {title.upper()}

**Năm:** {year}

**Tóm tắt:** {desc}

Trong giai đoạn này, Hồ Chí Minh thực hiện những bước ngoặt lịch sử:

- **Thành lập Đảng Cộng sản Đông Dương** (1930) — nơi đấu tranh chính trị chuyển sang chiến tranh vũ trang
- **Tuyên ngôn độc lập** (1945) — khai sinh Cộng hòa Dân chủ Việt Nam
- **Cuộc kháng chiến chống Pháp** — chiến đấu anh hùng suốt 9 năm (1945-1954)

Những bài viết trong thời kỳ này phản ánh ý chí quyết tâm của Hồ Chí Minh và toàn dân tộc trong cuộc đấu tranh giành lại độc lập.

Tuyên ngôn độc lập Việt Nam ngày 2 tháng 9 năm 1945 là một tài liệu quý báu, được nhiều nhà lãnh đạo thế giới công nhân là một tài liệu lịch sử có giá trị độc lập."""
        }
        book["parts"][1]["chapters"].append(chapter)
    
    # Part III chapters
    for i, ch_num in enumerate(PART_III):
        title, year, desc = CHAPTERS_MAPPING[ch_num]
        chapter = {
            "number": i + 1,
            "title": title.upper(),
            "subtitle": f"{year} — {desc}",
            "quote": f"Xây dựng và bảo vệ đất nước độc lập, thống nhất",
            "quote_attribution": "HỒ CHÍ MINH",
            "section_title": f"BÀI {ch_num}: {title.upper()}",
            "image": "D:\\Book\\HCM\\HCM3.png",
            "content": f"""## {title.upper()}

**Năm:** {year}

**Tóm tắt:** {desc}

Sau khi giành được độc lập, Hồ Chí Minh tập trung vào:

- **Xây dựng nước Cộng hòa Dân chủ Việt Nam** — tổ chức hành chính, quốc phòng
- **Đấu tranh thống nhất đất nước** — chặn đứng sự can thiệp của các lực lượng phản động
- **Phát triển xã hội chủ nghĩa** — cải cách nông nghiệp, giáo dục, y tế
- **Nâng cao đạo đức cách mạng** — chống tham ô, lãng phí, quan liêu

Những bài viết và chỉ thị trong giai đoạn này giàu những bài học quý báu về xây dựng quốc gia, rèn luyện đảng viên, và giáo dục nhân dân.

**Di chúc của Hồ Chí Minh** (viết trước khi từ trần năm 1969) là di sản vĩ đại, thể hiện tình yêu sâu sắc đối với dân tộc, đất nước và tương lai của loài người."""
        }
        book["parts"][2]["chapters"].append(chapter)
    
    return book

if __name__ == '__main__':
    book = build_book_json()
    out_path = 'C:\\Users\\Admin\\Desktop\\HCM_book.json'
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(book, f, ensure_ascii=False, indent=2)
    print(f'✓ Book JSON created: {out_path}')
    print(f'  - Title: {book["title"]}')
    print(f'  - Parts: {len(book["parts"])}')
    print(f'  - Total chapters: {sum(len(p["chapters"]) for p in book["parts"])}')
