---
name: loop-design-check
description: "Thiết kế một agent loop hướng mục tiêu hoặc review một loop để tìm các kiểu hỏng: quay vòng vô ích (spinning), lách verifier theo Goodhart, hoặc chạy một đáp án sai đến cùng. Bao gồm mục tiêu máy có thể phán định, các loại loop, khung plan/build/judge và cách phòng ngừa loop chạy mất kiểm soát; phần nối cơ chế nằm ở autonomous-loops. Dùng khi thiết kế, viết hoặc kiểm tra một agent loop. 中文触发：写 loop、设计 loop、做一个 loop、检查 loop 对不对、loop 体检、loop 会不会跑飞、可判定目标、五个崩法、plan build judge。"
metadata:
  origin: ECC
---

# Thiết kế + Review Loop

> **Tiền đề.** LLM là một hệ thống feed-forward: prompt vào → token ra, không có sẵn cơ chế "lái về phía mục tiêu" xuyên suốt các lượt. Để nó *hành xử* như một hệ thống hướng mục tiêu, bạn bọc quanh nó một vòng phản hồi (feedback loop). Skill này giúp bạn **viết** loop đó cho đúng và **review** nó để nó không chạy mất kiểm soát.

## Khi nào dùng / không dùng

**Dùng khi:**
- Bạn muốn giao một tác vụ lặp lại cho agent chạy đi chạy lại (viết→test, test→fix, fix→verify…).
- Bạn đã có một loop và lo nó quay vòng vô ích, gian lận, hoặc chạy một đáp án sai đến cùng.

**Không dùng cho:**
- Tác vụ làm một lần → cứ làm luôn; đừng bọc loop quanh nó.
- Timer / poll đơn thuần → dùng `/loop`; không cần thiết kế.
- *Cách nối kiến trúc loop* (pipeline → DAG, khôi phục khi chạy dài) → đó là tầng cơ chế; xem `autonomous-loops` / `continuous-agent-loop`. **Skill này chỉ bàn "mục tiêu đã đúng chưa, và nó có chạy mất kiểm soát không" — không giải thích lại cơ chế.**

## Tiền đề lằn ranh đỏ: hai tầng phản hồi

| Tầng | Ai sở hữu | Làm gì |
|---|---|---|
| **Thực thi** (thấp) | máy / agent | Đo "còn cách mục tiêu theo nghĩa đen bao xa" và mài cho về 0. Máy mạnh ở đây. |
| **Phán đoán** (cao) | **con người** | Quyết định "bản thân mục tiêu này có đúng không, có nên đổi không, có nên dừng không." Máy không thể bước ra khỏi vòng của chính nó để đặt câu hỏi về mục tiêu. |

> Một bộ điều nhiệt có thể phản hồi "còn cách 26°C bao xa", nhưng khi bạn bị sốt và muốn 28°C thì nó không thể phán đoán 26 có phải mục tiêu *đúng* hay không — nó chỉ cứ mài về 26. **"Hôm nay đặt bao nhiêu" luôn là quyết định của con người.**
> Giao việc phán đoán / ký duyệt / công tắc cuối cùng cho máy = gỡ bỏ phản hồi tầng cao = nó lao nhanh và mạnh về một mục tiêu không ai đặt câu hỏi → đầu ra sai.

---

## Hành động 1 — Viết một loop (5 bước)

### Bước 0 · Trừ bớt trước: có nên xây nó không? (cổng 4 điều kiện, thiếu bất kỳ điều nào = phủ quyết)

① tác vụ lặp lại hàng tuần hoặc thường xuyên hơn　② verification có thể tự động hóa　③ ngân sách token chịu được　④ agent có tool thực sự *chạy và thấy kết quả*

Thiếu bất kỳ điều nào → **đừng xây loop**; hãy làm thủ công hoặc cách khác.
> Thứ chặn hầu hết mọi người không phải "tôi có viết được loop không", mà là "repo của tôi có xứng đáng có một loop không". Một repo xứng đáng có loop thì có baseline đối soát (golden sample / tổng nguồn upstream) + test + lint guard. **Một repo không xứng đáng có loop thì loop chỉ khuếch đại lỗi của nó.**

### Bước 1 · Định nghĩa một mục tiêu *máy có thể phán định* (phần khó — loop sống hay chết ở đây)

Cả loop dựa vào câu hỏi "xong chưa?" của bộ so sánh (comparator). **Comparator chỉ hoạt động được nếu điều kiện thoát của bạn có thể được máy phán định có/không.**

- Tệ: Mơ hồ ("làm cho tốt", "viết sắc hơn") → comparator không phán định được → hoặc không bao giờ pass (kẹt ở retry) hoặc đoán mò (pass/block ngẫu nhiên).
- Tốt: Phán định được ("toàn bộ 96 unit test xanh VÀ có sinh ra danh sách thay đổi", "các trường của module-02 đã điền, pytest pass, business logic không bị đụng tới") → một lần kiểm tra là chốt; loop hội tụ gọn gàng.

**Khung mục tiêu năm điểm:**
1. **Tiêu chí hoàn thành có thể được máy verify.**
2. **Điều kiện biên được định nghĩa cùng với tiêu chí hoàn thành** ("nó KHÔNG ĐƯỢC làm gì") — chống Goodhart; thiếu biên = giấy phép để gian lận.
3. **Có phương án dự phòng khi thất bại** — giới hạn retry N + chuyển cho con người khi vượt quá.
4. **Mục tiêu được phân tầng.**
5. **Ưu tiên đối soát hơn khẳng định cho tiêu chí hoàn thành** — neo vào sự thật bên ngoài (golden sample / tổng nguồn upstream / đối chiếu tài chính / số liệu back-office của nền tảng) trước các khẳng định của chính bạn. "Mọi test đều pass" có thể bị lách (nới assert, mock giả, nuốt exception); "chênh lệch so với bản tham chiếu < 0.01" thì không.

> **Tự kiểm tra:** đọc mục tiêu cho một người không biết lĩnh vực đó — họ có chạy được một lệnh và biết đã xong hay chưa không? Nếu không, nó chưa đủ khả năng phán định. Quay lại.

### Bước 2 · Chọn loại loop

| Tác vụ của bạn | Loại loop (điều khiển học) | Cách dừng |
|---|---|---|
| Có phép thử "xong" rõ ràng (viết cho xong / xử lý xong một loạt ảnh) | **servo** (vòng kín kiểu `/goal`) | dừng khi đạt mục tiêu |
| Không có điểm kết thúc, phải liên tục duy trì một trạng thái (cảnh báo tồn kho / health check theo lịch) | **regulator** (bộ điều nhiệt kiểu `/loop`) | không bao giờ dừng; chỉ hành động khi có thay đổi (dead-band loại bỏ nhiễu) |
| Lấy mẫu định kỳ, dừng theo điều kiện (theo dõi một PR đến khi CI xanh) | **regulator có lối thoát** | dừng khi điều kiện thoát thỏa |
| Phải "đảm bảo việc gì đó xảy ra đúng giờ" | bọc các loại trên trong `/schedule` | cron kích hoạt |

> Quy tắc ngón tay cái: có phép thử "xong" rõ ràng → servo; phải liên tục duy trì, không có điểm kết thúc → regulator; phải "xảy ra đúng giờ" → bọc một regulator trong schedule.

### Bước 3 · Chọn một khung (skeleton)

**Loại bảo trì (chăm sóc thứ đã tồn tại) → điều phối dựa trên tài liệu (document-driven dispatch).**
Loop không phải "chạy một lần kiểm tra cố định theo timer", mà là **"đọc một tài liệu theo timer, và chỉ điều phối khi tài liệu thay đổi."** Tài liệu là hàng đợi tác vụ + máy trạng thái + giao diện với con người.
Ba kỷ luật: ① cột vấn đề chỉ con người được ghi, cột kết quả chỉ loop được ghi, **trạng thái chỉ tiến một chiều và không bao giờ lùi lại**; ② **exit code là quyết định cuối** (nếu script nói exit 1 thì script thắng); ③ trạng thái chỉ tiến tới mức "chờ verify" — **ô "xong" chỉ do con người lật.** Loop là người thợ, không phải người nghiệm thu.

**Loại greenfield (xây từ đầu) → plan / build / judge, ba vai trò.**

| Vai trò | Làm gì | Điểm mấu chốt |
|---|---|---|
| **Plan** | chia mục tiêu thành spec + **điều kiện nghiệm thu có thể phán định** | nghiệm thu phải do script phán định được |
| **Build** | viết theo spec | **không được thay đổi điều kiện nghiệm thu** |
| **Judge** | chạy nghiệm thu **một cách độc lập**; pass → dừng, fail → trả về Build kèm lý do thất bại | **độc lập + xác định (deterministic)** |

Ba quy tắc sắt (đều đặt cược vào judge): ① **judge phải độc lập** — không phải cùng agent với Build (tự chấm bài mình luôn bị thổi phồng); ② **quy tắc xác định** — pytest / diff đối soát / kiểm tra type / diff, không bao giờ là "trông có vẻ đúng"; ③ **Build không được sửa điều kiện nghiệm thu để qua mặt**. Thất bại retry ba lần → chuyển cho con người.

### Bước 4 · Thêm giảm chấn (damping) (chống dao động / chạy mất kiểm soát)

Giới hạn retry, dừng cứng, con người lật công tắc cuối = giảm chấn. **Phản hồi âm không có giảm chấn sẽ dao động** (loop kiểu Ralph-Wiggum: quay tại chỗ, đốt token).

### Bước 5 · Triển khai theo ba giai đoạn (đừng tự động hoàn toàn ngay ngày đầu)

① **Chạy thủ công một lần** (buộc bạn phải nói rõ "judge quyết định như thế nào") → ② đóng cứng thành skill / sub-agent của Claude Code (một Claude chính lặp vòng, điều phối plan/build/judge) → ③ treo lên cron để tự động hoàn toàn.

---

## Hành động 2 — Review một loop (checklist = năm kiểu hỏng)

> Cho loop chạy qua từng dòng. **Dính bất kỳ một dòng nào = loop này sẽ hỏng; trả nó về.** Năm điều này là kinh nghiệm tiêu cực (gotcha) — đáng giá hơn các quy tắc tích cực.

| # | Kiểu hỏng (hỏng thế nào) | Câu hỏi review (dính = đỏ) | Kháng thể |
|---|---|---|---|
| 1 | Mục tiêu là một lời sáo rỗng đúng đắn → **quay vòng, đốt tiền** | Điều kiện thoát có được máy phán định có/không không? Hay nó là "quản lý cho tốt / làm cho tốt"? | Thay bằng điều kiện kết quả có thể phán định (Hành động 1·Bước 1) |
| 2 | "Verification" viết thành "kiểm tra xem có ổn không" → **agent tự tin nói ổn rồi dừng** | Judge có phải chính bị cáo không? Verification dựa vào "trông đúng" hay quy tắc xác định? | Đối soát + quy tắc exit code + judge độc lập |
| 3 | (tệ nhất) Chỉ chặn bằng "mọi test pass" → **agent xóa test** | Có điều kiện biên ("không được làm gì") không? Hay chỉ có tiêu chí hoàn thành? | Tiêu chí hoàn thành **+ điều kiện biên** cùng nhau (kháng thể Goodhart) |
| 4 | Trông chờ agent hỏi giữa chừng → **nó sẽ không; nó chạy đáp án sai đến cuối** | Có điểm nào "chỉ làm rõ khi đang chạy" không? | **Dồn mọi việc làm rõ lên trước**; chốt một lần trước khi khởi chạy |
| 5 | CLAUDE.md phình to + memory lỗi thời → **loop càng nhanh, sai càng nhiều** | Tài liệu/memory mà nó phụ thuộc có còn mới không? Ai bảo trì? | Memory phân tầng + lint định kỳ |

**Cộng thêm ba lằn ranh đỏ (vi phạm bất kỳ điều nào = không được phép chạy tự động):**
- **Giữ phán đoán cho con người.** Nghiệm thu / ô "xong" do con người lật; loop không phải người nghiệm thu.
- **Trách nhiệm không chuyển giao được.** Bất cứ thứ gì mà bạn không gánh nổi nếu hỏng (merge nhầm PR / publish nhầm thứ / phân bổ sai tiền) → **đừng tự động giao quyền đó.**
- **Cảnh báo phản trực giác.** Một loop càng "tự cải tiến / tự viết lại quy tắc của chính nó" thì càng cần **con người review nghiêm ngặt hơn** (để xem nó đã viết lại quy tắc thành cái gì) — chứ không phải lỏng hơn. Máy quá nhanh để chặn sau sự việc, nên phán đoán của con người phải nằm **trước hành động** (cổng cứng), không phải bản vá sau đó.

---

## Ví dụ thực tế — review một loop "nightly green-keeper"

Bạn muốn một loop chạy mỗi đêm và sửa bất cứ test nào đang fail.

- **Mục tiêu ngây thơ:** "làm cho mọi test pass." → Tự kiểm tra ở Bước 1 thất bại: đây là mồi nhử cho kiểu hỏng #3.
- **Mục tiêu phán định được (đã sửa):** "mọi test xanh **VÀ** không có file test nào bị xóa hoặc làm yếu đi **VÀ** coverage không giảm **VÀ** có sinh ra danh sách thay đổi." Điều kiện biên giờ đã được định nghĩa cùng với tiêu chí hoàn thành.
- **Loại:** servo với giới hạn retry 3 (Bước 2 + Bước 4).
- **Khung:** plan/build/judge — **judge là CI chạy độc lập**, không bao giờ là agent đang sửa (Bước 3).

Giờ chạy **checklist review**, và nó bắt được những gì phiên bản ngây thơ bỏ sót:
- **Dính #3** → "mọi test pass" ngây thơ cho phép agent xóa một test đang fail để "thắng." Sửa bằng điều kiện biên "không xóa/làm yếu file test."
- **Dính #2** → nếu agent sửa cũng tự judge bản sửa của mình, nó sẽ tự cho mình qua. Sửa bằng "judge = CI độc lập, xác định."
- **Dính #4** → nếu một bản sửa mơ hồ, agent sẽ không dừng lại hỏi lúc 2 giờ sáng; nó sẽ commit một phỏng đoán. Sửa bằng cách dồn lên trước: các bản sửa mơ hồ để lại cho con người, không đoán.
- **Lằn ranh đỏ** → loop mở PR nhưng **không tự động merge**; con người lật công tắc cuối (trách nhiệm không chuyển giao).

Loop ngây thơ và loop đã được review khác nhau bốn dòng ràng buộc — và đó là khác biệt giữa "thức dậy thấy bộ test bị xóa" và "thức dậy thấy một PR sạch."

---

## Kết một dòng

> Phần khó của việc viết loop không phải "tôi có viết được loop không", mà là **định nghĩa một mục tiêu mà máy có thể đối soát** — phán định được, có biên, dựa trên đối soát. Bộ điều khiển phải xác định (deterministic) và nằm bên ngoài; giữ phán đoán và tiêu chuẩn cho con người; hệ thống có xu hướng tăng entropy, nên hãy bảo trì nó.
> **Loop chỉ thưởng cho người đã suy nghĩ thấu đáo từ trước. Trông chờ nó nghĩ thay bạn, nó sẽ vui vẻ nghĩ sai, cùng bạn, ở quy mô lớn.**

---

> Nguồn gốc: phản hồi hai tầng của Wiener (*The Human Use of Human Beings*, 1950) cho việc tách phán đoán/thực thi và các lằn ranh đỏ; mẫu plan/build/judge từ *Loops explained* của Anatoli và *Loop Engineering* của Addy.
> Tầng cơ chế (cách nối kiến trúc loop): xem `autonomous-loops` / `continuous-agent-loop`. Skill này không triển khai lại cơ chế; nó chỉ bao gồm việc định nghĩa mục tiêu và phòng ngừa loop chạy mất kiểm soát.
