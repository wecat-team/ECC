---
description: Vòng lặp hội tụ dual-review đối kháng — hai reviewer model độc lập đều phải approve trước khi code được ship. Dùng cho phiên bản vòng lặp này chạy qua CLI; bọc skill santa-method.
---

# Santa Loop

Vòng lặp hội tụ dual-review đối kháng dùng skill santa-method. Hai reviewer độc lập — khác model, không chia sẻ context — đều phải trả về NICE trước khi code được ship.

## Mục đích

Chạy hai reviewer độc lập (Claude Opus + một model bên ngoài) trên đầu ra của task hiện tại. Cả hai đều phải trả về NICE trước khi code được push. Nếu một trong hai trả về NAUGHTY, hãy sửa mọi vấn đề được đánh dấu, commit, và chạy lại với reviewer mới hoàn toàn — tối đa 3 vòng.

## Cách dùng

```
/santa-loop [file-or-glob | description]
```

## Quy trình

### Bước 1: Xác định cần review gì

Xác định phạm vi từ `$ARGUMENTS` hoặc quay về các thay đổi chưa commit:

```bash
git diff --name-only HEAD
```

Đọc tất cả file đã thay đổi để xây dựng toàn bộ context review. Nếu `$ARGUMENTS` chỉ định một đường dẫn, file hoặc mô tả, hãy dùng nó làm phạm vi thay thế.

### Bước 2: Xây dựng rubric

Xây dựng một rubric phù hợp với các loại file đang được review. Mỗi tiêu chí phải có điều kiện PASS/FAIL khách quan. Tối thiểu phải bao gồm:

| Tiêu chí | Điều kiện đạt |
|-----------|---------------|
| Correctness | Logic đúng đắn, không có bug, xử lý các edge case |
| Security | Không có secret, injection, XSS hay các vấn đề OWASP Top 10 |
| Error handling | Lỗi được xử lý tường minh, không nuốt lỗi im lặng |
| Completeness | Mọi yêu cầu đều được đáp ứng, không thiếu trường hợp nào |
| Internal consistency | Không có mâu thuẫn giữa các file hoặc các phần |
| No regressions | Thay đổi không làm hỏng hành vi hiện có |

Thêm các tiêu chí đặc thù theo lĩnh vực dựa trên loại file (ví dụ: type safety cho TS, memory safety cho Rust, migration safety cho SQL).

### Bước 3: Dual Independent Review

Khởi chạy hai reviewer **song song** bằng tool Agent (cả hai trong một message duy nhất để thực thi đồng thời). Cả hai phải hoàn thành trước khi chuyển sang verdict gate.

Mỗi reviewer đánh giá từng tiêu chí của rubric là PASS hoặc FAIL, rồi trả về JSON có cấu trúc:

```json
{
  "verdict": "PASS" | "FAIL",
  "checks": [
    {"criterion": "...", "result": "PASS|FAIL", "detail": "..."}
  ],
  "critical_issues": ["..."],
  "suggestions": ["..."]
}
```

Verdict gate (Bước 4) ánh xạ chúng sang NICE/NAUGHTY: cả hai PASS → NICE, một trong hai FAIL → NAUGHTY.

#### Reviewer A: Claude Agent (luôn chạy)

Khởi chạy một Agent (subagent_type: `code-reviewer`, model: `opus`) với toàn bộ rubric + tất cả file đang được review. Prompt phải bao gồm:
- Toàn bộ rubric
- Toàn bộ nội dung các file đang được review
- "You are an independent quality reviewer. You have NOT seen any other review. Your job is to find problems, not to approve."
- Trả về verdict JSON có cấu trúc ở trên

#### Reviewer B: Model bên ngoài (fallback sang Claude nếu chưa có reviewer bên ngoài sẵn sàng)

Antigravity là tùy chọn và yêu cầu runtime `ccg-workflow` bên ngoài; nó không có trong bản cài ECC cơ bản. Một bản cài đặt hiện có phải cung cấp cả `~/.claude/bin/codeagent-wrapper` có thể thực thi lẫn một file role reviewer thông thường có thể đọc tại `~/.claude/.ccg/prompts/antigravity/reviewer.md`. Nếu không, hãy giữ nguyên fallback Claude. Dùng hợp đồng chọn model do wrapper duy trì; không thêm model pin cho Antigravity.

Chạy việc phát hiện, tạo prompt và lần review bên ngoài đã chọn cùng nhau trong một Bash subshell duy nhất này. Thay placeholder prompt bằng cùng rubric, nội dung file và hướng dẫn chỉ-review đã đưa cho Reviewer A. Thứ tự vẫn là Codex, Gemini, Antigravity, rồi Claude. Fallback Claude không tạo file prompt.

```bash
(
  set -e
  set -o pipefail

  REVIEWER_WRAPPER="$HOME/.claude/bin/codeagent-wrapper"
  REVIEWER_ROLE="$HOME/.claude/.ccg/prompts/antigravity/reviewer.md"
  if command -v codex >/dev/null 2>&1; then
    REVIEWER_BACKEND=codex
  elif command -v gemini >/dev/null 2>&1; then
    REVIEWER_BACKEND=gemini
  elif [ -x "$REVIEWER_WRAPPER" ] && [ -f "$REVIEWER_ROLE" ] && [ -r "$REVIEWER_ROLE" ]; then
    REVIEWER_BACKEND=antigravity
  else
    printf '%s\n' 'CLAUDE_FALLBACK'
    exit 0
  fi

  cleanup_reviewer_prompt() {
    reviewer_status=$?
    trap - EXIT
    if ! rm -f -- "$PROMPT_FILE"; then
      printf '%s\n' 'Could not remove reviewer prompt; remove the private temp file before continuing.' >&2
      if [ "$reviewer_status" -eq 0 ]; then reviewer_status=1; fi
    fi
    exit "$reviewer_status"
  }

  umask 077
  PROMPT_FILE=$(mktemp "${TMPDIR:-/tmp}/santa-reviewer-b.XXXXXX")
  trap cleanup_reviewer_prompt EXIT
  trap 'exit 129' HUP
  trap 'exit 130' INT
  trap 'exit 143' TERM
  cat > "$PROMPT_FILE" << 'EOF'
... full rubric + file contents + reviewer instructions ...
EOF

  case "$REVIEWER_BACKEND" in
    codex)
      codex exec --sandbox read-only -m gpt-5.4 -C "$(pwd)" - < "$PROMPT_FILE"
      ;;
    gemini)
      REVIEWER_PROMPT=$(cat "$PROMPT_FILE")
      gemini -p "$REVIEWER_PROMPT" -m gemini-2.5-pro
      ;;
    antigravity)
      {
        printf 'ROLE_FILE: %s\n' "$REVIEWER_ROLE"
        cat "$PROMPT_FILE"
      } | "$REVIEWER_WRAPPER" --backend antigravity - "$PWD"
      ;;
  esac
)
```

Subshell xóa prompt của nó khi thành công, khi backend hoặc việc ghi prompt thất bại, và khi nhận tín hiệu HUP/INT/TERM đã được xử lý, đồng thời giữ nguyên status lỗi gốc. Một lỗi chỉ ở bước cleanup cũng trả về khác 0. Việc kết thúc cưỡng bức như SIGKILL không thể chạy cleanup; hãy kiểm tra các file tạm private sau khi một tiến trình bị ngắt. Một lần gọi bên ngoài thất bại không phải là sự chấp thuận và KHÔNG ĐƯỢC âm thầm chuyển thành fallback hay tiếp tục sang verdict gate.

**Fallback Claude Agent:** Nếu subshell in ra `CLAUDE_FALLBACK`, khởi chạy một Claude Agent thứ hai (subagent_type: `code-reviewer`, model: `opus`) trực tiếp với rubric và nội dung file. Marker này là chỉ thị điều phối, không phải verdict của review. Ghi log rằng cả hai reviewer dùng cùng một họ model; giữ context của chúng tách biệt.

Trong mọi trường hợp, reviewer phải trả về cùng verdict JSON có cấu trúc như Reviewer A.

### Bước 4: Verdict Gate

- **Cả hai PASS** → **NICE** — chuyển sang Bước 6 (push)
- **Một trong hai FAIL** → **NAUGHTY** — gộp tất cả vấn đề critical từ cả hai reviewer, loại trùng, chuyển sang Bước 5

### Bước 5: Chu trình sửa (đường NAUGHTY)

1. Hiển thị tất cả vấn đề critical từ cả hai reviewer
2. Sửa mọi vấn đề được đánh dấu — chỉ thay đổi những gì được đánh dấu, không refactor tiện tay
3. Commit tất cả bản sửa trong một commit duy nhất:
   ```
   fix: address santa-loop review findings (round N)
   ```
4. Chạy lại Bước 3 với **reviewer mới hoàn toàn** (không có ký ức về các vòng trước)
5. Lặp lại cho đến khi cả hai trả về PASS

**Tối đa 3 lần lặp.** Nếu vẫn NAUGHTY sau 3 vòng, hãy dừng và trình bày các vấn đề còn lại:

```
SANTA LOOP ESCALATION (exceeded 3 iterations)

Remaining issues after 3 rounds:
- [list all unresolved critical issues from both reviewers]

Manual review required before proceeding.
```

KHÔNG push.

### Bước 6: Push (đường NICE)

Khi cả hai reviewer trả về PASS:

```bash
git push -u origin HEAD
```

### Bước 7: Báo cáo cuối

In báo cáo đầu ra (xem phần Output bên dưới).

## Output

```
SANTA VERDICT: [NICE / NAUGHTY (escalated)]

Reviewer A (Claude Opus):   [PASS/FAIL]
Reviewer B ([model used]):  [PASS/FAIL]

Agreement:
  Both flagged:      [issues caught by both]
  Reviewer A only:   [issues only A caught]
  Reviewer B only:   [issues only B caught]

Iterations: [N]/3
Result:     [PUSHED / ESCALATED TO USER]
```

## Ghi chú

- Reviewer A (Claude Opus) luôn chạy — đảm bảo ít nhất một reviewer mạnh bất kể tooling.
- Mục tiêu của Reviewer B là sự đa dạng model. Hãy ghi lại model/provider thực tế mà backend được chọn báo cáo; chỉ riêng tên wrapper Antigravity không xác lập một họ model khác. Fallback chỉ-Claude cung cấp sự cô lập context nhưng mất đi sự đa dạng model.
- Dùng hợp đồng chọn model do mỗi backend duy trì. Không pin một model ID Antigravity tạm thời trong workflow này.
- Yêu cầu đầu ra chỉ-review từ mọi reviewer. Codex dùng `--sandbox read-only`; quyền của Gemini và Antigravity phụ thuộc vào cấu hình runtime đã cài. Chỉ riêng việc gọi wrapper CCG không đảm bảo sandbox chỉ-đọc.
- Reviewer mới ở mỗi vòng ngăn thiên kiến neo (anchoring bias) từ các phát hiện trước.
- Rubric là đầu vào quan trọng nhất. Hãy siết chặt nó nếu reviewer duyệt qua loa hoặc đánh dấu các vấn đề style chủ quan.
- Commit xảy ra ở các vòng NAUGHTY để các bản sửa được giữ lại kể cả khi vòng lặp bị ngắt.
- Push chỉ xảy ra sau NICE — không bao giờ giữa chừng vòng lặp.
