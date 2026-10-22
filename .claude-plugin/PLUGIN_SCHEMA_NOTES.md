# Ghi chú về Schema của Plugin Manifest

Tài liệu này ghi lại **các ràng buộc không được tài liệu hóa nhưng vẫn được áp dụng** của validator manifest plugin Claude Code.

Các quy tắc này dựa trên những lần cài đặt thất bại thực tế, hành vi của validator và so sánh với các plugin đã hoạt động tốt.
Chúng tồn tại để ngăn lỗi âm thầm và các regression lặp đi lặp lại.

Nếu bạn sửa `.claude-plugin/plugin.json`, hãy đọc tài liệu này trước.

---

## Tóm tắt (Đọc phần này trước)

Validator manifest plugin Claude **rất nghiêm ngặt và có chủ kiến riêng**.
Nó áp dụng những quy tắc chưa được mô tả đầy đủ trong các tài liệu schema công khai.

Kiểu lỗi phổ biến nhất là:

> Manifest trông hợp lý, nhưng validator từ chối với các lỗi mơ hồ như
> `agents: Invalid input`

Tài liệu này giải thích lý do.

---

## Các trường bắt buộc

### `version` (BẮT BUỘC)

Trường `version` là bắt buộc đối với validator, kể cả khi một số ví dụ bỏ qua nó.

Nếu thiếu, việc cài đặt có thể thất bại khi cài từ marketplace hoặc khi CLI validate.

Ví dụ:

```json
{
  "version": "1.1.0"
}
```

---

## Quy tắc về kiểu dữ liệu của trường

Các trường sau **luôn phải là mảng**:

* `commands`
* `skills`
* `hooks` (nếu có)

Ngay cả khi chỉ có một mục, **chuỗi (string) không được chấp nhận**.

Quy tắc này áp dụng nhất quán cho mọi trường đường dẫn của component.

---

## Frontmatter `tools` của Agent: DÙNG SCALAR

Quy tắc mảng ở trên áp dụng cho `plugin.json`, không áp dụng cho frontmatter Markdown của agent.
Các file agent của Claude Code dùng một scalar phân tách bằng dấu phẩy cho danh sách tool được phép:

```yaml
tools: Read, Glob, Grep
```

Không dùng YAML sequence như `tools: [Read, Glob, Grep]`. Bỏ qua trường
`tools` sẽ cấp cho agent quyền truy cập mọi tool, nhưng các agent của ECC khai báo
allowlist tường minh và validator của repo yêu cầu trường này.

---

## Trường `agents`: KHÔNG ĐƯỢC THÊM

> CẢNH BÁO: **QUAN TRỌNG:** KHÔNG thêm trường `"agents"` vào `plugin.json`. Validator plugin của Claude Code từ chối hoàn toàn trường này.

### Vì sao điều này quan trọng

Trường `agents` không thuộc schema manifest plugin của Claude Code. Mọi dạng của nó -- đường dẫn dạng chuỗi, mảng đường dẫn hoặc mảng thư mục -- đều gây lỗi validation:

```
agents: Invalid input
```

Các file `.md` của agent trong `agents/` được phát hiện tự động theo quy ước (tương tự hooks). Không cần khai báo chúng trong manifest.

### Lịch sử

Trước đây repo này liệt kê agent tường minh trong `plugin.json` dưới dạng mảng các đường dẫn file. Cách đó vượt qua schema của chính repo nhưng thất bại với validator thực tế của Claude Code, vốn không nhận ra trường này. Đã gỡ bỏ trong #1459.

---

## Quy tắc phân giải đường dẫn

### Commands và Skills

* `commands` và `skills` chỉ chấp nhận đường dẫn thư mục **khi được bọc trong mảng**
* Đường dẫn file tường minh là an toàn nhất và bền vững nhất về lâu dài

---

## Ghi chú về hành vi của Validator

* `claude plugin validate` nghiêm ngặt hơn một số bản xem trước của marketplace
* Validation có thể qua ở local nhưng thất bại khi cài đặt nếu đường dẫn mơ hồ
* Lỗi thường chung chung (`Invalid input`) và không chỉ ra nguyên nhân gốc
* Cài đặt đa nền tảng (đặc biệt là Windows) ít khoan dung hơn với các giả định về đường dẫn

Hãy coi validator là kẻ thù và hiểu theo nghĩa đen.

---

## Trường `hooks`: KHÔNG ĐƯỢC THÊM

> CẢNH BÁO: **QUAN TRỌNG:** KHÔNG thêm trường `"hooks"` vào `plugin.json`. Điều này được thực thi bằng một regression test.

### Vì sao điều này quan trọng

Claude Code v2.1+ **tự động tải** `hooks/hooks.json` từ mọi plugin đã cài theo quy ước. Nếu bạn cũng khai báo nó trong `plugin.json`, bạn sẽ gặp:

```
Duplicate hooks file detected: ./hooks/hooks.json resolves to already-loaded file.
The standard hooks/hooks.json is loaded automatically, so manifest.hooks should
only reference additional hook files.
```

### Lịch sử qua lại (Flip-Flop)

Điều này đã gây ra nhiều chu kỳ fix/revert lặp lại trong repo này:

| Commit | Hành động | Nguyên nhân |
|--------|--------|---------|
| `22ad036` | THÊM hooks | Người dùng báo "hooks không được tải" |
| `a7bc5f2` | GỠ hooks | Người dùng báo "lỗi trùng hooks" (#52) |
| `779085e` | THÊM hooks | Người dùng báo "agents không được tải" (#88) |
| `e3a1306` | GỠ hooks | Người dùng báo "lỗi trùng hooks" (#103) |

**Nguyên nhân gốc:** CLI của Claude Code thay đổi hành vi giữa các phiên bản:
- Trước v2.1: Yêu cầu khai báo `hooks` tường minh
- v2.1+: Tự động tải theo quy ước, báo lỗi nếu trùng

### Quy tắc hiện tại (được thực thi bằng test)

Test `plugin.json does NOT have explicit hooks declaration` trong `tests/hooks/hooks.test.js` ngăn việc đưa lại khai báo này.

**Nếu bạn thêm các file hook bổ sung** (không phải `hooks/hooks.json`), những file đó CÓ THỂ được khai báo. Nhưng `hooks/hooks.json` chuẩn thì KHÔNG ĐƯỢC khai báo.

---

## Trường `mcpServers`: Giữ lại opt-out rỗng

ECC giữ `.mcp.json` ở root repo cho việc cài plugin Codex và thiết lập MCP thủ công.
Claude Code cũng tự động phát hiện các file `.mcp.json` ở root plugin theo quy ước, điều này sẽ đóng gói cùng các MCP server đó vào các bản cài plugin Claude.
Slug plugin Claude được cố ý đặt ngắn (`ecc`), nhưng opt-out này vẫn cần thiết vì các bản cài cũ và các gateway provider nghiêm ngặt đã thất bại với những tên được sinh từ định danh plugin dài hơn.

Giữ trường này trong `.claude-plugin/plugin.json`:

```json
{
  "mcpServers": {}
}
```

Object rỗng tường minh này ngăn các bản cài plugin Claude tự động tải các định nghĩa MCP ở root của ECC.
Nếu không có opt-out, các gateway tương thích OpenAI nghiêm ngặt có thể từ chối các tên tool MCP của plugin quá dài, ví dụ tên của bản cài cũ `mcp__plugin_everything-claude-code_github__create_pull_request_review`, vì chúng vượt quá 64 ký tự.

Người dùng muốn dùng các MCP server đi kèm nên cấu hình thủ công từ `.mcp.json` hoặc `mcp-configs/mcp-servers.json`.

---

## Các Anti-Pattern đã biết

Những điều này trông đúng nhưng bị từ chối:

* Giá trị chuỗi thay vì mảng
* **Thêm `"agents"` dưới bất kỳ dạng nào** - không phải trường manifest được nhận diện, gây `Invalid input`
* Thiếu `version`
* Dựa vào đường dẫn suy diễn
* Cho rằng hành vi của marketplace giống với validation ở local
* **Thêm `"hooks": "./hooks/hooks.json"`** - được tự động tải theo quy ước, gây lỗi trùng lặp
* Gỡ `"mcpServers": {}` - bật lại tính năng tự động phát hiện `.mcp.json` ở root cho các bản cài plugin Claude và có thể tạo ra tên tool MCP quá dài

Tránh sự khôn lỏi. Hãy tường minh.

---

## Ví dụ tối thiểu đã biết là hoạt động tốt

```json
{
  "version": "1.1.0",
  "commands": ["./commands/"],
  "skills": ["./skills/"]
}
```

Cấu trúc này đã được kiểm chứng với validator plugin Claude.

**Quan trọng:** Lưu ý KHÔNG có trường `"hooks"` và KHÔNG có trường `"agents"`. Cả hai đều được tải tự động theo quy ước. Thêm tường minh một trong hai sẽ gây lỗi.

---

## Khuyến nghị cho người đóng góp

Trước khi gửi thay đổi động đến `plugin.json`:

1. Đảm bảo mọi trường component đều là mảng
2. Bao gồm `version`
3. KHÔNG thêm các trường `agents` hoặc `hooks` (cả hai đều được tự động tải theo quy ước)
4. Giữ `"mcpServers": {}` trừ khi bạn chủ ý thay đổi hành vi đóng gói MCP của plugin Claude
5. Chạy:

```bash
claude plugin validate .claude-plugin/plugin.json
```

Nếu còn nghi ngờ, hãy chọn sự chi tiết thay vì sự tiện lợi.

---

## Vì sao file này tồn tại

Repo này được fork và dùng rộng rãi như một implementation tham chiếu.

Việc ghi lại các điểm kỳ quặc của validator ở đây:

* Ngăn các vấn đề lặp lại
* Giảm sự bực bội cho người đóng góp
* Giữ sự ổn định của plugin khi hệ sinh thái phát triển

Nếu validator thay đổi, hãy cập nhật tài liệu này trước.
