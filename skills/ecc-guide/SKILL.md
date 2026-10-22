---
name: ecc-guide
description: "Trả lời các câu hỏi về ECC bằng cách đọc trực tiếp bề mặt repo — agents, skills, commands, hooks, rules, install profile và docs — thay vì dựa vào trí nhớ. Dùng khi người dùng hỏi ECC gồm những gì, cách cài đặt hoặc reset, skill hay command nào phù hợp với một task, hoặc cách onboarding dự án hoạt động."
metadata:
  origin: community
---

# Hướng dẫn ECC

Dùng skill này khi người dùng cần được giúp hiểu, điều hướng, cài đặt hoặc chọn các phần của ECC.

## Khi nào dùng

Dùng skill này khi người dùng:

- hỏi ECC gồm những gì
- muốn được giúp tìm một skill, command, agent, hook, rule hoặc install profile
- mới làm quen với repository và cần một lộ trình có hướng dẫn
- hỏi "how do I do X with ECC?"
- hỏi thành phần ECC nào phù hợp với một dự án
- cần lời giải thích gọn về mối quan hệ giữa commands, skills, agents, hooks và rules
- bối rối về đường dẫn cài đặt, cài trùng lặp, reset/uninstall, hoặc các tùy chọn selective install

## Nguyên tắc cốt lõi

Trả lời từ các file hiện tại, không từ trí nhớ. ECC thay đổi nhanh, nên các số lượng catalog, danh sách tính năng và hướng dẫn cài đặt được ghi cứng sẽ nhanh chóng lỗi thời.

Khi repository ECC có sẵn, hãy kiểm tra các file liên quan trước khi đưa ra câu trả lời cụ thể:

```bash
node scripts/ci/catalog.js --json
find skills -maxdepth 2 -name SKILL.md | sort
find commands -maxdepth 1 -name '*.md' | sort
find agents -maxdepth 1 -name '*.md' | sort
node scripts/install-plan.js --list-profiles
node scripts/install-plan.js --list-components --json
```

Chỉ đọc tập file nhỏ nhất cần thiết cho câu hỏi của người dùng.

## Bản đồ repository

- `README.md`: đường dẫn cài đặt, hướng dẫn uninstall/reset, định vị công khai, FAQ
- `AGENTS.md`: hướng dẫn cho contributor và cấu trúc dự án
- `agent.yaml`: bề mặt gitagent được export và danh sách command
- `commands/`: các shim tương thích slash-command được duy trì
- `skills/*/SKILL.md`: các workflow tái sử dụng và playbook theo lĩnh vực
- `agents/*.md`: các prompt vai trò subagent được ủy quyền
- `rules/`: rule theo ngôn ngữ và harness
- `hooks/README.md`, `hooks/hooks.json`, `scripts/hooks/`: hành vi hook và các gate an toàn
- `manifests/install-*.json`: các module selective install, component, profile và hỗ trợ target
- `docs/`: hướng dẫn harness, ghi chú kiến trúc, tài liệu đã dịch, tài liệu release

## Phong cách trả lời

Mở đầu bằng câu trả lời, rồi đưa ra hành động tiếp theo. Hầu hết người dùng không cần một bản dump toàn bộ catalog.

Dạng phản hồi đầu tiên tốt:

1. dùng cái gì
2. vì sao phù hợp
3. file hoặc lệnh cụ thể để kiểm tra
4. một lệnh hoặc câu hỏi tiếp theo

Tránh:

- liệt kê mọi skill hoặc command theo mặc định
- lặp lại các phần README dài
- đề xuất các command shim đã ngừng dùng khi đã có đường đi ưu tiên skill
- khẳng định một component tồn tại mà không kiểm tra filesystem
- thay hướng dẫn cài đặt bằng các lệnh copy thủ công khi trình cài đặt được quản lý đã hỗ trợ target đó

## Các tác vụ thường gặp

### Onboarding người dùng mới

Đưa ra một menu ngắn:

- cài đặt hoặc reset ECC
- chọn skill cho một dự án
- hiểu commands so với skills
- kiểm tra hook và hành vi an toàn
- chạy harness audit
- tìm một workflow cụ thể

Chỉ tới `README.md` cho cài đặt/reset và `/project-init` cho onboarding riêng của dự án.

### Khám phá tính năng

Với câu hỏi "what should I use for X?":

1. Tìm trong `skills/`, `commands/` và `agents/`.
2. Ưu tiên skill làm bề mặt workflow chính.
3. Chỉ dùng command khi nó là shim tương thích được duy trì hoặc người dùng rõ ràng muốn hành vi slash-command.
4. Nhắc tới agent khi việc ủy quyền (delegation) có ích.

Các lệnh tìm kiếm hữu ích:

```bash
rg -n "<query>" skills commands agents docs
find skills -maxdepth 2 -name SKILL.md | sort
```

### Hướng dẫn cài đặt

Dùng các đường cài đặt được quản lý:

```bash
node scripts/install-plan.js --list-profiles
node scripts/install-plan.js --profile minimal --target claude --json
node scripts/install-apply.js --profile minimal --target claude --dry-run
```

Với việc cài các skill cụ thể:

```bash
node scripts/install-plan.js --skills <skill-id> --target claude --json
node scripts/install-apply.js --skills <skill-id> --target claude --dry-run
```

Cảnh báo người dùng không chồng cài plugin với cài đặt thủ công/profile đầy đủ, trừ khi họ cố ý muốn các bề mặt trùng lặp.

### Onboarding dự án

Dùng `/project-init` khi người dùng muốn cấu hình ECC cho một repo đích. Trình tự mong đợi là:

1. phát hiện stack từ các file dự án
2. giải quyết một install plan dạng dry-run
3. kiểm tra `CLAUDE.md` và các file settings hiện có
4. hỏi trước khi áp dụng thay đổi
5. giữ hướng dẫn được sinh ra ở mức tối thiểu và riêng cho repo

### Xử lý sự cố

Hỏi harness đích và đường dẫn cài đặt trước, rồi kiểm tra:

- metadata cài đặt plugin
- `.claude/`, `.cursor/`, `.codex/`, `.gemini/`, `.opencode/`, `.codebuddy/`, `.joycode/` hoặc `.qwen/`
- `hooks/hooks.json`
- các file install-state
- các file command/skill liên quan

Để kiểm tra sức khỏe repo, hãy đề xuất:

```bash
npm run harness:audit -- --format text
npm run observability:ready
npm test
```

## Mẫu đầu ra

### Đề xuất ngắn

```text
Use <skill-or-command>. It fits because <reason>.

Canonical file: <path>
Verify with: <command>
Next: <one concrete action>
```

### Kết quả tìm kiếm

```text
Best matches:
- <path>: <why it matters>
- <path>: <why it matters>

Recommendation: <which one to use first and why>
```

### Tóm tắt Install Plan

```text
Detected: <stack evidence>
Target: <harness>
Plan: <profile/modules/skills>
Dry run: <command>
Would change: <paths>
Needs approval before apply: <yes/no>
```

## Các bề mặt liên quan

- `/project-init`: kế hoạch onboarding nhận biết stack cho một repo đích
- `/harness-audit`: bảng điểm mức sẵn sàng mang tính tất định
- `/skill-health`: review chất lượng skill
- `/skill-create`: sinh skill mới từ lịch sử git local
- `/security-scan`: kiểm tra bảo mật cấu hình Claude/OpenCode
