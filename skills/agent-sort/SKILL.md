---
name: agent-sort
description: Xây dựng kế hoạch cài đặt ECC có bằng chứng cho một repo cụ thể bằng cách phân loại skill, command, rule, hook và các phần bổ sung vào hai nhóm DAILY và LIBRARY thông qua các lượt review song song có nhận biết repo. Dùng khi cần cắt gọn ECC theo đúng những gì dự án thực sự cần thay vì nạp toàn bộ bundle.
metadata:
  origin: ECC
---

# Agent Sort

Dùng skill này khi một repo cần bề mặt ECC riêng cho dự án thay vì bản cài đặt đầy đủ mặc định.

Mục tiêu không phải là đoán xem cái gì "có vẻ hữu ích". Mục tiêu là phân loại các thành phần ECC dựa trên bằng chứng từ codebase thực tế.

## Khi nào dùng

- Một dự án chỉ cần một tập con của ECC và bản cài đầy đủ gây quá nhiều nhiễu
- Stack của repo đã rõ, nhưng không ai muốn tuyển chọn thủ công từng skill một
- Một team muốn có quyết định cài đặt lặp lại được, dựa trên bằng chứng grep thay vì ý kiến chủ quan
- Cần tách các bề mặt workflow hằng ngày luôn được nạp khỏi các bề mặt thư viện/tham khảo có thể tìm kiếm
- Một repo đã trôi sang bộ ngôn ngữ, rule hoặc hook sai và cần dọn dẹp

## Quy tắc bất di bất dịch

- Dùng repo hiện tại làm nguồn sự thật, không dùng sở thích chung chung
- Mọi quyết định DAILY phải trích dẫn bằng chứng cụ thể từ repo
- LIBRARY không có nghĩa là "xóa"; nó có nghĩa là "giữ để truy cập được mà không nạp theo mặc định"
- Không cài hook, rule hay script mà repo hiện tại không dùng được
- Ưu tiên các bề mặt gốc của ECC; không đưa vào hệ thống cài đặt thứ hai

## Đầu ra

Tạo các artifact sau theo thứ tự:

1. Danh mục DAILY
2. Danh mục LIBRARY
3. kế hoạch cài đặt
4. báo cáo xác minh
5. router `skill-library` tùy chọn nếu dự án muốn có

## Mô hình phân loại

Chỉ dùng hai nhóm:

- `DAILY`
  - nên được nạp ở mọi session cho repo này
  - khớp mạnh với ngôn ngữ, framework, workflow hoặc bề mặt vận hành của repo
- `LIBRARY`
  - hữu ích để giữ lại, nhưng không đáng nạp theo mặc định
  - nên vẫn truy cập được thông qua tìm kiếm, router skill hoặc dùng thủ công có chọn lọc

## Nguồn bằng chứng

Dùng bằng chứng cục bộ của repo trước khi đưa ra bất kỳ phân loại nào:

- phần mở rộng file
- package manager và lockfile
- cấu hình framework
- cấu hình CI và hook
- script build/test
- import và manifest dependency
- tài liệu repo mô tả tường minh stack

Các lệnh hữu ích gồm:

```bash
rg --files
rg -n "typescript|react|next|supabase|django|spring|flutter|swift"
cat package.json
cat pyproject.toml
cat Cargo.toml
cat pubspec.yaml
cat go.mod
```

## Các lượt review song song

Nếu có subagent song song, chia việc review thành các lượt sau:

1. Agents
   - phân loại `agents/*`
2. Skills
   - phân loại `skills/*`
3. Commands
   - phân loại `commands/*`
4. Rules
   - phân loại `rules/*`
5. Hooks và script
   - phân loại các bề mặt hook, kiểm tra tình trạng MCP, script trợ giúp và khả năng tương thích OS
6. Extras
   - phân loại context, ví dụ, cấu hình MCP, template và tài liệu hướng dẫn

Nếu không có subagent, hãy chạy tuần tự các lượt tương tự.

## Quy trình cốt lõi

### 1. Đọc repo

Xác lập stack thực sự trước khi phân loại bất cứ thứ gì:

- các ngôn ngữ đang dùng
- các framework đang dùng
- package manager chính
- test stack
- lint/format stack
- bề mặt deployment/runtime
- các tích hợp vận hành đã có sẵn

### 2. Xây bảng bằng chứng

Với mỗi bề mặt ứng viên, ghi lại:

- đường dẫn thành phần
- loại thành phần
- nhóm đề xuất
- bằng chứng từ repo
- lý giải ngắn gọn

Dùng định dạng này:

```text
skills/frontend-patterns | skill | DAILY | 84 .tsx files, next.config.ts present | core frontend stack
skills/django-patterns   | skill | LIBRARY | no .py files, no pyproject.toml       | not active in this repo
rules/typescript/*       | rules | DAILY | package.json + tsconfig.json            | active TS repo
rules/python/*           | rules | LIBRARY | zero Python source files             | keep accessible only
```

### 3. Quyết định DAILY hay LIBRARY

Nâng lên `DAILY` khi:

- repo rõ ràng dùng stack tương ứng
- thành phần đủ tổng quát để giúp ích mọi session
- repo đã phụ thuộc vào runtime hoặc workflow tương ứng

Hạ xuống `LIBRARY` khi:

- thành phần nằm ngoài stack
- repo có thể cần nó sau này, nhưng không phải hằng ngày
- nó làm tăng chi phí context mà không liên quan ngay lập tức

### 4. Xây kế hoạch cài đặt

Chuyển phân loại thành hành động:

- skill DAILY -> cài hoặc giữ trong `.claude/skills/`
- command DAILY -> chỉ giữ dưới dạng shim tường minh nếu vẫn còn hữu ích
- rule DAILY -> chỉ cài các bộ ngôn ngữ khớp
- hook/script DAILY -> chỉ giữ những cái tương thích
- bề mặt LIBRARY -> giữ truy cập được qua tìm kiếm hoặc `skill-library`

Nếu repo đã dùng cài đặt có chọn lọc, hãy cập nhật kế hoạch đó thay vì tạo một hệ thống khác.

### 5. Tạo library router tùy chọn

Nếu dự án muốn có bề mặt thư viện có thể tìm kiếm, hãy tạo:

- `.claude/skills/skill-library/SKILL.md`

Router đó nên chứa:

- giải thích ngắn gọn về DAILY so với LIBRARY
- các từ khóa kích hoạt được nhóm lại
- nơi các tham chiếu thư viện nằm

Không sao chép toàn bộ nội dung của mọi skill vào router.

### 6. Xác minh kết quả

Sau khi kế hoạch được áp dụng, hãy xác minh:

- mọi file DAILY tồn tại ở nơi kỳ vọng
- các rule ngôn ngữ lỗi thời không còn được để ở trạng thái hoạt động
- các hook không tương thích không được cài
- bản cài đặt kết quả thực sự khớp với stack của repo

Trả về một báo cáo gọn với:

- số lượng DAILY
- số lượng LIBRARY
- các bề mặt lỗi thời đã gỡ bỏ
- các câu hỏi còn mở

## Chuyển giao (Handoff)

Nếu bước tiếp theo là cài đặt tương tác hoặc sửa chữa, hãy chuyển giao cho:

- `configure-ecc`

Nếu bước tiếp theo là dọn dẹp chồng chéo hoặc review danh mục, hãy chuyển giao cho:

- `skill-stocktake`

Nếu bước tiếp theo là cắt gọn context rộng hơn, hãy chuyển giao cho:

- `strategic-compact`

## Định dạng đầu ra

Trả về kết quả theo thứ tự này:

```text
STACK
- language/framework/runtime summary

DAILY
- always-loaded items with evidence

LIBRARY
- searchable/reference items with evidence

INSTALL PLAN
- what should be installed, removed, or routed

VERIFICATION
- checks run and remaining gaps
```
