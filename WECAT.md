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

```bash
git fetch upstream
git switch main && git merge --ff-only upstream/main && git push origin main
git switch vi && git merge main   # file nào upstream sửa sẽ conflict -> dịch lại phần thay đổi
```

## Lưu ý

Một số test trong `tests/` so khớp nguyên văn câu tiếng Anh trong skill/agent nên sẽ fail trên branch `vi`.
Các validator cấu trúc (`scripts/ci/validate-agents.js`, `validate-commands.js`, `validate-skills.js`,
`validate-rules.js`) đều pass.
