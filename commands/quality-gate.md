---
description: Chạy quality gate formatter của ECC cho một file đơn lẻ và báo cáo các bước khắc phục.
---

# Lệnh Quality Gate

Điểm vào dành cho operator của quality gate formatter, vốn thường chạy dưới dạng
hook PostToolUse `post:quality-gate` (`scripts/hooks/quality-gate.js`).

## Cách hoạt động thực tế

Gate là một bước kiểm tra formatter trên một file đơn lẻ, được điều khiển bởi đầu vào của hook, không phải bởi CLI flag:

- Script đọc mục tiêu từ JSON stdin của hook
  (`tool_input.file_path`); nó không nhận đối số đường dẫn.
- Các công tắc hành vi là biến môi trường:
  - `ECC_QUALITY_GATE_FIX=true` - áp dụng sửa định dạng thay vì chỉ kiểm tra
  - `ECC_QUALITY_GATE_STRICT=true` - ghi log lỗi formatter như là lỗi của gate
- Phạm vi theo loại file:
  - `.ts/.tsx/.js/.jsx/.json/.md` - Biome `check` hoặc Prettier `--check`,
    tùy cái nào project có (JS/TS dùng Biome sẽ bị bỏ qua ở đây vì
    `post-edit-format` đã chạy `biome check --write`)
  - `.go` - `gofmt`
  - `.py` - `ruff format`
- Kiểm tra lint và type không thuộc gate này. Hãy dùng skill `verification-loop`
  hoặc các skill verification theo ngôn ngữ cho pipeline lint/type/test.

## Cách dùng

Để chạy gate thủ công trên một file, hãy pipe JSON kiểu hook vào
script (đặt các công tắc env trước nếu bạn muốn hành vi fix hoặc strict):

```bash
echo '{"tool_input":{"file_path":"src/example.ts"}}' \
  | ECC_QUALITY_GATE_FIX=true node scripts/hooks/quality-gate.js
```

Sau đó báo cáo các phát hiện của formatter và các bước khắc phục cụ thể.

## Ghi chú

Việc nối hook đi vào qua dispatcher PostToolUse bất đồng bộ trong
`hooks/hooks.json`. Registry nội bộ của nó giữ nguyên ID `post:quality-gate`
và các profile `standard`/`strict`.

## Đối số

$ARGUMENTS:

- `[path]` file tùy chọn cần kiểm tra. Bản thân script không nhận CLI
  argument - khi có đường dẫn, hãy thay nó vào `tool_input.file_path`
  trong JSON stdin ở trên trước khi chạy lệnh
