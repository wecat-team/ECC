---
name: instinct-export
description: Export các instinct từ phạm vi project/global ra một file
command: /instinct-export
---

# Lệnh Instinct Export

Export các instinct sang định dạng có thể chia sẻ. Rất phù hợp để:
- Chia sẻ với đồng đội
- Chuyển sang máy mới
- Đóng góp vào quy ước của dự án

## Cách dùng

```
/instinct-export                           # Export all personal instincts
/instinct-export --domain testing          # Export only testing instincts
/instinct-export --min-confidence 0.7      # Only export high-confidence instincts
/instinct-export --output team-instincts.yaml
/instinct-export --scope project --output project-instincts.yaml
```

## Cần làm gì

1. Phát hiện context dự án hiện tại
2. Nạp instinct theo phạm vi được chọn:
   - `project`: chỉ dự án hiện tại
   - `global`: chỉ global
   - `all`: gộp project + global (mặc định)
3. Áp dụng các bộ lọc (`--domain`, `--min-confidence`)
4. Ghi export dạng YAML ra file (hoặc stdout nếu không cung cấp đường dẫn output)

## Định dạng output

Tạo một file YAML:

```yaml
# Instincts Export
# Generated: 2025-01-22
# Source: personal
# Count: 12 instincts

---
id: prefer-functional-style
trigger: "when writing new functions"
confidence: 0.8
domain: code-style
source: session-observation
scope: project
project_id: a1b2c3d4e5f6
project_name: my-app
---

# Prefer Functional Style

## Action
Use functional patterns over classes.
```

## Flag

- `--domain <name>`: Chỉ export domain được chỉ định
- `--min-confidence <n>`: Ngưỡng độ tin cậy tối thiểu
- `--output <file>`: Đường dẫn file output (in ra stdout nếu bỏ qua)
- `--scope <project|global|all>`: Phạm vi export (mặc định: `all`)
