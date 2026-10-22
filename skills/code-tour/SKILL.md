---
name: code-tour
description: Tạo các file CodeTour `.tour` — walkthrough từng bước hướng theo persona, với anchor file và dòng thực tế. Dùng cho onboarding tour, architecture walkthrough, PR tour, RCA tour và các yêu cầu có cấu trúc kiểu "explain how this works". Dùng khi người dùng yêu cầu code tour, onboarding walkthrough, PR tour, hoặc giải thích cách một subsystem hoạt động.
metadata:
  origin: ECC
---

# Code Tour

Tạo các file **CodeTour** `.tour` cho các walkthrough codebase, mở thẳng tới file và khoảng dòng thực tế. Tour nằm trong `.tours/` và dành cho định dạng CodeTour, không phải ghi chú Markdown ad hoc.

Một tour tốt là một câu chuyện dành cho một người đọc cụ thể:
- họ đang nhìn vào cái gì
- tại sao nó quan trọng
- họ nên đi theo con đường nào tiếp theo

Chỉ tạo file JSON `.tour`. Không sửa source code như một phần của skill này.

## Khi nào dùng

Dùng skill này khi:
- người dùng yêu cầu code tour, onboarding tour, architecture walkthrough hoặc PR tour
- người dùng nói "explain how X works" và muốn một artifact hướng dẫn có thể tái sử dụng
- người dùng muốn một lộ trình ramp-up cho kỹ sư hoặc reviewer mới
- tác vụ phù hợp với một chuỗi hướng dẫn hơn là một bản tóm tắt phẳng

Ví dụ:
- onboarding một maintainer mới
- architecture tour cho một service hoặc package
- PR-review walk-through bám theo các file đã thay đổi
- RCA tour cho thấy đường dẫn xảy ra lỗi
- security review tour về các trust boundary và các điểm kiểm tra chính

## Khi nào KHÔNG dùng

| Thay vì code-tour | Dùng |
| --- | --- |
| Một lời giải thích một lần trong chat là đủ | trả lời trực tiếp |
| Người dùng muốn tài liệu dạng văn xuôi, không phải artifact `.tour` | `documentation-lookup` hoặc chỉnh sửa docs của repo |
| Tác vụ là triển khai hoặc refactor | thực hiện công việc triển khai |
| Tác vụ là onboarding codebase tổng quát mà không cần artifact tour | `codebase-onboarding` |

## Workflow

### 1. Khám phá (Discover)

Khám phá repo trước khi viết bất cứ thứ gì:
- README và các entry point của package/app
- cấu trúc thư mục
- các file config liên quan
- các file đã thay đổi nếu tour tập trung vào PR

Không bắt đầu viết các bước trước khi bạn hiểu hình dạng của code.

### 2. Suy ra người đọc

Quyết định persona và độ sâu từ yêu cầu.

| Dạng yêu cầu | Persona | Độ sâu đề xuất |
| --- | --- | --- |
| "onboarding", "new joiner" | `new-joiner` | 9-13 bước |
| "quick tour", "vibe check" | `vibecoder` | 5-8 bước |
| "architecture" | `architect` | 14-18 bước |
| "tour this PR" | `pr-reviewer` | 7-11 bước |
| "why did this break" | `rca-investigator` | 7-11 bước |
| "security review" | `security-reviewer` | 7-11 bước |
| "explain how this feature works" | `feature-explainer` | 7-11 bước |
| "debug this path" | `bug-fixer` | 7-11 bước |

### 3. Đọc và xác minh anchor

Mọi đường dẫn file và anchor dòng phải là thật:
- xác nhận file tồn tại
- xác nhận số dòng nằm trong phạm vi
- nếu dùng selection, xác minh đúng block đó
- nếu file hay thay đổi, ưu tiên anchor dựa trên pattern

KHÔNG BAO GIỜ đoán số dòng.

### 4. Viết file `.tour`

Ghi vào:

```text
.tours/<persona>-<focus>.tour
```

Giữ đường dẫn có tính xác định và dễ đọc.

### 5. Xác thực (Validate)

Trước khi kết thúc:
- mọi đường dẫn được tham chiếu đều tồn tại
- mọi dòng hoặc selection đều hợp lệ
- bước đầu tiên được anchor vào một file hoặc thư mục thật
- `ref` trỏ tới một branch hoặc commit thực sự có mọi file mà tour tham chiếu (xem bên dưới)
- tour kể một câu chuyện mạch lạc thay vì chỉ liệt kê file

## Trường `ref`

`ref` gắn tour với một git branch hoặc commit. Nó quan trọng hơn vẻ bề ngoài: khi `ref` không phải là branch mà người đọc đang checkout, CodeTour mở file của mỗi bước từ revision đó trong git, chứ không phải từ file trên đĩa. Nếu một file không có trong revision đó, bước sẽ không mở được — người đọc thấy *"The editor could not be opened because the file was not found"* dù file đang nằm ngay đó. Tour và các comment của nó vẫn hiển thị, nên nguyên nhân thật rất dễ bị bỏ sót.

Chọn `ref` theo loại tour:

| Loại tour | Đặt `ref` thành |
| --- | --- |
| PR tour | branch của PR — KHÔNG BAO GIỜ là base branch |
| Onboarding / architecture | branch mà người đọc sẽ đang dùng (thường là `main`), hoặc bỏ qua |
| Không chắc | bỏ `ref`, để CodeTour đọc file trực tiếp từ đĩa |

Trường hợp PR là cái bẫy thường gặp: một PR thường thêm file mới, và file mới chưa tồn tại trên base branch. Trỏ `ref` vào base (ví dụ `develop`) thì mọi bước trên file mới đều không mở được.

Trước khi kết thúc, xác nhận file của mỗi bước thực sự tồn tại tại `ref` bạn đã chọn.

## Các loại bước (Step Types)

### Content

Dùng tiết kiệm, thường chỉ cho bước kết thúc:

```json
{ "title": "Next Steps", "description": "You can now trace the request path end to end." }
```

Không làm bước đầu tiên chỉ có content.

### Directory

Dùng để định hướng người đọc tới một module:

```json
{ "directory": "src/services", "title": "Service Layer", "description": "The core orchestration logic lives here." }
```

### File + line

Đây là loại bước mặc định:

```json
{ "file": "src/auth/middleware.ts", "line": 42, "title": "Auth Gate", "description": "Every protected request passes here first." }
```

### Selection

Dùng khi một block code quan trọng hơn cả file:

```json
{
  "file": "src/core/pipeline.ts",
  "selection": {
    "start": { "line": 15, "character": 0 },
    "end": { "line": 34, "character": 0 }
  },
  "title": "Request Pipeline",
  "description": "This block wires validation, auth, and downstream execution."
}
```

### Pattern

Dùng khi số dòng chính xác có thể bị lệch:

```json
{ "file": "src/app.ts", "pattern": "export default class App", "title": "Application Entry" }
```

### URI

Dùng cho PR, issue hoặc docs khi hữu ích:

```json
{ "uri": "https://github.com/org/repo/pull/456", "title": "The PR" }
```

## Quy tắc viết: SMIG

Mỗi description nên trả lời:
- **Situation (Tình huống)**: người đọc đang nhìn vào cái gì
- **Mechanism (Cơ chế)**: nó hoạt động như thế nào
- **Implication (Hệ quả)**: tại sao nó quan trọng với persona này
- **Gotcha (Điểm dễ vấp)**: điều mà một người đọc thông minh có thể bỏ sót

Giữ description gọn, cụ thể, và bám sát code thực tế.

## Cấu trúc tự sự

Dùng mạch này trừ khi tác vụ rõ ràng cần thứ khác:
1. định hướng
2. bản đồ module
3. đường thực thi cốt lõi
4. edge case hoặc gotcha
5. kết thúc / bước tiếp theo

Tour nên giống một con đường, không phải một bản kiểm kê.

## Ví dụ

```json
{
  "$schema": "https://aka.ms/codetour-schema",
  "title": "API Service Tour",
  "description": "Walkthrough of the request path for the payments service.",
  "ref": "main",
  "steps": [
    {
      "directory": "src",
      "title": "Source Root",
      "description": "All runtime code for the service starts here."
    },
    {
      "file": "src/server.ts",
      "line": 12,
      "title": "Entry Point",
      "description": "The server boots here and wires middleware before any route is reached."
    },
    {
      "file": "src/routes/payments.ts",
      "line": 8,
      "title": "Payment Routes",
      "description": "Every payments request enters through this router before hitting service logic."
    },
    {
      "title": "Next Steps",
      "description": "You can now follow any payment request end to end with the main anchors in place."
    }
  ]
}
```

## Anti-Pattern

| Anti-pattern | Cách sửa |
| --- | --- |
| Liệt kê file phẳng | Kể một câu chuyện với sự phụ thuộc giữa các bước |
| Description chung chung | Nêu tên đường code hoặc pattern cụ thể |
| Anchor đoán mò | Xác minh mọi file và dòng trước |
| Quá nhiều bước cho một quick tour | Cắt mạnh tay |
| Bước đầu tiên chỉ có content | Anchor bước đầu tiên vào một file hoặc thư mục thật |
| Persona không khớp | Viết cho người đọc thực tế, không phải một kỹ sư chung chung |

## Best Practice

- giữ số bước tương xứng với kích thước repo và độ sâu của persona
- dùng directory step để định hướng, file step cho phần nội dung chính
- với PR tour, bao quát các file đã thay đổi trước
- với monorepo, giới hạn phạm vi vào các package liên quan thay vì tour mọi thứ
- kết thúc bằng những gì người đọc giờ có thể làm, không phải một bản recap

## Skill liên quan

- `codebase-onboarding`
- `coding-standards`
- `council`
- định dạng upstream chính thức: `microsoft/codetour`
