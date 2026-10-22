---
description: Chạy audit harness của repo một cách xác định (deterministic) và trả về scorecard có ưu tiên. Dùng để có scorecard tổng thể xác định về mức độ sẵn sàng của repo; với audit chuyên về bảo mật hãy dùng command security-scan.
---

# Lệnh Harness Audit

Chạy audit harness của repo một cách xác định và trả về scorecard có ưu tiên.

## Cách dùng

`/harness-audit [scope] [--format text|json] [--root path]`

- `scope` (tùy chọn): `repo` (mặc định), `hooks`, `skills`, `commands`, `agents`
- `--format`: kiểu output (`text` mặc định, `json` cho tự động hóa)
- `--root`: audit một đường dẫn cụ thể thay vì thư mục làm việc hiện tại

## Engine xác định

Luôn chạy:

```bash
node scripts/harness-audit.js <scope> --format <text|json> [--root <path>]
```

Script này là nguồn sự thật cho việc chấm điểm và kiểm tra. Không bịa thêm tiêu chí hay điểm ad-hoc.

Phiên bản rubric: `2026-05-19`.

Script tính tối đa 12 nhóm cố định (mỗi nhóm chuẩn hóa `0-10`). Bảy nhóm đầu luôn áp dụng; GitHub Integration luôn áp dụng; các nhóm theo deploy target chỉ áp dụng khi phát hiện marker tương ứng.

1. Tool Coverage
2. Context Efficiency
3. Quality Gates
4. Memory Persistence
5. Eval Coverage
6. Security Guardrails
7. Cost Efficiency
8. GitHub Integration
9. Vercel Integration *(khi có `vercel.json` hoặc `.vercel/`)*
10. Netlify Integration *(khi có `netlify.toml` hoặc `.netlify/`)*
11. Cloudflare Integration *(khi có `wrangler.toml` hoặc `wrangler.jsonc`)*
12. Fly Integration *(khi có `fly.toml`)*

Điểm số được suy ra từ các kiểm tra file/rule tường minh và có thể tái lập cho cùng một commit.
Script mặc định audit thư mục làm việc hiện tại và tự động phát hiện đích là chính repo ECC hay một dự án consumer đang dùng ECC.

## Hợp đồng output

Trả về:

1. `overall_score` trên `max_score`. `max_score` phụ thuộc vào các nhóm áp dụng cho đích; không bao giờ giả định một tổng cố định.
2. `applicable_categories[]` và `category_count` mô tả những nhóm nào đã đóng góp.
3. Điểm từng nhóm và các phát hiện cụ thể.
4. Các kiểm tra thất bại kèm đường dẫn file chính xác.
5. Top 3 hành động từ output xác định (`top_actions`).
6. Các skill ECC đề xuất áp dụng tiếp theo.

## Checklist

- Dùng trực tiếp output của script; không tự chấm lại thủ công.
- Nếu yêu cầu `--format json`, trả về JSON của script không thay đổi.
- Nếu yêu cầu text, tóm tắt các kiểm tra thất bại và top action.
- Bao gồm đường dẫn file chính xác từ `checks[]` và `top_actions[]`.

## Kết quả ví dụ

```text
Harness Audit (repo, repo): 71/80
- Tool Coverage: 10/10 (10/10 pts)
- Context Efficiency: 9/10 (9/10 pts)
- Quality Gates: 10/10 (10/10 pts)
- GitHub Integration: 2/10 (2/10 pts)

Top 3 Actions:
1) [GitHub Integration] Add at least one workflow under .github/workflows/. (.github/workflows/)
2) [Security Guardrails] Add prompt/tool preflight security guards in hooks/hooks.json. (hooks/hooks.json)
3) [Eval Coverage] Increase automated test coverage across scripts/hooks/lib. (tests/)
```

## Đối số

$ARGUMENTS:
- `repo|hooks|skills|commands|agents` (scope tùy chọn)
- `--format text|json` (kiểu output tùy chọn)
