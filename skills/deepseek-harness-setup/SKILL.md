---
name: deepseek-harness-setup
description: "Cài đặt và vận hành Everything Claude Code (ECC) trên DeepSeek Harness (DSH): các skill root gốc (~/.dsh/skills, .agents/skills), cầu nối @deepseek-ai/dsh-hooks-claude-code cho command hook, gắn patch bằng bare-insert, cách dùng generator, giới hạn hỗ trợ event và quy trình cập nhật. Dùng khi thiết lập ECC trên DeepSeek Harness, nối ECC hook vào profile DSH, hoặc debug vì sao ECC skill hay hook không xuất hiện trong phiên DSH."
metadata:
  origin: community
---

# Thiết lập DeepSeek Harness

Chạy ECC trên DeepSeek Harness. Hướng dẫn đầy đủ: `docs/DEEPSEEK-HARNESS-GUIDE.md`.

## Khi nào dùng

- Cài ECC skill hoặc hook lên bản cài đặt DeepSeek Harness.
- Quyết định bề mặt (surface) nào của ECC chạy được trên DSH và bề mặt nào không.
- Debug phiên DSH không hiển thị ECC skill hoặc không kích hoạt ECC hook.

## Cách hoạt động

1. **Skill không cần chuyển đổi.** DSH đọc frontmatter `SKILL.md`
   (name/description) từ các skill root gốc. Liên kết catalog ECC một lần:

   ```bash
   ln -s /path/to/ECC/skills/<skill-name> ~/.dsh/skills/<skill-name>
   ```

   Thứ tự ưu tiên root (root `.dsh` và `.agents` của project thắng `~/.dsh`): bỏ qua
   việc liên kết những skill đã có tên trong root ưu tiên cao hơn.
   Thay các placeholder bằng tên skill thật; dấu ngoặc nhọn không phải
   cú pháp shell.

2. **Hook đi qua cầu nối first-party.** Sinh cấu hình định dạng DSH
   từ file hook ECC chuẩn:

   ```bash
   node scripts/dsh/generate-hooks-config.js --ecc-root /path/to/ECC --out ~/.dsh/ecc/hooks-dsh.json
   ```

   Generator chuyển matcher tên tool sang chữ thường, gắn trực tiếp tiền tố
   `CLAUDE_PLUGIN_ROOT`/`ECC_PLUGIN_ROOT` (cầu nối không export
   plugin root), giữ nguyên timeout và bỏ qua các event DSH không bridge được:
   `PreCompact`, `PostToolUseFailure`, `SessionEnd`.

3. **Gắn bằng bare insert** trong `~/.dsh/profiles/<profile>/cordis.patch.yml`:

   ```yaml
   - insert:
       - id: ecc-hooks-claude-code
         name: "@deepseek-ai/dsh-hooks-claude-code"
         config:
           configPath: /absolute/path/to/hooks-dsh.json
   ```

   Các quy tắc của loader từng tốn nhiều thời gian debug mới rút ra được:
   một entry cấp cao nhất dạng `- id:` thuần sẽ bị bỏ qua âm thầm;
   `insert` dưới một id không phải group sẽ bị từ chối với lỗi "not a group"; các
   package plugin first-party không cần entry trong `package.json` của profile.

4. **Xác thực bằng cách compose, rồi kiểm tra trực tiếp.**

   ```bash
   cd ~/.dsh && dsh --profile web --dump-config > /tmp/dump.yml
   grep ecc-hooks /tmp/dump.yml
   ```

   Exit status của compose vẫn là 0 ngay cả khi loader bỏ qua hoặc từ chối
   một entry — các vấn đề đó chỉ được báo trên stderr. Hãy xác nhận id của entry
   xuất hiện trong bản dump và stderr trống. Việc GateGuard từ chối ngay lần
   edit/write/bash đầu tiên của phiên là dấu hiệu nhìn thấy được cho thấy cầu nối
   đang hoạt động.

## Cập nhật

`git pull` phản ánh ngay vào các skill đã liên kết; hãy sinh lại cấu hình hook
bằng cùng lệnh generator. Nếu thư mục checkout ECC bị di chuyển, hãy sinh lại
(đường dẫn được nhúng trong mọi lệnh hook) và liên kết lại skill.

## Giới hạn

| Bề mặt | Trạng thái trên DSH |
|---------|---------------|
| Skills | Khám phá gốc (native); workflow có thể cần điều chỉnh theo host |
| Hooks | 23 command hook trên 5 trong 7 bridge event |
| Slash commands | Không có (cơ chế của Claude Code); workflow được các skill thay thế |
| Agents | Chưa xác minh native dispatch; chỉ dùng hướng dẫn prompt chuẩn sau khi review |

Thiết lập đã được xác thực ở đây nhắm tới profile CLI/web. Profile Desktop có
runtime riêng do bản cài đặt sở hữu, và việc khám phá skill phải được xác minh độc lập ở đó.
Chỉ sinh hook từ bản checkout ECC đã được review; bản checkout được liên kết cung cấp runtime cho chúng.
