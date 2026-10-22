---
name: ecc-recipes
description: "Ánh xạ một workflow được mô tả tới nhóm lệnh ECC phù hợp kèm thứ tự chạy và điều kiện dừng, hoặc duyệt toàn bộ các họ recipe nhóm lệnh được đọc trực tiếp từ thư mục commands. Chỉ mang tính tư vấn — không bao giờ thực thi. Dùng khi được hỏi lệnh nào chạy một workflow, chuỗi lệnh cho một task, hoặc để liệt kê các pipeline của ECC; không dùng để thực thi task (hãy chuyển tới chính command đó), tài liệu một command đơn lẻ (dùng ecc-guide), hoặc viết lại prompt (dùng prompt-optimizer)."
argument-hint: <mô tả workflow | để trống=liệt kê tất cả>
origin: community
author: KyawZinLatt
metadata:
  version: "1.0.0"
---

# ECC Recipes

Một điểm vào duy nhất cho câu hỏi "nhóm slash-command ECC nào chạy workflow của tôi, theo
thứ tự nào, và khi nào thì dừng." Đồng thời cho phép duyệt mọi họ recipe nhóm lệnh.

Lấp khoảng trống giữa hai skill hiện có:

- `ecc-guide` — liệt kê command và nơi đọc tài liệu, nhưng dưới dạng catalog phẳng.
- `prompt-optimizer` — ghép task với các component, nhưng chỉ xuất ra một prompt đơn,
  không phải một nhóm nhiều command có thứ tự chạy và điều kiện dừng.

Skill này bổ sung: **gom họ (family) + thứ tự chạy + điều kiện dừng.**

## Khi nào kích hoạt

- "Which command group do I run for <workflow>?"
- "What's the command sequence to build an MVP / fix a defect / refactor?"
- "Show me all ECC command-group recipes" (chế độ catalog)
- "How many workflow pipelines does ECC have?"
- Người dùng gọi `/ecc-recipes` có hoặc không kèm mô tả.

### Không dùng khi

- Người dùng muốn task được làm ngay — hãy chuyển tới command thực sự, đừng mô tả nó.
- Người dùng muốn tài liệu chuyên sâu cho MỘT command — dùng `ecc-guide`.
- Người dùng muốn viết lại một prompt nháp — dùng `prompt-optimizer`.

## Nguyên tắc cốt lõi

**Trả lời từ các file hiện tại, không từ trí nhớ.** Tập command thay đổi; không bao giờ
ghi cứng số lượng hay danh sách thành viên. Hãy đọc trực tiếp thư mục `commands/` mỗi lần chạy,
rồi mới phân loại thành các họ.

### Đọc trực tiếp (live read)

Xác định thư mục commands (thư mục đầu tiên tồn tại), rồi liệt kê tên:

```bash
for D in \
  "$HOME"/.claude/plugins/marketplaces/ecc/commands \
  "$HOME"/.claude/plugins/cache/ecc/ecc/*/commands \
  ./commands \
  ./.claude/commands \
  "$HOME"/.claude/commands; do
  [ -d "$D" ] && CMD_DIR="$D" && break
done
[ -z "${CMD_DIR:-}" ] && { echo "No ECC commands directory found."; return 1; }
find "$CMD_DIR" -maxdepth 1 -name '*.md' -exec basename {} .md \; | sort
```

Có thể đọc thêm `manifests/install-*.json` nếu có để gom nhóm phong phú hơn. Chỉ dùng
tập đọc nhỏ nhất cần thiết.

## Phân loại họ (theo tiền tố)

Gom tên command theo tiền tố đứng đầu; ánh xạ các command đơn lẻ đã biết bằng tay. Các họ được
suy ra trực tiếp — bảng dưới đây là *quy tắc phân loại*, không phải danh sách cố định.

| Tiền tố họ | Ý nghĩa recipe | Thứ tự chạy điển hình |
|---|---|---|
| `orch-*` | Research, Plan, TDD, Review, Commit có kiểm soát theo từng loại task | chọn một orch-* theo loại task; nó tự chạy các giai đoạn nội bộ của mình |
| `multi-*` | workflow đa mô hình | `multi-plan` rồi `multi-execute` rồi review (hoặc `multi-workflow` từ đầu đến cuối) |
| `prp-*` | pipeline từ PRD sang plan sang implement sang PR | `prp-prd` rồi `prp-plan` rồi `prp-implement` rồi `prp-commit` rồi `prp-pr` |
| `epic-*` | epic lớn nhiều đơn vị, song song | `epic-decompose` rồi `epic-claim` rồi `epic-validate` rồi `epic-review` rồi `epic-unblock` rồi `epic-sync` rồi `epic-publish` |
| `loop-*` | vòng lặp tự trị được quản lý và monitor | `loop-start <pattern>` rồi theo dõi bằng `loop-status` |
| `gan-*` | vòng lặp generator và evaluator | `gan-build` (code) hoặc `gan-design` (UI); tự lặp |
| `*-build` / `*-review` / `*-test` | bộ ba CI theo từng ngôn ngữ | `<lang>-test` (TDD) rồi `<lang>-build` (fix) rồi `<lang>-review` |
| `hookify-*` | quản lý hook hành vi | `hookify` rồi `hookify-list` rồi `hookify-configure` |
| `learn` / `instinct-*` / `evolve` / `promote` / `prune` | học liên tục | `learn` rồi `instinct-status` rồi `evolve` rồi `promote` |
| singletons | `santa-loop`, `plan`, `plan-prd`, `pr`, `code-review`, `checkpoint`, v.v. | đứng riêng hoặc làm chất kết nối giữa các nhóm |

Command nào không khớp quy tắc tiền tố → liệt kê dưới **singletons** kèm mô tả
một dòng của nó.

## Cách hoạt động

```
1. Live-read command names from CMD_DIR.
2. Classify into families by prefix and a singleton map.
3. If a workflow description was given -> MATCH MODE.
   If none -> CATALOG MODE.
4. Advisory only: print the plan. Never run the matched commands.
```

### Chế độ catalog (không có mô tả)

Xuất bảng các họ: mỗi họ, số lượng thành viên, các thành viên, ý nghĩa một dòng,
thứ tự chạy điển hình. Kết thúc bằng tổng số command và lời nhắc hãy mô tả một
workflow để nhận recipe khớp.

### Chế độ match (có mô tả)

1. Diễn đạt lại workflow trong một câu.
2. Chọn 1-2 họ phù hợp nhất; nói VÌ SAO trong một dòng cho mỗi họ.
3. **Khối thứ tự chạy** — chuỗi command chính xác cho họ khớp.
4. **Điều kiện dừng** — luôn tường minh (max-runs, completion-signal,
   review-passes, hoặc single-shot). Với các vòng lặp tự trị, hãy cảnh báo về việc
   đốt subscription và đề xuất một giới hạn dự phòng (backstop).
5. **Nơi đọc thêm** — đường dẫn `commands/<name>.md` cùng `/ecc-guide <name>`.

## Mẫu đầu ra (chế độ match)

```
Workflow: <one-sentence restatement>

Best fit: <family> — <why>
(Alt: <family> — <why>)

Run-order:
  /<cmd1>   # job
  /<cmd2>   # job
  /<cmd3>   # job
  STOP when: <condition>
  WARNING (autonomous loops only): an unbounded loop burns subscription/credits —
  add a max-iteration or max-cost backstop alongside the completion signal.

Read full docs:
  commands/<cmd1>.md   (or: /ecc-guide <cmd1>)
```

## Ví dụ

**Catalog:** `/ecc-recipes` → in bảng các họ và tổng số lượng.

**Match:** `/ecc-recipes plan a whole app upfront then auto-build with adversarial
review until done` → Phù hợp nhất: `loop-*` (tự trị) bao quanh `gan-*` hoặc
`santa-loop` (đối kháng). Thứ tự chạy: `plan-prd` rồi
`loop-start rfc-dag --mode safe` rồi theo dõi `loop-status`; DỪNG khi mọi đơn vị
vượt qua review N lần liên tiếp (thêm backstop max-iteration để giới hạn mức đốt).

**Match:** `/ecc-recipes fix a bug in my Go service` → Phù hợp nhất: `orch-fix-defect`
(tái hiện, sửa, review, commit). Thay thế: `go-test` rồi `go-build` rồi
`go-review`. DỪNG: regression test xanh và review đạt.

## Ngoài phạm vi (Non-Goals)

- Không phải bộ thực thi — chỉ tư vấn.
- Không phải tài liệu chuyên sâu theo từng command — đó là việc của `ecc-guide`.
- Không viết lại prompt — đó là việc của `prompt-optimizer`.
- Không bao giờ ghi cứng số lượng command hay danh sách thành viên — luôn đọc trực tiếp.
