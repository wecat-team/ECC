---
description: Chạy Workflow native orch-review trên một diff (thay đổi cục bộ hoặc một GitHub PR) và báo cáo các phát hiện blocking so với advisory. Là bề mặt (surface) cho workflow orch-review. Dùng cho một lượt review đa chiều bằng native Workflow, được kiểm chứng đối kháng (adversarial) với fan-out và dedup; với lượt review theo checklist từng bước hãy dùng /code-review, và với lượt review đa agent hãy dùng /review-pr.
argument-hint: "[pr-number | pr-url | để trống cho các thay đổi cục bộ chưa commit]"
---

# /orch-review

Bề mặt cho `workflows/orch-review.workflow.js` — bản port Workflow native của
Phase 5 (Review) trong orch-pipeline. Command này tính toán một diff, đưa nó cho
workflow, và trình bày kết quả. Workflow sở hữu phần fan-out (một reviewer
cho mỗi chiều, dedup, adversarial verify); command này sở hữu input và output.

**Input**: $ARGUMENTS

---

## Chọn chế độ

| Input | Chế độ |
|---|---|
| Để trống | **Local Mode** — review các thay đổi chưa commit |
| Số (ví dụ `42`) hoặc URL của PR | **PR Mode** — review một GitHub PR |

---

## Phase 1 — GATHER

Dựng unified diff và metadata mà workflow cần.

**Local Mode:**

```bash
git diff --name-only HEAD          # changedFiles
git diff HEAD                      # diff text
```

Nếu diff rỗng, hãy dừng lại: "Nothing to review."

**PR Mode:**

Trước hết hãy suy ra một **PR id dạng số an toàn** từ `$ARGUMENTS` — KHÔNG BAO GIỜ truyền đối số
thô vào shell. Chấp nhận một số nguyên trần, hoặc số ở cuối của một URL
`https://github.com/<owner>/<repo>/pull/<N>`. Từ chối mọi thứ khác (văn bản thừa,
ký tự đặc biệt của shell, URL không phải PR) và dừng lại với một lỗi. Chỉ dùng
số nguyên đã trích xuất `<NUMBER>` bên dưới:

```bash
gh pr diff <NUMBER>                       # diff text
gh pr view <NUMBER> --json files \
  --jq '.files[].path'                    # changedFiles
```

Nếu không tìm thấy PR, hãy dừng lại với một lỗi.

Sau đó suy ra `language` từ phần mở rộng file thay đổi chiếm ưu thế (ví dụ
`.ts`/`.tsx` thành `typescript`, `.py` thành `python`, `.go` thành `go`). Để trống
khi thay đổi hỗn hợp hoặc không phải code — workflow sẽ đơn giản bỏ qua reviewer
theo ngôn ngữ cụ thể.

## Phase 2 — INVOKE

Gọi tool Workflow. Workflow tự validate input của nó và fail closed khi
diff thiếu hoặc rỗng, vì vậy luôn truyền một `diff` không rỗng.

```jsonc
Workflow({
  scriptPath: "workflows/orch-review.workflow.js",
  args: {
    diff: "<unified diff text from Phase 1>",   // required
    language: "typescript",                      // optional
    changedFiles: ["src/auth.ts"]                // optional — feeds the security trigger
  }
})
```

Workflow fan-out các reviewer song song, dedup các phát hiện dựa trên đoạn
bằng chứng đã chuẩn hóa, và chạy một adversarial verifier trên mọi phát hiện
CRITICAL/HIGH duy nhất. Nó trả về:

```jsonc
{
  "verdict": "APPROVE" | "CHANGES_REQUESTED",
  "incomplete": false,                 // true if a review dimension failed to run
  "failedDimensions": [ /* { dimension, error } */ ],
  "blocking": [ /* confirmed CRITICAL/HIGH + unverifiable findings */ ],
  "advisory": [ /* MEDIUM/LOW + adversarially-refuted findings */ ],
  "stats": { "dimensions": 3, "failed": 0, "raw": 11, "unique": 4, "confirmed": 3, "unverified": 0, "uncertain": 0, "refuted": 1 }
}
```

## Phase 3 — REPORT

Trình bày kết quả cho người dùng (đây là cổng review của con người; workflow không
commit bất cứ thứ gì):

- Mở đầu bằng `verdict` và dòng `stats` (số chiều, mức thu gọn từ raw xuống unique).
- Liệt kê mọi phát hiện `blocking` kèm file, mức độ nghiêm trọng và bằng chứng — những phát hiện này phải
  được giải quyết trước khi commit. Các phát hiện được gắn thẻ "could not be verified" vẫn ở lại trong
  `blocking` theo thiết kế; hãy chỉ rõ chúng cần được xác nhận thủ công.
- Liệt kê ngắn gọn các phát hiện `advisory` (MEDIUM/LOW và các mục bị verifier bác bỏ).
- Nếu `incomplete` là true, hãy nêu những chiều nào trong `failedDimensions` đã không
  chạy và do đó verdict không phải là một sự phê duyệt hoàn chỉnh.

## Hợp đồng Fail-Closed

Command này KHÔNG BAO GIỜ được trình bày một APPROVE sạch khi lượt review không thể chạy đầy đủ.
Nếu bản thân tool Workflow bị lỗi, hãy báo cáo lỗi — không quay lại một lượt review
tự làm thủ công và không ám chỉ rằng diff đã được duyệt.

---

## Edge Case

- **Không có `gh` CLI (PR Mode)**: dừng lại và báo người dùng rằng PR Mode cần `gh`; đề xuất
  dùng Local Mode trên một branch đã checkout thay thế.
- **Diff lớn**: workflow tự động giới hạn mức đồng thời của reviewer, nên một
  diff lớn sẽ chậm hơn nhưng an toàn; hãy cảnh báo người dùng rằng có thể mất nhiều thời gian hơn.
- **File binary hoặc được sinh tự động**: loại chúng khỏi `changedFiles` trước khi gọi —
  chúng chỉ thêm nhiễu cho security trigger mà không có nội dung để review.
