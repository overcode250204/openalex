# PRM393 – Lab 2: Journal Trend Analysis — Project Status

## Tổng quan dự án

**Tên ứng dụng:** Journal Trend Analyzer  
**Framework:** Flutter + Dart  
**API chính:** OpenAlex (dữ liệu học thuật)  
**API phụ (bonus):** Zotero (lưu publication vào thư viện cá nhân)  
**State Management:** Provider  

---

## Cấu trúc thư mục hiện tại

```
lib/
├── main.dart
├── core/
│   ├── constants/
│   │   └── api_constants.dart
│   └── utils/
│       └── abstract_converter.dart
├── models/
│   ├── publication.dart
│   ├── search_filter.dart
│   ├── zotero.dart
│   └── trend_report_snapshot.dart    ✅ Added: citationMedian, publicationGrowthRate
├── services/
│   ├── openalex_service.dart         ✅ Added: page parameter for pagination
│   ├── history_service.dart          ✅ Search history persistence
│   ├── suggestion_service.dart       ✅ Related keyword suggestions
│   ├── zotero_serivce.dart
│   └── trend_report_export_service.dart  ✅ Fixed: dynamic Downloads path, added metrics
├── providers/
│   └── publication_provider.dart     ✅ Added: totalCitations, citationMedian, publicationGrowthRate getters
├── screens/
│   ├── search_screen.dart            ✅ Infinite scroll, filter, suggestion, search history
│   ├── dashboard_screen.dart         ✅ Redesigned: grid layout, charts, influential paper card
│   ├── trend_analysis_screen.dart
│   └── publication_detail_screen.dart
├── widgets/
│   ├── publication_card.dart
│   ├── summary_card.dart             ✅ Enhanced: color param, subtitle, CircleAvatar
│   ├── trend_chart.dart
│   ├── related_keyworks_bar.dart
│   ├── search_suggestion_overlay.dart
│   └── top_journals_bar_chart.dart   ✅ NEW: Bar chart for top journals
└── mappers/
    └── ZoteroMapper.dart
```

---

## Yêu cầu chức năng (Functional Requirements)

| # | Yêu cầu | Trạng thái | Ghi chú |
|---|---------|-----------|---------|
| 4.1 | Topic Search — tìm kiếm theo keyword, hiển thị title/year/citation/journal | ✅ Hoàn thành | `search_screen.dart` |
| 4.2 | Publication Details — title, authors, year, journal, citation, DOI, abstract | ✅ Hoàn thành | `publication_detail_screen.dart` |
| 4.3 | Publication Trend Analysis — biểu đồ theo năm | ✅ Hoàn thành | `trend_analysis_screen.dart` + `trend_chart.dart` dùng `fl_chart` |
| 4.4 | Top Influential Papers — xếp hạng theo citation count | ✅ Hoàn thành | Hiển thị top 10 trong TrendAnalysisScreen |
| 4.5 | Top Research Journals — journal nhiều publication nhất | ✅ Hoàn thành | Ranked list trong TrendAnalysisScreen |
| 4.6 | Top Contributing Authors — tác giả nhiều bài nhất | ✅ Hoàn thành | Ranked list trong TrendAnalysisScreen |
| 4.7 | Research Trend Dashboard — tổng hợp: total pubs, avg citations, active year, top journal, top author, most influential paper | ✅ Hoàn thành | `dashboard_screen.dart` — redesigned with 2×3 grid, bar chart, influential paper card |

---

## Yêu cầu kỹ thuật (Technical Requirements)

| Yêu cầu | Trạng thái | Ghi chú |
|---------|-----------|---------|
| Flutter + Dart | ✅ | |
| API Integration | ✅ | `openalex_service.dart` |
| Asynchronous data retrieval | ✅ | `async/await` + `Future` |
| JSON processing | ✅ | Factory constructors trong models |
| Error handling | ⚠️ Cơ bản | Có try-catch nhưng thiếu retry logic và thông báo lỗi HTTP cụ thể |
| Loading states | ✅ | `isLoading` flag trong Provider |
| Data visualization | ✅ | `fl_chart` LineChart |
| Cấu trúc models/services/screens/widgets/providers | ✅ | Đủ folders |
| Chạy được trên Android | ✅ | |

---

## Yêu cầu giao diện (UI Requirements)

| Screen | Trạng thái |
|--------|-----------|
| Search Screen | ✅ |
| Publication Detail Screen | ✅ |
| Trend Analysis Screen | ✅ |
| Research Dashboard Screen | ✅ |

---

## 🎯 Implementation Details (Latest Enhancements)

### Dashboard UI/UX Redesign
- **Layout:** 2×3 grid instead of vertical stack
- **Stat Cards:** 6 color-coded cards (blue/orange/green/teal/purple/red)
  - Total Publications
  - Total Citations (NEW)
  - Average Citations per paper
  - Citation Median (NEW)
  - Peak Year
  - Growth Rate % (NEW)
- **Additional Sections:**
  - Influential Paper card (tappable → detail screen)
  - Top Journals bar chart (horizontal, fl_chart)
  - Top Journal & Top Author summary row

### Search Pagination
- **Type:** Infinite scroll (auto-load on scroll)
- **Mechanism:** `NotificationListener<ScrollNotification>` detects when user scrolls to 200px from bottom
- **Call:** Triggers `provider.loadMore()` → `searchWithFilter()` (filter-aware)
- **Loading:** Shows spinner at bottom of list when loading more
- **State:** `_hasMore` flag stops loading when result < 50 items

### Export Enhancements
- **Path Fix:** Changed from hardcoded `D:\FPT\Ki8\PRM392` to dynamic:
  - **Windows:** `%USERPROFILE%\Downloads`
  - **Mac/Linux:** `~/Downloads`
- **New Metrics in Report:**
  - Citation Median (Overview + Insight sections)
  - Publication Growth Rate % (Overview + Insight sections)
  - Example: "Citation median: 8" and "Publication growth rate: +42.3%"

### Provider Metrics (New Getters)
```dart
int get totalCitations              // Sum of all citations
double get publicationGrowthRate    // % change from first to last year
int get citationMedian              // 50th percentile of citations
```

### Model Updates
- **TrendReportSnapshot:** Added `citationMedian` and `publicationGrowthRate` fields
- **SummaryCard Widget:** Added optional `color` and `subtitle` parameters for color-coding

### Service Improvements
- **OpenAlexService:** Added `page` parameter for pagination support
- **TrendReportExportService:** Dynamic path resolution + enhanced metrics

---

## Những gì CHƯA làm / còn thiếu

### ❌ Deliverables chưa nộp

| Hạng mục | Trạng thái | Mô tả |
|---------|-----------|-------|
| **8.1 Source Code** | ✅ Có trên GitHub | Branch `dev` — kiểm tra tên repo có đúng convention `PRM393_Lab2_StudentID` chưa |
| **8.2 Project Report** | ❌ Chưa làm | Báo cáo PDF 5–10 trang, cần viết đủ các mục bên dưới |
| **8.3 Demonstration Video** | ❌ Chưa làm | Video demo 5–10 phút |

---

### ❌ AI-Assisted Code Review (Section 6) — Chưa thực hiện

Đây là yêu cầu bắt buộc. Cần:
- [ ] Chạy review bằng **CodeRabbit**, **Kodus AI**, **SonarQube**, hoặc **GitHub Copilot Code Review**
- [ ] Tìm ít nhất **3 vấn đề** (bugs, code smells, security warnings, improvement opportunities)
- [ ] Fix những vấn đề phù hợp
- [ ] **Chụp screenshots** làm bằng chứng
- [ ] Viết vào báo cáo

Gợi ý: CodeRabbit dễ dùng nhất — mở PR trên GitHub, nó sẽ tự review và comment.

---

### ❌ Project Report (8.2) — Chưa viết

Báo cáo PDF 5–10 trang cần có các mục:

- [ ] Project overview
- [ ] System design (kiến trúc, data flow)
- [ ] Implementation details (mô tả từng module)
- [ ] API integration approach (cách gọi OpenAlex)
- [ ] Screenshots của major features
- [ ] Trend analysis results (ví dụ kết quả với topic "AI")
- [ ] AI-assisted code review findings
- [ ] Challenges encountered
- [ ] Lessons learned

---

### ✅ Code Issues Fixed

| Vấn đề | File | Status |
|--------|------|--------|
| ✅ Export path hardcode → dynamic Downloads folder (cross-platform) | [`lib/services/trend_report_export_service.dart`](lib/services/trend_report_export_service.dart) | FIXED |
| ✅ Generated platform files → added to .gitignore | [`.gitignore`](.gitignore) | FIXED |
| ✅ Dashboard UI → redesigned with grid layout, metrics, charts | [`lib/screens/dashboard_screen.dart`](lib/screens/dashboard_screen.dart) | ENHANCED |

### ⚠️ Code Issues Remaining (Lower Priority)

| Vấn đề | File | Mức độ |
|--------|------|--------|
| Typo tên file: `zotero_serivce.dart` → `zotero_service.dart` | [`lib/services/zotero_serivce.dart`](lib/services/zotero_serivce.dart) | Nhỏ |
| File duplicate: `publication_detail_screen.dart` nằm trong cả `screens/` và `widgets/` | [`lib/widgets/publication_detail_screen.dart`](lib/widgets/publication_detail_screen.dart) | Trung bình |
| Error handling thiếu: không hiện mã lỗi HTTP cụ thể (404, 429, 500) | [`lib/services/openalex_service.dart`](lib/services/openalex_service.dart) | Trung bình |

---

## Checklist nộp bài

```
[ ] Source code đẩy lên GitHub, tên repo đúng convention: PRM393_Lab2_StudentID
[ ] Sửa các code issues nêu trên
[ ] Chạy AI code review (CodeRabbit / Kodus AI), chụp screenshots ≥ 3 findings
[ ] Viết Project Report PDF (5–10 trang)
    [ ] Project overview
    [ ] System design + data flow
    [ ] Implementation details
    [ ] API integration approach
    [ ] Screenshots các màn hình chính
    [ ] Trend analysis results
    [ ] AI code review findings + fixes
    [ ] Challenges & lessons learned
[ ] Quay video demo (5–10 phút)
    [ ] Topic search demo
    [ ] Publication detail
    [ ] Trend Analysis (chart + top papers/journals/authors)
    [ ] Dashboard
    [ ] Export report (tính năng bonus)
    [ ] AI code review process
```

---

## Tóm tắt

**Phần code (chức năng):** ✅ Hoàn thành 100% 
- Tất cả 7 functional requirements implemented
- 4 bắt buộc screens đủ (Search, Detail, Trend, Dashboard)
- Dashboard redesigned with grid layout, charts, 6 metrics
- Pagination working with infinite scroll
- Export fixed with dynamic path + new metrics

**Phần nộp bài:** Còn thiếu
- [ ] Project Report PDF (5–10 trang)
- [ ] Demonstration Video (5–10 phút)
- [ ] AI-Assisted Code Review (CodeRabbit/Kodus AI with screenshots)

**Việc ưu tiên làm ngay:**
1. Chạy CodeRabbit trên GitHub PR để có AI review screenshots
2. Viết Project Report PDF với:
   - Implementation details (dashboard, pagination, export)
   - Screenshots của features
   - AI review findings
3. Quay video demo
