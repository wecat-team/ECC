# ECC bản tiếng Việt — WeCat Team

Fork của [affaan-m/ECC](https://github.com/affaan-m/ECC), dịch sang tiếng Việt cho team WeCat.

## Đã dịch

Toàn bộ nội dung được cài bởi profile `developer`:

- 71 agents (`agents/`)
- 97 slash commands (`commands/`)
- 122 rules (`rules/`) + rule mới `rules/common/language.md` — luôn trả lời bằng tiếng Việt
- 186 skills của profile `developer` (`skills/`)
- `AGENTS.md`, `hooks/README.md`, 3 agent Codex trong `.codex/agents/`

Giữ nguyên tiếng Anh: `name`/`tools`/`model` trong frontmatter, code block, đường dẫn, tên lệnh,
và các nhãn máy đọc (`CRITICAL`, `PASS`, `APPROVE`...). Các skill ngoài profile `developer` và `docs/` vẫn là tiếng Anh.

## Cài đặt

```bash
git clone -b vi https://github.com/wecat-team/ECC.git wecat-ecc
cd wecat-ecc
npm install --ignore-scripts

# Claude Code (~/.claude) — không cài hook tự động
./install.sh --target claude --profile developer --no-hooks

# Codex (~/.codex)
./install.sh --target codex --profile developer
```

Thêm `--dry-run` để xem trước danh sách file sẽ được chép. Gỡ cài đặt: `node scripts/uninstall.js --target claude` (hoặc `codex`).

## Cập nhật từ upstream

`main` chứa bản tiếng Việt (đã merge từ `vi`), nên cập nhật bằng cách merge `upstream/main` vào `main`.
`vi` là branch mặc định trên GitHub và luôn được giữ trùng với `main`.

```bash
git remote add upstream https://github.com/affaan-m/ECC.git   # chỉ cần làm một lần
git fetch upstream
git switch main
git merge upstream/main
```

Nếu có conflict: đó là file upstream vừa sửa mà mình đã dịch. Với mỗi file conflict:

1. Xem upstream đổi gì: `git diff main...upstream/main -- <file>`
2. Giữ bản tiếng Việt, rồi dịch thêm phần upstream mới thay đổi theo đúng quy ước trong phần "Đã dịch"
   (frontmatter chỉ dịch `description`, giữ nguyên code block).
3. `git add <file>`, rồi `git commit` khi đã xử lý hết.

File upstream mới thêm sẽ vào thẳng bằng tiếng Anh; dịch dần nếu cần.

Sau đó chạy validator, push `main` và đồng bộ `vi`:

```bash
node scripts/ci/validate-agents.js && node scripts/ci/validate-commands.js \
  && node scripts/ci/validate-skills.js && node scripts/ci/validate-rules.js
git push origin main
git switch vi && git merge --ff-only main && git push origin vi
```

Cuối cùng cài lại để máy nhận bản mới (chạy lại đúng lệnh ở phần "Cài đặt").

## Lưu ý

Một số test trong `tests/` so khớp nguyên văn câu tiếng Anh trong skill/agent nên sẽ fail trên branch `vi`.
Các validator cấu trúc (`scripts/ci/validate-agents.js`, `validate-commands.js`, `validate-skills.js`,
`validate-rules.js`) đều pass.
