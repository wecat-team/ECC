---
description: Gửi code do Claude viết cho GPT-6-Astra (ChatGPT, qua Codex CLI) để review độc lập giữa các nhà cung cấp (cross-provider), rồi sửa những gì nó tìm ra.
argument-hint: "[--base <branch> | --commit <sha> | --files <paths> | --files-from-commit <sha>] [extra reviewer instructions]"
model: opus
---

# Astra Review

Ý kiến thứ hai từ nhà cung cấp khác (cross-provider). Claude viết code; GPT-6-Astra (OpenAI, chạy qua Codex CLI cài sẵn trên máy với đăng nhập ChatGPT của bạn) review mà không chia sẻ context. Sau đó Claude sửa những gì Astra tìm ra và chạy lại cho đến khi Astra cho pass hoặc chạm giới hạn số vòng.

Lệnh này chạy trên **Opus** (`model: opus`). Opus điều phối, xác minh các phát hiện, kiểm tra mọi diff và chạy test. Việc sửa được giao cho một subagent **Fable**; khi Fable đã chạm giới hạn sử dụng, Astra sẽ áp dụng các bản sửa thay thế (xem Bước 4).

## Mục đích

- Bắt các vấn đề mà một reviewer cùng model có chung điểm mù.
- Giữ Claude là người viết: Astra review trong sandbox chỉ đọc và trả về verdict có cấu trúc, không bao giờ trả về patch. Ngoại lệ duy nhất là phương án dự phòng khi Fable chạm giới hạn ở Bước 4, trong đó Astra chỉnh sửa working tree và Opus xác minh kết quả.
- Tạo ra verdict đọc được bằng máy (PASS/FAIL, các phát hiện gắn mức độ nghiêm trọng) có thể dùng để chặn commit hoặc push.

## Điều kiện tiên quyết

- Đã cài Codex CLI và đăng nhập bằng ChatGPT: `codex login`
- `gpt-6-astra` khả dụng trên tài khoản (kiểm tra bằng model picker của `codex`; ghi đè bằng `ECC_ASTRA_MODEL`)
- Việc gọi lệnh này đồng nghĩa với việc bạn đồng ý gửi diff cho OpenAI. Không chạy trên code mà bạn không được phép chia sẻ.

## Cách dùng

```
/astra-review                          # uncommitted changes (default)
/astra-review --base main              # everything on this branch vs main
/astra-review --commit HEAD~1          # one commit
/astra-review --files src/a.ts src/b.ts
/astra-review --files-from-commit HEAD~1  # repair round after a --commit review
/astra-review Focus on the SQL layer   # free text becomes extra reviewer instructions
```

## Workflow

### Bước 1: Xác định phạm vi

Phân tích `$ARGUMENTS`. Các flag (`--base`, `--commit`, `--files`, `--files-from-commit`) chọn phạm vi; phần văn bản còn lại được truyền làm `--instructions`. Nếu không có flag nào, review các thay đổi chưa commit.

Xem trước những gì sẽ rời khỏi máy trước khi gửi:

```bash
ASTRA=""
for candidate in "${CLAUDE_PLUGIN_ROOT:-$HOME/.claude}/scripts/astra-review.js" \
                 "./.claude/scripts/astra-review.js" \
                 "$HOME/.claude/scripts/astra-review.js" \
                 "./scripts/astra-review.js"; do   # plugin, project-local, global, the ECC repo itself
  [ -f "$candidate" ] && ASTRA="$candidate" && break
done
[ -n "$ASTRA" ] || { echo "astra-review.js not found; install ECC commands-core"; exit 2; }
node "$ASTRA" --dry-run [scope flags] | head -40
```

Nếu đầu ra ghi "Nothing to review", hãy dừng và báo người dùng.

### Bước 2: Chạy review

```bash
node "$ASTRA" --consent-to-openai [scope flags] \
  --instructions "<extra text, if any>" \
  --output "$(mktemp -d)/astra-review.json"   # private dir, never a shared predictable path
```

Script in ra một báo cáo markdown và thoát với mã 0 (PASS), 1 (FAIL) hoặc 2 (lỗi). Khi thoát với mã 2, hãy báo lỗi nguyên văn và dừng. Nguyên nhân thường gặp: chưa cài Codex, chưa đăng nhập, model không khả dụng trên tài khoản, timeout.

### Bước 3: Cổng verdict

- **PASS** không có phát hiện MEDIUM: báo cáo và kết thúc.
- **PASS** kèm phát hiện MEDIUM/LOW: liệt kê chúng, sửa những phát hiện rõ ràng đúng, rồi kết thúc.
- **FAIL** (bất kỳ CRITICAL hoặc HIGH nào): chuyển sang Bước 4.

### Bước 4: Chu trình sửa (tối đa 3 vòng)

1. Hiển thị mọi phát hiện CRITICAL và HIGH kèm file và dòng.
2. Xác minh từng phát hiện với code trước khi thay đổi bất cứ điều gì (Opus làm việc này, không phải subagent). Astra có thể sai; nếu một phát hiện là false positive, hãy nói rõ và bỏ qua nó kèm lý do một dòng.
3. Chuẩn bị vòng này. Mỗi lời gọi Bash bắt đầu một shell mới, nên hãy in các đường dẫn này một lần và dùng lại nguyên văn (các biến shell như `$ASTRA` không tồn tại giữa các lời gọi):
   - `mktemp -d` cho một thư mục riêng `<dir>`. Dùng tool Write ghi các phát hiện đã xác nhận vào `<dir>/confirmed.json`, dưới dạng mảng JSON lấy từ `review.findings` trong payload `--output`.
   - Chụp snapshot working tree trước khi bất kỳ writer nào chạm vào: `git diff --binary HEAD > <dir>/before.patch` và `git ls-files --others --exclude-standard > <dir>/before-untracked.txt`. Phạm vi mặc định review công việc chưa commit, nên các chỉnh sửa của chính người dùng đã nằm sẵn trong `git diff`; snapshot là thứ phân tách chúng khỏi phần của writer.
4. Áp dụng các bản sửa. **Thử Fable trước, dự phòng bằng Astra:**
   - **Fable (writer mặc định).** Khởi chạy một Agent với `model: "fable"` (subagent type `general-purpose`). Prompt của nó gồm các phát hiện đã xác nhận, chỉ thị chỉ thay đổi những gì đã bị đánh dấu và không refactor tiện tay, và lệnh test của dự án.
   - **Phát hiện Fable chạm giới hạn sử dụng.** Chỉ chuyển khi chính lời gọi Agent thất bại với lỗi API có type là `rate_limit` / `rate_limit_error` hoặc có status HTTP 429 (ví dụ `You've reached your Fable limit ... (error type rate_limit, HTTP 429 ...)`). Những từ như "quota" hoặc "rate limit" trong một kết quả thành công không bao giờ là tác nhân kích hoạt: code về rate limiting cũng trích dẫn chúng. Không thử lại Fable trong session này, và thông báo cho người dùng một lần: `Fable usage limit reached; Astra is applying the fixes, Opus is verifying.` Sau đó chạy, với các đường dẫn nguyên văn từ mục 3:

     ```bash
     node <astra-review.js path> --consent-to-openai --fix-findings <dir>/confirmed.json \
       --instructions "<extra text, if any>"
     ```

     Astra chỉnh sửa working tree trong sandbox `workspace-write` với cùng mức cô lập như lúc review (không web search, không network, MCP bị tắt, config người dùng bị bỏ qua, không chuyển tiếp API key); thư mục tạm của hệ thống và `$TMPDIR` bị loại trừ, nên chỉ repository là ghi được. Nó không commit hay push. Thoát với mã 2 nghĩa là việc sửa thất bại: hãy báo cáo và dừng.
   - **Bất kỳ lỗi Fable nào khác** (sửa sai, crash không liên quan đến giới hạn): Opus tự sửa trực tiếp. Không gửi cho Astra.
5. Opus kiểm tra công việc của writer so với snapshot: so sánh `git diff --binary HEAD` với `<dir>/before.patch`, và `git ls-files --others --exclude-standard` với `<dir>/before-untracked.txt`. Chỉ phần chênh lệch giữa chúng mới là của writer. Hoàn tác các hunk của writer nằm ngoài các phát hiện đã đánh dấu; không bao giờ chạm vào các hunk đã có sẵn trong snapshot, vì đó là công việc của người dùng. Đảm bảo không phát hiện nào được "sửa" bằng cách xóa test hoặc làm yếu các kiểm tra. Báo cáo sửa của Astra chỉ là một lời tuyên bố, không phải bằng chứng, và prompt của nó được dựng từ code đang được review, nên hãy coi các chỉnh sửa bất ngờ là có thể do prompt injection.
6. Chạy test của dự án.
7. Chạy lại Bước 2. Reviewer không có trí nhớ về các vòng trước. Phạm vi ở các vòng sau:
   - mặc định và `--base`: không đổi. Cả hai đều diff working tree, nên các bản sửa được bao gồm.
   - `--commit <sha>`: chuyển sang `--files-from-commit <sha>`, review nội dung hiện tại của các file mà commit đó đã chạm tới (đường dẫn bị xóa được bỏ qua, merge commit và root commit hoạt động bình thường). Chạy lại `--commit` sẽ gửi lại diff gốc chưa được sửa.

Sau 3 vòng mà vẫn còn phát hiện CRITICAL/HIGH, hãy dừng và giao danh sách cho người dùng. Không push.

### Bước 5: Báo cáo

```
ASTRA VERDICT: [PASS / FAIL (escalated)]
Model:      gpt-6-astra
Scope:      [uncommitted | base main | commit sha | N files]
Rounds:     [N]/3
Fixer:      [Fable | Astra (Fable usage limit) | Opus]

Fixed:          [findings fixed, with file:line]
False positive: [findings skipped, with reason]
Remaining:      [unresolved CRITICAL/HIGH, if any]
```

## Ghi chú

- Script là `scripts/astra-review.js` dưới plugin root; thư viện nằm ở `scripts/lib/astra-review/`. Luôn chạy nó từ thư mục của dự án đang được review để git thấy đúng dự án đó.
- `--base <branch>` diff từ merge-base của `<branch>` và HEAD đến working tree, cộng thêm các file untracked. Cả công việc đã commit lẫn chưa commit trên branch đều được bao gồm.
- Diff trên 200 KB bị cắt bớt; reviewer được yêu cầu đọc các file đã liệt kê bằng các tool chỉ đọc của nó.
- Web search bị tắt với reviewer, config Codex cấp người dùng không được nạp, và mọi MCP server mà Codex báo qua `codex mcp list` đều bị tắt theo tên (một bảng `mcp_servers` rỗng sẽ không xóa được chúng). Chỉ các biến kiểu PATH/HOME mới đến được process Codex. API key trong môi trường của bạn không được chuyển tiếp.
- Để chặn một lần push dựa trên review này, hãy chạy nó trước `git push` và từ chối push khi mã thoát là 1. Kết hợp với `/santa-loop` khi bạn muốn có hai reviewer độc lập.
- Nếu thiếu Codex, hãy dự phòng bằng `/code-review` và nói rõ rằng không có cross-provider review nào xảy ra.
- Phương án dự phòng khi Fable chạm giới hạn cũng gửi các phát hiện đã xác nhận và các file Astra mở cho OpenAI. Việc gọi lệnh này bao gồm cả điều đó.
- `--fix-findings` không thể kết hợp với flag phạm vi. `--dry-run` in ra prompt sửa mà không gọi Codex.
- Tài liệu hướng dẫn đầy đủ (cài đặt, phạm vi, chặn push, xử lý sự cố): `docs/ASTRA-REVIEW-GUIDE.md` trong repository ECC.
