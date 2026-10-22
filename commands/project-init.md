---
description: Phát hiện stack của một dự án và tạo kế hoạch onboarding ECC dạng dry-run dựa trên các install manifest và stack mapping của repo. Dùng để onboard ECC vào một dự án đích thông qua một kế hoạch dry-run có thể review; để khám phá tính năng chung và điều hướng hãy dùng skill ecc-guide hoặc command /ecc-guide.
---

# /project-init

Tạo một kế hoạch onboarding ECC an toàn, có thể review cho dự án hiện tại. Command này phải bắt đầu ở chế độ dry-run và chỉ ghi file sau khi người dùng phê duyệt tường minh.

## Cách dùng

```text
/project-init
/project-init --dry-run
/project-init --target claude
/project-init --target cursor
/project-init --skills continuous-learning-v2,security-review
/project-init --config ecc-install.json
```

## Quy tắc an toàn

1. Mặc định là dry-run. Không sửa `CLAUDE.md`, file settings, rules, skills hay trạng thái cài đặt cho đến khi người dùng phê duyệt kế hoạch cụ thể.
2. Bảo toàn hướng dẫn hiện có của dự án. Nếu `CLAUDE.md`, `.claude/settings.local.json`, `.cursor/`, `.codex/`, `.gemini/`, `.opencode/`, `.codebuddy/`, `.joycode/` hoặc `.qwen/` đã tồn tại, hãy kiểm tra nó và đề xuất kế hoạch merge/append thay vì ghi đè.
3. Dùng công cụ installer và manifest của ECC. Không sao chép file thủ công hay clone các remote tùy ý như một lối tắt cài đặt.
4. Giữ quyền hạn hẹp. Mọi settings được sinh ra phải khớp với các công cụ build/test/lint đã phát hiện và tránh quyền shell rộng.
5. Báo cáo chính xác những gì sẽ thay đổi trước khi áp dụng bất cứ thứ gì.

## Đầu vào phát hiện

Đọc thư mục gốc dự án hiện tại và phát hiện tín hiệu stack từ:

- file package manager: `package.json`, `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lockb`
- manifest ngôn ngữ: `pyproject.toml`, `requirements.txt`, `go.mod`, `Cargo.toml`, `pom.xml`, `build.gradle`, `build.gradle.kts`
- file framework: `next.config.*`, `vite.config.*`, `tailwind.config.*`, `Dockerfile`, `docker-compose.yml`
- cấu hình ECC: `ecc-install.json`
- stack map tùy chọn: `config/project-stack-mappings.json` trong repo ECC

Khi có checkout ECC, hãy dùng `config/project-stack-mappings.json` làm tham chiếu stack-sang-rules/skills. Nếu file không có, hãy quay về các manifest ECC đã cài và lựa chọn tường minh của người dùng.

## Luồng lập kế hoạch

1. Xác định harness đích. Mặc định là `claude` trừ khi người dùng yêu cầu `cursor`, `codex`, `gemini`, `opencode`, `codebuddy`, `joycode` hoặc `qwen`.
2. Phát hiện stack từ các file dự án và hiển thị bằng chứng cho từng kết quả khớp.
3. Xác định kế hoạch ECC nhỏ nhất mà vẫn hữu ích:
   - dự án có `ecc-install.json`: `node scripts/install-plan.js --config ecc-install.json --json`
   - người dùng nêu tên một profile: `node scripts/install-plan.js --profile <profile> --target <target> --json`
   - người dùng nêu tên các skill: `node scripts/install-plan.js --skills <skill-ids> --target <target> --json`
   - chỉ phát hiện được các stack ngôn ngữ: dùng dry-run cài đặt ngôn ngữ legacy với các tên ngôn ngữ đó
4. Chạy lệnh apply ở chế độ dry-run trước khi ghi:

```bash
node scripts/install-apply.js --target <target> --dry-run --json <language-or-profile-args>
```

5. Tóm tắt các stack đã phát hiện, các module/component/skill được chọn, đường dẫn đích, các module không được hỗ trợ bị bỏ qua, và các file sẽ bị thay đổi.
6. Xin phê duyệt trước khi áp dụng lệnh không phải dry-run.

## Hợp đồng output

Trả về:

1. bằng chứng stack đã phát hiện
2. harness đích được đề xuất
3. lệnh dry-run chính xác đã dùng
4. lệnh apply chính xác để chạy sau khi được phê duyệt
5. các file/thư mục sẽ được tạo hoặc thay đổi
6. cảnh báo về các file hiện có, quyền rộng, script thiếu hoặc đích không được hỗ trợ

## Hướng dẫn CLAUDE.md

Nếu người dùng muốn một `CLAUDE.md` khởi đầu, hãy sinh nó tách biệt với kế hoạch installer và giữ ở mức tối thiểu:

- lệnh build, nếu phát hiện được
- lệnh test, nếu phát hiện được
- lệnh lint/typecheck, nếu phát hiện được
- lệnh dev server, nếu phát hiện được
- ghi chú riêng của repo từ các script package hoặc manifest hiện có

KHÔNG BAO GIỜ thay thế một `CLAUDE.md` hiện có mà không hiển thị diff và nhận được phê duyệt.

## Liên quan

- `config/project-stack-mappings.json` cho các gợi ý stack-sang-bề-mặt
- `scripts/install-plan.js` cho việc xác định kế hoạch một cách xác định (deterministic)
- `scripts/install-apply.js` cho các thao tác dry-run và apply
- `/ecc-guide` để khám phá tính năng tương tác trước khi cài đặt
