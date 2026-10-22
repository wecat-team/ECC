---
name: configure-ecc
description: "Chạy wizard thiết lập ECC theo kiểu hội thoại ngay trong harness hiện tại: kiểm kê bản cài, thu thập scope (user/project/local) và hook mode (off/minimal/standard/strict) trong Claude Code, dùng vòng đời plugin gốc của Codex, hoặc cài bề mặt dự án vào ./.kimi-code, sau đó preview, apply và verify. Dùng khi cài đặt, cập nhật, cấu hình lại hoặc sửa chữa bản cài ECC, đổi hook profile, hoặc chuyển ECC giữa các install scope."
metadata:
  origin: ECC
---

# Configure ECC

Chạy một wizard hội thoại bên trong harness hiện tại. Kiểm kê trước, chỉ thu thập
các lựa chọn được hỗ trợ, preview, xác nhận một lần, apply ở chế độ không tương tác,
verify, và chỉ hiển thị lời chào sau khi thành công. KHÔNG BAO GIỜ clone ECC vào một thư mục
tạm hay sao chép thủ công các thành phần plugin.

Với terminal do con người thao tác, các entry point chuẩn là `ecc setup` và
`npx ecc-universal setup`. Bên trong một harness, hãy dùng các lệnh không tương tác
tường minh bên dưới thay vào đó.

## Định tuyến theo harness hiện tại

- Trong Claude Code, dùng wizard đầy đủ về scope và hook bên dưới.
- Trong Codex, dùng vòng đời plugin gốc của Codex. KHÔNG đưa ra các scope của Claude và không
  ánh xạ bốn hook profile Claude của ECC sang Codex.
- Trong Kimi, cài bề mặt dự án vào `./.kimi-code`. Kimi không
  cung cấp các hook profile vòng đời Claude của ECC.
- Nếu không chắc harness nào, hãy nêu bằng chứng đã phát hiện và hỏi nên cấu hình
  harness nào trước khi chạy bất kỳ lệnh nào có thay đổi dữ liệu.

Skill này là đường cấu hình lại sau khi cài đặt. Nó không thể chặn hoặc
thay thế UI cài đặt lần đầu có sẵn của nhà cung cấp.

## Claude Code: chạy wizard hội thoại đầy đủ

### 1. Kiểm kê mà không thay đổi gì

Chạy cả hai lệnh và tóm tắt scope ECC đã cài, trạng thái đã bật và nguồn
marketplace:

```bash
claude plugin list --json
claude plugin marketplace list --json
```

Coi một bản cài `ecc@ecc` duy nhất hiện có là việc cấu hình lại. KHÔNG
diễn giải nút "Open home page" do Claude quản lý như bằng chứng đã cài đặt. Dừng lại và báo cáo
cách khôi phục mà setup trả về khi có nhiều scope ECC, bản cài legacy/thủ công,
settings bị hỏng định dạng, hoặc xung đột marketplace;
KHÔNG BAO GIỜ đoán nên xóa trạng thái nào.

### 2. Thu thập đúng hai lựa chọn

Hỏi đúng một câu hỏi về scope và yêu cầu một giá trị:

- `user | project | local`
- `user` là toàn cục cho người dùng này.
- `project` được chia sẻ qua settings của repository.
- `local` là riêng tư cho dự án hiện tại.

Chỉ đánh dấu trực quan scope được chọn là đã chọn hoặc đang cài. Nếu người dùng
chọn một scope khác với bản cài duy nhất hiện có, hãy mô tả đó là một lần
migrate scope và thêm `--move-scope` vào các lệnh bên dưới.

Hỏi đúng một câu hỏi về hook mode và yêu cầu một giá trị:

- `off | minimal | standard | strict`
- `off` giữ skill và command nhưng tắt tự động hóa hook của ECC.
- `minimal` bật tự động hóa vòng đời và an toàn nhẹ nhất.
- `standard` cân bằng giữa tự động hóa chất lượng và an toàn.
- `strict` bật các kiểm tra và nhắc nhở mạnh nhất.

Tùy chọn hook là cấu hình plugin Claude cá nhân; nó không đi theo
install scope đã chọn.

### 3. Preview và xác nhận một lần

Ưu tiên script setup đi kèm plugin. Thay hai giá trị đã chọn vào và
chỉ thêm `--move-scope` khi migrate scope:

```bash
node "$CLAUDE_PLUGIN_ROOT/scripts/setup.js" --mode claude-plugin \
  --scope <scope> --hooks <hooks> [--move-scope] --dry-run --json
```

Nếu `$CLAUDE_PLUGIN_ROOT` không khả dụng, dùng package npm đã publish:

```bash
npx --yes --package ecc-universal ecc setup --mode claude-plugin \
  --scope <scope> --hooks <hooks> [--move-scope] --dry-run --json
```

Hiển thị đúng một bản tóm tắt xác nhận gồm hành động dự kiến, một scope,
một hook mode, hành động với marketplace, và mọi việc migrate từ nguồn sang đích.
Hỏi một câu yes/no. KHÔNG chạy `ecc setup` tương tác trần thông qua
công cụ shell của harness vì shell đó thường không phải TTY.

### 4. Apply các lựa chọn tường minh

Sau khi xác nhận, chạy lại cùng route đó mà không có `--dry-run`. Giữ mọi lựa chọn
ở dạng tường minh và yêu cầu JSON để có thể kiểm tra thành công một cách xác định:

```bash
node "$CLAUDE_PLUGIN_ROOT/scripts/setup.js" --mode claude-plugin \
  --scope <scope> --hooks <hooks> [--move-scope] --yes --json
```

Phương án dự phòng:

```bash
npx --yes --package ecc-universal ecc setup --mode claude-plugin \
  --scope <scope> --hooks <hooks> [--move-scope] --yes --json
```

### 5. Verify, rồi hiển thị lời chào

Yêu cầu exit status bằng 0 và kết quả setup có `scope` và `hooks` bằng
các giá trị đã chọn. Sau đó chạy độc lập:

```bash
claude plugin list --json
```

Chỉ tiếp tục khi tồn tại đúng một entry `ecc@ecc` đang bật ở scope
đã chọn. Khi `$CLAUDE_PLUGIN_ROOT` khả dụng, truyền `action` của lần setup thành công
(`installed`, `updated`, `migrated`, `resumed`, hoặc
`already-migrated`) cho renderer đi kèm:

Trước khi gọi nó, yêu cầu phiên bản do nhà cung cấp báo cáo khớp với
`ECC_VERSION_PATTERN` từ `scripts/lib/terminal-welcome.js`. Từ chối văn bản
phiên bản bất ngờ thay vì nội suy nó vào một lệnh shell.

```bash
node -e 'const { renderTerminalWelcome } = require(process.env.CLAUDE_PLUGIN_ROOT + "/scripts/lib/terminal-welcome"); process.stdout.write(renderTerminalWelcome({ action: process.argv[1], version: process.argv[2], color: process.stdout.isTTY }));' "<action>" "<installed-version>"
```

Hiển thị lời chào đúng một lần. Khi thất bại, dry-run, hủy bỏ, scope hoặc
hook không khớp, hoặc trạng thái không thể xác minh, KHÔNG hiển thị nó; thay vào đó hãy báo lỗi
và cách khôi phục. Sau các thay đổi đã được verify, bảo người dùng chạy
`/reload-plugins` hoặc khởi động lại Claude Code.

## Codex: dùng vòng đời plugin gốc

Kiểm kê bằng `codex plugin marketplace list --json` và
`codex plugin list --available --json`. Lệnh plugin gốc của Codex không có
bộ chọn `user | project | local` kiểu Claude. Plugin gốc của Codex có hỗ trợ
hook riêng theo nhà cung cấp, nhưng Codex yêu cầu trust tường minh cho chúng. Hãy để Codex
hiển thị quyết định trust đó; KHÔNG hỏi câu hỏi bốn hook profile của Claude hay
tuyên bố rằng các profile đó ánh xạ sang Codex.

Nếu marketplace ECC chưa có, hãy thêm nó. Nếu không, làm mới snapshot của nó:

```bash
codex plugin marketplace add affaan-m/ECC
codex plugin marketplace upgrade ecc --json
```

Hỏi xác nhận một lần, rồi cài hoặc làm mới cache đã cài theo kiểu idempotent
và verify nó:

```bash
codex plugin add ecc@ecc --json
codex plugin list --json
```

Chỉ tiếp tục khi JSON báo ECC đã được cài và cung cấp
`installedPath` của nó. Sau đó hiển thị lời chào của bundle đã được verify:

Chỉ dùng đúng `installedPath` tuyệt đối do Codex JSON trả về. Từ chối
ký tự điều khiển và yêu cầu phiên bản đã cài khớp với
`ECC_VERSION_PATTERN`. Gọi `node` trực tiếp với mảng đối số này; đây là
một lời gọi qua API của tool, không phải lệnh shell:

```text
["<installedPath>/scripts/welcome.js", "--action", "configured", "--version", "<installed-version>"]
```

Nếu harness hiện tại không thể gọi một executable với mảng đối số riêng biệt,
hãy bỏ qua lời chào. KHÔNG BAO GIỜ dựng một lệnh shell từ các giá trị Codex JSON.

KHÔNG BAO GIỜ tuyên bố rằng các profile `off | minimal | standard | strict` của Claude đã được
áp dụng cho Codex.

## Kimi: cài bề mặt dự án

Nêu bản tóm tắt khả năng trước khi xác nhận: đích
`./.kimi-code`; `hooks=unsupported` cho các lifecycle hook của ECC. KHÔNG hỏi
các câu hỏi về scope hoặc hook mode của Claude. Preview trước:

```bash
npx --yes --package ecc-universal ecc install --profile core --target kimi --dry-run
```

Hiển thị một xác nhận cho đích dự án đó, rồi apply đúng lệnh y hệt
mà không có `--dry-run`. Verify bằng:

```bash
npx --yes --package ecc-universal ecc doctor --target kimi
```

Chỉ sau khi doctor thành công và các chỉ dẫn cùng skill đã cài vẫn nằm
bên trong `./.kimi-code`, mới hiển thị:

```bash
npx --yes --package ecc-universal ecc welcome --action configured
```

KHÔNG tuyên bố rằng Kimi đã cài hoặc cấu hình các lifecycle hook của ECC.
