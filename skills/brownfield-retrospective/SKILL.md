---
name: brownfield-retrospective
description: Chạy quy trình kỹ thuật của ECC theo hướng hồi tố (retroactively) trên một phần (slice) của dự án đã có. Audit trạng thái hiện tại, dựng lại các quyết định trong quá khứ, tạo gap register bốn trục (tư duy, thực hành coding, tính năng còn thiếu, lựa chọn công nghệ), rồi thực thi các bản sửa tiến về phía trước qua pipeline plan-TDD-review. Dùng khi áp dụng ECC giữa chừng dự án, tiếp quản một codebase thừa kế, hoặc khi hỏi điều gì đã bị bỏ sót và điều gì lẽ ra đã được xây dựng khác đi ngay từ ngày đầu.
metadata:
  origin: ECC
---

# Brownfield Retrospective

Chạy quy trình kỹ thuật của ECC theo hướng hồi tố trên một dự án được xây dựng mà không có nó. Chọn bất kỳ slice nào của codebase hiện có, audit những gì đang tồn tại, dựng lại cách nó đi đến trạng thái đó, rút ra gap register bốn trục, rồi thực thi các bản sửa tiến về phía trước qua pipeline ECC tiêu chuẩn.

Workflow này ưu tiên slice (slice-first): không cần onboard toàn bộ repo trước khi nó trở nên hữu ích, và mọi phase đều có thể được tiếp tục (re-enterable) từ một artifact bền vững trên đĩa. Bắt đầu từ giữa, đi ngược về sau, rồi tiến về phía trước.

## Khi nào kích hoạt

- Áp dụng ECC trong một repository đã tồn tại và đã định hình sẵn
- Người dùng yêu cầu "audit my existing project", "retro this codebase" hoặc "what did we miss?"
- Tiếp quản, thừa kế hoặc quay lại một codebase sau một khoảng thời gian dài
- Người dùng hỏi "why is it like this?" rồi tiếp theo là "should it stay like this?"
- Một module, tính năng hoặc service cần được suy nghĩ lại trước khi tính năng tiếp theo được xây chồng lên nó
- Quyết định xem một khu vực legacy nên được sửa tiến về phía trước (fix forward), viết lại, hay để nguyên và chỉ ghi tài liệu

## Khi nào KHÔNG dùng

- Công việc greenfield chưa có code — hãy dùng trực tiếp `planner` và `tdd-workflow`
- Onboard vào spec-driven development mà không cần vòng lặp thiết kế lại — agent `spec-miner` tự làm việc đó
- Một đợt kiểm tra production-readiness để quyết định go/no-go khi launch — dùng `production-audit`
- Các đợt quét chỉ về bảo mật — dùng `security-review`
- Retrospective về quy trình của team (các nghi thức sprint) — skill này audit một codebase, không phải con người

## Working Set

Mọi artifact được ghi bên trong dự án được audit, dưới `docs/retro/<slice>/`:

| File | Phase | Mục đích |
|------|-------|---------|
| `gap-register.md` | 0-6 | State machine — perimeter, marker `Current phase:` và các dòng. File duy nhất cần để tiếp tục giữa chừng. |
| `baseline-audit.md` | 1 | Các phát hiện của reviewer, snapshot test/CI, danh sách TODO. |
| `reconstructed-spec.md` | 2 | Code thực sự làm gì hiện nay (Requirements + Invariants). |
| `target-design.md` | 4 | Hình dạng đích cho slice và trình tự sửa. |

Các quyết định được backfill sẽ đi vào `docs/adr/` theo skill `architecture-decision-records`. Nếu dự án dùng OpenSpec, `reconstructed-spec.md` có thể thay bằng `openspec/specs/<capability>/spec.md` do `spec-miner` tạo ra.

## Cách hoạt động

### Phase 0 — Chọn điểm bắt đầu

Bắt đầu từ điều người dùng quan tâm hôm nay. KHÔNG map toàn bộ repo trước.

Bất kỳ điều nào sau đây đều là một slice hợp lệ:

| Tín hiệu từ người dùng | Slice |
|-------------|-------|
| Nêu tên một thư mục, module hoặc service | Đường dẫn đó cùng các caller trực tiếp của nó |
| Nêu tên một tính năng hoặc user flow | Các file triển khai nó, được truy vết từ entry point |
| Nêu tên một bug, sự cố hoặc điểm đau | Code đã gây ra nó cộng thêm một cấp call chain |
| Nêu tên một dependency hoặc lựa chọn công nghệ | Mọi thứ chạm tới nó |
| Không nêu gì | 2-3 đường dẫn nóng nhất theo churn — đề xuất chúng và để người dùng chọn |

Ghi perimeter ở đầu `gap-register.md` trước mọi thứ khác: các đường dẫn trong phạm vi, entry point, caller, blast radius. Giới hạn slice ở khoảng 15 file hoặc 2.000 dòng; nếu lựa chọn của người dùng lớn hơn, hãy cắt nó thành các sub-slice có tên và đăng ký mỗi sub-slice thành một dòng công việc riêng. Một slice quá lớn để audit trong một phiên là một slice không bao giờ hoàn thành. Giữ marker `Current phase:` bên cạnh perimeter và cập nhật nó mỗi khi một phase hoàn tất.

### Phase 1 — Audit trạng thái hiện tại

Xác lập những gì đang tồn tại, kèm bằng chứng. CHƯA sửa bất cứ thứ gì.

1. Recon slice: manifest và dấu vân tay framework, entry point, bố cục test, các kiểm tra CI (mượn các bước recon từ `codebase-onboarding`, giới hạn trong perimeter).
2. Chạy các reviewer phù hợp với stack, song song khi có thể. Mỗi phát hiện PHẢI kèm một con trỏ `file:line`:
   - Language reviewer cho stack (`typescript-reviewer`, `python-reviewer`, `go-reviewer`, ...)
   - `security-reviewer`
   - `silent-failure-hunter` cho các lỗi bị nuốt
   - `type-design-analyzer` ở nơi invariant được mã hóa trong type
   - `performance-optimizer` chỉ khi slice nằm trên một đường dẫn nóng (hot path)
3. Chụp snapshot trạng thái hiện tại: số lượng test và coverage, trạng thái lint/CI, danh sách `TODO`/`FIXME`/`HACK` bên trong perimeter.

Ghi mọi thứ vào `baseline-audit.md`. Các phát hiện được sửa ngay trong phase này sẽ làm hỏng baseline — hãy giữ chúng lại cho register.

### Phase 2 — Dựng lại ngược (Backward Reconstruction)

Đi ngược từ trạng thái hiện tại về các quyết định đã tạo ra nó.

1. Khai thác behavioral spec: chạy `spec-miner` trên slice. Các Requirement (WHEN → THEN) và Invariant của nó trở thành `reconstructed-spec.md` — sự thật nền tảng cho các test ở Phase 5.
2. Khảo cổ git (git archaeology) trên perimeter:
   - `git log --oneline -- <slice>` cho lịch sử thư mục; chỉ dùng `--follow` với một đường dẫn file duy nhất — tuổi, tác giả, nhịp độ
   - Các commit lớn nhất và bị revert nhiều nhất — nơi thiết kế đã thay đổi dưới áp lực
   - Các điểm nóng churn — những file thay đổi thường xuyên hơn hẳn các file lân cận
   - Ngõ cụt — các branch hoặc scaffolding chưa bao giờ được ship
3. Danh mục quyết định: liệt kê các quyết định quan trọng đã đóng băng vào code (lựa chọn stack và framework, data model, ranh giới, chiến lược lỗi, quản lý state). Đối chiếu từng quyết định với `docs/adr/`, README và comment. Mỗi quyết định không có bản ghi bằng văn bản tự nó là một khoảng trống tư duy có sẵn từ trước — hãy ghi nó ở Phase 3, KHÔNG âm thầm backfill nó ở đây.
4. Nơi hành vi không rõ ràng, dùng `code-explorer` để truy vết các đường thực thi trước khi đoán ý định.

### Phase 3 — Phân tích khoảng trống (Bốn trục)

Chuyển audit và phần dựng lại thành các dòng trong register. Mỗi trục ứng với một loại khoảng trống:

| Trục | Câu hỏi | Nguồn |
|------|-----------|---------|
| Tư duy | Điều gì đã được quyết định nhưng chưa bao giờ được ghi lại? Invariant nào chỉ tồn tại trong code? | Danh mục quyết định, reconstructed spec |
| Thực hành coding | Code lệch khỏi cách ECC sẽ viết ở đâu? | Các phát hiện của Phase 1, gói `rules/` cho ngôn ngữ đó, các mục spec không có test neo |
| Tính năng còn thiếu | Một bản build từ ngày đầu sẽ bao gồm những gì mà slice này chưa bao giờ có? | Input validation ở ranh giới, observability, rate limiting, idempotency, migration kèm rollback, a11y, i18n, tài liệu cho người dùng, CI gate |
| Lựa chọn công nghệ | Công nghệ đã chọn có đang chống lại codebase không? Lỗi thời, trùng lặp, rủi ro hoặc thiếu? | Danh mục dependency, git archaeology, recon |

Định dạng register (bảng này là đầu ra bền vững của skill):

```markdown
| ID | Axis | Gap | Evidence | Forward fix | Severity | Effort | Status |
|----|------|-----|----------|-------------|----------|--------|--------|
| G-001 | practice | Errors swallowed in retry loop | src/api/retry.ts:42 | Propagate + map at boundary | P1 | S | open |
```

- Mức độ nghiêm trọng (Severity): `P0` lộ lỗ hổng bảo mật hoặc mất dữ liệu, `P1` tính đúng đắn, `P2` thực hành và observability, `P3` lựa chọn và dọn dẹp.
- Effort: `S` dưới một phiên, `M` vài phiên, `L` cần kế hoạch riêng.
- Status: `open`, `in-progress`, `done`, `wont-fix`.
- Mỗi dòng cần một con trỏ bằng chứng. Một khoảng trống mà bạn không chỉ ra được thì chỉ là một ý kiến.

### Phase 4 — Thiết kế lại / Suy nghĩ lại

Biến register thành một kế hoạch có trình tự. Tuân theo thẩm quyền task và phê duyệt hiện có của dự án. Giữ register làm bằng chứng audit được liên kết với hệ thống đó; KHÔNG tạo ra trạng thái task chuẩn (canonical) cạnh tranh. Xác nhận phạm vi và lấy phê duyệt theo yêu cầu của dự án trước khi viết lại, thay thế công nghệ, migration hoặc các thay đổi quan trọng khác.

1. Chạy `architect` hoặc `code-architect` trên các dòng `P0` và `P1` để tạo `target-design.md`: hình dạng đích cho slice, trình tự sửa, và một danh sách tường minh "what does not change" để bảo vệ hành vi đang hoạt động.
2. Backfill retro-ADR cho mọi quyết định chưa được ghi lại từ Phase 2. Đánh dấu chúng là được dựng lại (`status: proposed (reconstructed)`, ngày của retro, ghi chú rằng quyết định gốc có trước bản ghi). Tách biệt lịch sử quan sát được khỏi ý định suy luận, và để chủ dự án xác nhận một quyết định trước khi đánh dấu accepted. KHÔNG BAO GIỜ trình bày một ADR backfill như thể nó được viết vào thời điểm đưa ra quyết định.
3. Phân loại mỗi dòng register vào một trong: `fix-forward` (sửa tại chỗ), `rewrite` (thay thế slice), `leave-documented` (wont-fix). Một `wont-fix` PHẢI ghi lý do trong register — một wont-fix có lý do sẽ đóng khoảng trống tư duy; một wont-fix im lặng sẽ mở lại nó.
4. Sắp xếp trình tự backlog: `P0` trước, sau đó xen kẽ các chiến thắng nhanh (quick win) với các bản sửa lớn hơn để giữ đà.

### Phase 5 — Thực thi tiến về phía trước

Xử lý register qua pipeline ECC tiêu chuẩn, mỗi phiên một dòng làm nhịp cơ bản:

```text
planner (scope the row)
  → tdd-guide (failing test first — for a legacy gap the first test
    usually encodes the missing invariant from reconstructed-spec.md)
  → implement
  → code-reviewer
  → security-reviewer (if the row touches input, auth, or data)
  → doc-updater + ADR (if the decision changed)
  → conventional commit
  → mark the register row done
```

- Cập nhật status trong `gap-register.md` khi các dòng đóng lại; register là trạng thái bền vững, không phải cuộc hội thoại.
- Ở ranh giới giữa các phiên, bàn giao qua cơ chế memory của dự án (`unified-memory`, context carrier) để phiên sau có thể tiếp tục chỉ từ register.

### Phase 6 — Đóng và Re-Audit

Khi mọi dòng đều là `done` hoặc `wont-fix`:

1. Chạy lại audit của Phase 1 trên cùng perimeter.
2. Diff với `baseline-audit.md` và xác minh bằng `verification-loop` — các khoảng trống được cho là đã đóng phải tiếp tục đóng.
3. Ghi lại delta (phát hiện lúc trước, phát hiện hiện tại, số dòng đã đóng, số dòng hoãn) ở cuối `gap-register.md`.
4. Bất cứ thứ gì tái xuất hiện trở thành một dòng mới, không phải một thất bại — register là một vòng lặp, không phải việc làm một lần.

## Tiếp tục giữa chừng

Bất kỳ phiên nào cũng có thể bắt đầu ở giữa. Hãy đọc `docs/retro/<slice>/gap-register.md` trước:

- Register tồn tại với một dòng `in-progress` → Phase 5, hoàn tất dòng đó.
- Register tồn tại với ít nhất một dòng, mọi dòng đã đóng → Phase 6.
- Register tồn tại, các dòng còn open, không dòng nào in progress → tiếp tục tại marker `Current phase:` (Phase 3 register đang chờ triage, hoặc backlog Phase 4 đang chờ dòng đầu tiên).
- Không có register, nhưng `baseline-audit.md` tồn tại → Phase 2.
- Hoàn toàn không có artifact nào → Phase 0 cùng người dùng.

## Anti-Pattern

- Audit toàn bộ repo trước khi chọn bất kỳ slice nào — workflow này được thiết kế theo hướng slice-first.
- Sửa code trong các Phase 1-3 — các phase audit tạo ra register; chỉnh sửa giữa chừng audit sẽ làm hỏng baseline.
- Các dòng register không có con trỏ bằng chứng.
- `wont-fix` không có lý do được ghi lại.
- Trình bày các ADR backfill như các bản ghi đương thời.
- Bỏ qua bước re-audit ở Phase 6 — việc đóng phải được xác minh, không phải tuyên bố.

## Skill liên quan

- `codebase-onboarding` — recon baseline cho Phase 1
- `architecture-decision-records` — backfill retro-ADR ở Phase 4
- `tdd-workflow` — kỷ luật thực thi của Phase 5
- `verification-loop` — đóng ở Phase 6
- `production-audit` — góc nhìn launch-readiness (bổ trợ, làm sau)
- `security-review` — các yêu cầu chỉ về bảo mật
