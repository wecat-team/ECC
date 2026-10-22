---
description: Chạy AgentShield trên các bề mặt agent, hook, MCP, permission và secret. Đây là điểm vào dạng slash-command cho lượt audit đó; hãy ưu tiên skill security-scan cho cùng lượt audit AgentShield trong hội thoại.
agent: ecc:security-reviewer
subtask: true
---

# Lệnh Security Scan

Chạy AgentShield trên project hiện tại hoặc một đường dẫn đích, sau đó biến các phát hiện thành kế hoạch khắc phục có thứ tự ưu tiên.

## Cách dùng

`/security-scan [path] [--format text|json|markdown|html] [--min-severity low|medium|high|critical] [--fix]`

- `path` (tùy chọn): mặc định là project hiện tại. Dùng đường dẫn `.claude/`, root của repo, hoặc thư mục template đã được check in.
- `--format`: định dạng đầu ra. Dùng `json` cho CI, `markdown` cho bàn giao, và `html` cho báo cáo review độc lập.
- `--min-severity`: lọc các phát hiện có mức ưu tiên thấp hơn.
- `--fix`: chỉ áp dụng các bản sửa của AgentShield được đánh dấu rõ ràng là an toàn và có thể tự động sửa.

## Engine xác định (Deterministic Engine)

Ưu tiên scanner đã đóng gói:

```bash
npx ecc-agentshield scan --path "${TARGET_PATH:-.}" --format text
```

Với việc phát triển AgentShield cục bộ, chạy từ bản checkout của AgentShield:

```bash
npm run scan -- --path "${TARGET_PATH:-.}" --format text
```

Không tự bịa ra phát hiện. Dùng đầu ra của AgentShield làm nguồn sự thật và tách biệt các sự kiện từ scanner với nhận định tiếp theo.

## Checklist review

1. Xác định trước các phát hiện runtime đang hoạt động:
   - secret hardcode
   - permission quá rộng
   - hook có thể thực thi
   - MCP server có shell, filesystem, transport từ xa, hoặc `npx` không pin phiên bản
   - prompt của agent xử lý nội dung không tin cậy mà không có biện pháp phòng vệ
2. Tách riêng phần inventory có độ tin cậy thấp hơn:
   - ví dụ trong tài liệu
   - ví dụ trong template
   - plugin manifest
   - cài đặt tùy chọn cục bộ của project
3. Với mỗi phát hiện critical hoặc high, trả về:
   - đường dẫn file
   - mức độ nghiêm trọng
   - độ tin cậy runtime
   - vì sao nó quan trọng
   - cách khắc phục chính xác
   - có an toàn để tự động sửa hay không
4. Nếu `--fix` được yêu cầu, nêu các chỉnh sửa dự kiến trước khi áp dụng bản sửa.
5. Chạy lại scan sau khi sửa và báo cáo điểm trước/sau.

## Hợp đồng đầu ra (Output Contract)

Trả về:

1. Xếp hạng và điểm bảo mật.
2. Số lượng theo mức độ nghiêm trọng và độ tin cậy runtime.
3. Các phát hiện critical/high kèm đường dẫn chính xác.
4. Các phát hiện có độ tin cậy thấp hơn, nhóm riêng.
5. Thứ tự khắc phục.
6. Các lệnh đã chạy và việc scan là cục bộ, CI, hay dùng npx.

## Pattern CI

Dùng AgentShield trong GitHub Actions để có các gate bắt buộc:

```yaml
- uses: affaan-m/agentshield@v1
  with:
    path: "."
    min-severity: "medium"
    fail-on-findings: true
```

## Liên kết

- Skill: `skills/security-scan/SKILL.md`
- Agent: `agents/security-reviewer.md`
- Scanner: <https://github.com/affaan-m/agentshield>

## Đối số

$ARGUMENTS:
- đường dẫn đích tùy chọn
- các flag AgentShield tùy chọn
