---
name: skill-stocktake
description: "Dùng khi audit chất lượng các skill và command của Claude. Hỗ trợ chế độ Quick Scan (chỉ các skill đã thay đổi) và Full Stocktake với đánh giá theo batch tuần tự bằng subagent."
metadata:
  origin: ECC
---

# skill-stocktake

Slash command (`/skill-stocktake`) audit toàn bộ skill và command của Claude bằng checklist chất lượng + đánh giá tổng thể (holistic) của AI. Hỗ trợ hai chế độ: Quick Scan cho các skill mới thay đổi và Full Stocktake cho việc review toàn bộ.

## Phạm vi

Command nhắm tới các đường dẫn sau **tính tương đối theo thư mục nơi nó được gọi**:

| Đường dẫn | Mô tả |
|------|-------------|
| `~/.claude/skills/` | Skill toàn cục (mọi dự án) |
| `{cwd}/.claude/skills/` | Skill cấp dự án (nếu thư mục tồn tại) |

**Ở đầu Giai đoạn 1, command liệt kê tường minh những đường dẫn nào đã được tìm thấy và quét.**

Các thư mục tên `.trash` bị loại khỏi cả hai chế độ quét: skill đã lưu trữ (archived) không thuộc danh mục đang hoạt động. Nếu một `results.json` cũ chứa các mục `.trash`, hãy bắt đầu một Full Stocktake mới bằng cách khởi tạo cache bên dưới trước khi tiếp tục Quick Scan. Một lần lưu thông thường chỉ gộp các mục và không xóa các bản ghi đã archive.

### Nhắm tới một dự án cụ thể

Để bao gồm các skill cấp dự án, hãy chạy từ thư mục gốc của dự án đó:

```bash
cd ~/path/to/my-project
/skill-stocktake
```

Nếu dự án không có thư mục `.claude/skills/`, chỉ các skill và command toàn cục được đánh giá.

## Chế độ

| Chế độ | Điều kiện kích hoạt | Thời lượng |
|------|---------|---------|
| Quick Scan | `results.json` tồn tại (mặc định) | 5–10 phút |
| Full Stocktake | `results.json` không tồn tại, hoặc `/skill-stocktake full` | 20–30 phút |

Các shell script yêu cầu Bash, Node.js và `jq` có trong `PATH`.

**Cache kết quả:** `~/.claude/skills/skill-stocktake/results.json`

## Luồng Quick Scan

Chỉ đánh giá lại các skill đã thay đổi kể từ lần chạy trước (5–10 phút).

1. Đọc `~/.claude/skills/skill-stocktake/results.json`
2. Chạy: `bash ~/.claude/skills/skill-stocktake/scripts/quick-diff.sh \
         ~/.claude/skills/skill-stocktake/results.json`
   (Thư mục dự án được tự động phát hiện từ `$PWD/.claude/skills`; chỉ truyền tường minh khi cần)
3. Nếu đầu ra là `[]`: báo cáo "No changes since last run." rồi dừng
4. Chỉ đánh giá lại các file đã thay đổi đó theo cùng tiêu chí của Giai đoạn 2
5. Giữ nguyên kết quả trước đó của các skill không thay đổi
6. Chỉ xuất phần diff
7. Chạy: `bash ~/.claude/skills/skill-stocktake/scripts/save-results.sh \
         ~/.claude/skills/skill-stocktake/results.json <<< "$EVAL_RESULTS"`

## Luồng Full Stocktake

### Giai đoạn 1 — Kiểm kê (Inventory)

Chạy toàn bộ khối này trong **một lần gọi Bash duy nhất**. Nó in danh mục cho agent và chỉ khởi tạo một lượt chạy full mới khi không có lượt chạy dở dang nào để tiếp tục:

```bash
(
  set -euo pipefail
  SCAN_JSON=$(bash ~/.claude/skills/skill-stocktake/scripts/scan.sh)
  printf '%s\n' "$SCAN_JSON"
  RESULTS_JSON=~/.claude/skills/skill-stocktake/results.json

  CACHE_STATUS=""
  if [[ -f "$RESULTS_JSON" ]]; then
    CACHE_STATUS=$(jq -r '.batch_progress.status // ""' "$RESULTS_JSON")
  fi
  if [[ "$CACHE_STATUS" == "in_progress" ]]; then
    RESUMED_RESULTS=$(jq --slurpfile saved "$RESULTS_JSON" '
      . as $inventory | $saved[0]
      | .skills = (.skills | to_entries
        | map(.key = (.value.path // .key))
        | map(select(. as $entry
          | $entry.value.mtime != null
            and any($inventory.skills[];
              .path == $entry.key and .mtime == $entry.value.mtime)))
        | from_entries)
      | .mode = "full"
      | .batch_progress = {
          total: ($inventory.skills | length),
          evaluated: (.skills | length), status: "in_progress"
        }
    ' <<< "$SCAN_JSON")
    bash ~/.claude/skills/skill-stocktake/scripts/save-results.sh \
      "$RESULTS_JSON" --replace <<< "$RESUMED_RESULTS"
  else
    INITIAL_RESULTS=$(printf '%s\n' "$SCAN_JSON" | jq '{
      mode: "full", skills: {},
      batch_progress: {total: (.skills | length), evaluated: 0, status: "in_progress"}
    }')
    bash ~/.claude/skills/skill-stocktake/scripts/save-results.sh \
      "$RESULTS_JSON" --replace <<< "$INITIAL_RESULTS"
  fi
)
```

Script liệt kê các file skill, trích xuất frontmatter và thu thập mtime theo UTC.
Thư mục dự án được tự động phát hiện từ `$PWD/.claude/skills`; chỉ truyền tường minh khi cần.
Trình bày bản tóm tắt quá trình quét và bảng danh mục từ đầu ra của script:

```
Scanning:
  ✓ ~/.claude/skills/         (17 files)
  ✗ {cwd}/.claude/skills/    (not found — global skills only)
```

| Skill | Dùng 7 ngày | Dùng 30 ngày | Mô tả |
|-------|--------|---------|-------------|

Số lần sử dụng lấy từ file tùy chọn `~/.claude/observations.jsonl` (có thể ghi đè bằng `SKILL_STOCKTAKE_OBSERVATIONS`), file này Claude Code không tạo mặc định. Khi file không tồn tại, `use_7d` và `use_30d` là JSON `null`; hiển thị chúng là **unmeasured (chưa đo)** trong bảng danh mục và bảng tóm tắt. Giá trị số `0` nghĩa là file tồn tại nhưng không có quan sát Read khớp nào trong khoảng thời gian đó. Thiếu dữ liệu sử dụng KHÔNG BAO GIỜ là bằng chứng để retire một skill.

`--replace` ghi một snapshot cache hoàn chỉnh. Một lượt chạy mới bắt đầu với phần đánh giá rỗng; một lượt chạy được tiếp tục (resume) thì chỉ giữ lại một đánh giá đã lưu khi đường dẫn của nó vẫn còn tồn tại và mtime đã lưu (khác null) khớp với danh mục mới. Các skill đã thay đổi và các mục không có mtime cần được đánh giá lại. Nó loại bỏ các mục đã archive/xóa và làm mới số liệu tiến độ ngay cả khi không còn batch mới nào. Các mục hiện có dùng tên làm key được chuẩn hóa dựa trên `path` đã lưu. KHÔNG BAO GIỜ dùng payload khởi tạo rỗng cho việc resume. Các chunk sau, các cập nhật hoàn tất và Quick Scan PHẢI bỏ `--replace` để chúng được gộp vào lượt chạy hiện tại thay vì làm mất kết quả trước đó.

### Giai đoạn 2 — Đánh giá chất lượng

Khởi chạy một subagent bằng Agent tool (**general-purpose agent**) với JSON thực tế do Giai đoạn 1 phát ra và checklist bên dưới. Sao chép các giá trị của danh mục vào chính prompt; biến shell không được chuyển sang các lệnh gọi Agent. Đưa vào toàn bộ danh mục để kiểm tra mức độ chồng lấn và chỉ rõ các đường dẫn trong batch hiện tại cần đánh giá. Không gửi các placeholder nguyên văn của danh mục hay checklist.

Subagent đọc từng skill được giao, áp dụng checklist và trả về một đối tượng JSON có map `skills` với key là đường dẫn trong danh mục. Mỗi mục gồm `path`, `mtime` đã quét, `verdict` và `reason` tự chứa (self-contained). Dùng cùng key đường dẫn trong mọi batch để việc gộp kết quả không ghi đè nhầm một skill khác trùng tên.

**Hướng dẫn chia chunk:** Xử lý khoảng ~20 skill mỗi lần gọi subagent để giữ context ở mức quản lý được. Sau mỗi chunk, bọc map `skills` mà nó trả về với `mode: "full"` và `batch_progress: {total, evaluated, status: "in_progress"}`. Đặt `total` bằng kích thước danh mục và `evaluated` bằng tổng số tích lũy các đường dẫn đã đánh giá khác nhau, bao gồm cả các batch đã lưu. Gán JSON này cho `CHUNK_RESULTS` và chạy lệnh sau trong **cùng một lần gọi Bash với phép gán đó**:

```bash
bash ~/.claude/skills/skill-stocktake/scripts/save-results.sh \
  ~/.claude/skills/skill-stocktake/results.json <<< "$CHUNK_RESULTS"
```

Sau khi tất cả skill được đánh giá, hãy lưu trạng thái hoàn tất trước khi sang Giai đoạn 3:

```bash
(
  set -euo pipefail
  RESULTS_JSON=~/.claude/skills/skill-stocktake/results.json
  COMPLETED_RESULTS=$(jq -e '
    if (.skills | length) == .batch_progress.total then
      {skills: {}, mode: "full", batch_progress: (.batch_progress + {
        evaluated: (.skills | length), status: "completed"
      })}
    else error("Inventory still has unevaluated skills") end
  ' "$RESULTS_JSON")
  bash ~/.claude/skills/skill-stocktake/scripts/save-results.sh \
    "$RESULTS_JSON" <<< "$COMPLETED_RESULTS"
)
```

**Phát hiện resume:** Nếu thấy `status: "in_progress"` khi khởi động, hãy chạy Giai đoạn 1 để đối chiếu kết quả đã lưu với danh mục mới, sau đó chỉ đánh giá những đường dẫn không có trong map `skills` đã đối chiếu. Nếu không còn đường dẫn nào, lưu trạng thái hoàn tất ngay lập tức. Các đánh giá đã hoàn tất chỉ được giữ lại cho những đường dẫn còn tồn tại có mtime khớp và khác null; các skill mới hoặc đã thay đổi và các mục không có mtime cần được đánh giá.

Mỗi skill được đánh giá theo checklist này:

```
- [ ] Content overlap with other skills checked
- [ ] Overlap with MEMORY.md / CLAUDE.md checked
- [ ] Freshness of technical references verified (use WebSearch if tool names / CLI flags / APIs are present)
- [ ] Usage frequency considered when measured; missing observations marked unmeasured, not treated as zero
```

Tiêu chí verdict:

| Verdict | Ý nghĩa |
|---------|---------|
| Keep | Hữu ích và còn cập nhật |
| Improve | Đáng giữ lại, nhưng cần cải thiện cụ thể |
| Update | Công nghệ được tham chiếu đã lỗi thời (xác minh bằng WebSearch) |
| Retire | Chất lượng thấp, lỗi thời hoặc chi phí không cân xứng với giá trị |
| Merge into [X] | Chồng lấn đáng kể với skill khác; nêu rõ đích để merge |

Việc đánh giá là **phán đoán tổng thể của AI (holistic AI judgment)** — không phải rubric số. Các khía cạnh định hướng:
- **Actionability (khả năng hành động)**: ví dụ code, lệnh hoặc các bước cho phép hành động ngay lập tức
- **Scope fit (độ phù hợp phạm vi)**: tên, điều kiện kích hoạt và nội dung thống nhất với nhau; không quá rộng hay quá hẹp
- **Uniqueness (tính độc nhất)**: giá trị không thể thay thế bằng MEMORY.md / CLAUDE.md / skill khác
- **Currency (độ cập nhật)**: các tham chiếu kỹ thuật còn hoạt động trong môi trường hiện tại

**Yêu cầu chất lượng của reason** — trường `reason` phải tự chứa đầy đủ và đủ để ra quyết định:
- KHÔNG chỉ viết mỗi "unchanged" — LUÔN LUÔN nêu lại bằng chứng cốt lõi
- Với **Retire**: nêu (1) lỗi cụ thể nào đã được phát hiện, (2) thứ gì khác đáp ứng cùng nhu cầu đó
  - Bad: `"Superseded"`
  - Good: `"disable-model-invocation: true already set; superseded by continuous-learning-v2 which covers all the same patterns plus confidence scoring. No unique content remains."`
- Với **Merge**: nêu rõ đích và mô tả nội dung cần tích hợp
  - Bad: `"Overlaps with X"`
  - Good: `"42-line thin content; Step 4 of chatlog-to-article already covers the same workflow. Integrate the 'article angle' tip as a note in that skill."`
- Với **Improve**: mô tả thay đổi cụ thể cần làm (section nào, hành động gì, kích thước mục tiêu nếu liên quan)
  - Bad: `"Too long"`
  - Good: `"276 lines; Section 'Framework Comparison' (L80–140) duplicates ai-era-architecture-principles; delete it to reach ~150 lines."`
- Với **Keep** (chỉ mtime thay đổi trong Quick Scan): nêu lại lý do của verdict ban đầu, không viết "unchanged"
  - Bad: `"Unchanged"`
  - Good: `"mtime updated but content unchanged. Unique Python reference explicitly imported by rules/python/; no overlap found."`

### Giai đoạn 3 — Bảng tóm tắt

| Skill | Dùng 7 ngày | Verdict | Reason |
|-------|--------|---------|--------|

### Giai đoạn 4 — Hợp nhất (Consolidation)

1. **Retire / Merge**: trình bày lý do chi tiết cho từng file trước khi xác nhận với người dùng:
   - Đã phát hiện vấn đề cụ thể nào (chồng lấn, lỗi thời, tham chiếu hỏng, v.v.)
   - Giải pháp thay thế nào đáp ứng cùng chức năng (với Retire: skill/rule hiện có nào; với Merge: file đích và nội dung cần tích hợp)
   - Tác động của việc loại bỏ (các skill phụ thuộc, tham chiếu trong MEMORY.md hoặc workflow bị ảnh hưởng)
2. **Improve**: trình bày các đề xuất cải thiện cụ thể kèm lý do:
   - Cần thay đổi gì và vì sao (ví dụ: "trim 430→200 lines because sections X/Y duplicate python-patterns")
   - Người dùng quyết định có thực hiện hay không
3. **Update**: trình bày nội dung đã cập nhật kèm các nguồn đã kiểm tra
4. Kiểm tra số dòng của MEMORY.md; đề xuất nén lại nếu >100 dòng

## Schema của file kết quả

`~/.claude/skills/skill-stocktake/results.json`:

**`evaluated_at`**: PHẢI được đặt bằng thời điểm UTC thực tế khi hoàn tất đánh giá.
Lấy qua Bash: `date -u +%Y-%m-%dT%H:%M:%SZ`. KHÔNG BAO GIỜ dùng giá trị xấp xỉ chỉ có ngày như `T00:00:00Z`.

```json
{
  "evaluated_at": "2026-02-21T10:00:00Z",
  "mode": "full",
  "batch_progress": {
    "total": 80,
    "evaluated": 80,
    "status": "completed"
  },
  "skills": {
    "~/.claude/skills/skill-name/SKILL.md": {
      "path": "~/.claude/skills/skill-name/SKILL.md",
      "verdict": "Keep",
      "reason": "Concrete, actionable, unique value for X workflow",
      "mtime": "2026-01-15T08:30:00Z"
    }
  }
}
```

## Ghi chú

- Việc đánh giá là mù (blind): cùng một checklist áp dụng cho mọi skill bất kể nguồn gốc (ECC, tự viết, tự động trích xuất)
- Các thao tác archive / xóa LUÔN LUÔN yêu cầu người dùng xác nhận tường minh
- Không phân nhánh verdict theo nguồn gốc của skill
