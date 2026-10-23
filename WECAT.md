# ECC bản tiếng Việt — WeCat Team

Fork của [affaan-m/ECC](https://github.com/affaan-m/ECC), dịch sang tiếng Việt cho team WeCat.

## Đã dịch

- 71 agents (`agents/`)
- 97 slash commands (`commands/`)
- 122 rules (`rules/`) + rule mới `rules/common/language.md` — luôn trả lời bằng tiếng Việt
- Mô tả (`description`) của toàn bộ 311 skills (`skills/`) — đây là dòng hiện trong menu `/` của
  Claude Code và danh sách skill của Codex. Nội dung đầy đủ đã dịch cho 186 skills của profile `developer`.
- `AGENTS.md`, `hooks/README.md`, 3 agent Codex trong `.codex/agents/`

Giữ nguyên tiếng Anh: `name`/`tools`/`model` trong frontmatter, code block, đường dẫn, tên lệnh,
các nhãn máy đọc (`CRITICAL`, `PASS`, `APPROVE`...), và các câu mà validator đọc bằng máy
(mô tả trong `.claude-plugin/*.json`, dòng comment catalog trong `AGENTS.md`). Thân bài của các
skill ngoài profile `developer` và `docs/` vẫn là tiếng Anh.

## Cài đặt trên mọi thiết bị (Claude Code + Codex)

Mỗi máy chỉ cần chạy **một lệnh**. Máy nào chạy cùng lệnh cũng có cùng nguồn (`wecat-team/ECC`,
nhánh `vi`), cùng cấu hình hook và cùng quy tắc trả lời tiếng Việt, cho cả Claude Code (CLI, app
desktop, extension IDE — đều dùng chung `~/.claude`) lẫn Codex (CLI và app — dùng chung `~/.codex`).

**Linux / macOS:**

```bash
curl -fsSL https://raw.githubusercontent.com/wecat-team/ECC/vi/scripts/wecat-install.sh | bash
```

Script sẽ:

1. Tìm `claude` (cả bản đi kèm app Claude Desktop) và `codex`; thiếu cái nào thì bỏ qua cái đó.
2. Nếu máy đang cài ECC từ nguồn khác (ví dụ bản gốc `affaan-m/ECC`), gỡ ra trước.
3. Cài plugin `ecc@ecc` từ fork cho Claude Code (scope `user`) và Codex.
4. Ghi vào `~/.claude/settings.json`: nguồn marketplace là fork (để Claude không tự kéo lại bản gốc),
   bật plugin, và cấu hình hook (`hooks_enabled=true`, `hook_profile=standard`).
5. Ghi quy tắc "luôn trả lời bằng tiếng Việt" vào `~/.claude/CLAUDE.md` và `~/.codex/AGENTS.md`,
   trong khối `<!-- wecat-ecc:vi-rule:begin -->` … `<!-- wecat-ecc:vi-rule:end -->`. Nội dung khác
   của hai file này được giữ nguyên; chạy lại chỉ thay khối đó, không chèn trùng.

Chạy lại bao nhiêu lần cũng được. Tùy chọn:

| Tùy chọn | Tác dụng |
|---|---|
| `--update` | Lấy commit mới nhất của nhánh và cài lại (xem phần "Cập nhật trên các máy") |
| `--claude-only` / `--codex-only` | Chỉ cài cho một bên |
| `--no-vi-rule` | Không ghi quy tắc tiếng Việt |
| `ECC_HOOK_PROFILE=minimal` | Hook nhẹ hơn (`minimal` / `standard` / `strict`) — đặt giống nhau trên mọi máy |
| `ECC_HOOKS=false` | Tắt toàn bộ hook của ECC trong Claude Code |
| `ECC_REF=main` | Cài từ nhánh khác |

Truyền tùy chọn khi chạy qua `curl`: `curl -fsSL …/wecat-install.sh | ECC_HOOK_PROFILE=minimal bash -s -- --update`.

**Windows** (PowerShell), hoặc máy không chạy được script:

```powershell
claude plugin marketplace add wecat-team/ECC@vi
claude plugin install ecc@ecc --scope user --config hooks_enabled=true --config hook_profile=standard
codex plugin marketplace add wecat-team/ECC --ref vi
codex plugin add ecc@ecc
```

Sau đó tự thêm nội dung `rules/common/language.md` vào `%USERPROFILE%\.claude\CLAUDE.md` và
`%USERPROFILE%\.codex\AGENTS.md`. Nếu máy đã cài ECC bản gốc, gỡ trước:
`claude plugin uninstall ecc@ecc`, `claude plugin marketplace remove ecc`,
`codex plugin remove ecc@ecc`, `codex plugin marketplace remove ecc`.

**Sau khi cài:**

- Claude Code: mở phiên mới (hoặc khởi động lại app Claude), gõ `/ecc:` để thấy danh sách tiếng Việt.
- Codex: mở phiên mới. Hook của ECC trong Codex cần được duyệt tay một lần trên mỗi máy: vào `/hooks`,
  review rồi trust. Gọi skill bằng `$tên-skill`, ví dụ `$tdd-workflow`.
- Kiểm tra: `claude plugin marketplace list` và `codex plugin marketplace list` phải thấy `ecc`
  trỏ tới `wecat-team/ECC`.

**Không dùng chung với `install.sh`.** `./install.sh --target claude|codex` là cách cài cũ, chép file
thẳng vào `~/.claude` / `~/.codex`. Dùng song song với plugin sẽ bị trùng agent/skill. Nếu máy từng cài
theo cách đó, gỡ trước bằng `node scripts/uninstall.js --target claude` (và `--target codex`).

## Cập nhật trên các máy

Sau khi có commit mới trên nhánh `vi`, chạy trên từng máy:

```bash
curl -fsSL https://raw.githubusercontent.com/wecat-team/ECC/vi/scripts/wecat-install.sh | bash -s -- --update
```

Fork giữ nguyên số phiên bản của upstream (`2.2.3`), nên `claude plugin update` sẽ báo "already at the
latest version" dù nội dung đã đổi. `--update` vì vậy làm mới marketplace rồi gỡ và cài lại plugin,
sau đó ghi lại cấu hình hook và quy tắc tiếng Việt. Trên Codex, hook đã đổi phải được trust lại trong `/hooks`.

## Cập nhật từ upstream

`main` chứa bản tiếng Việt (đã merge từ `vi`), nên cập nhật bằng cách merge `upstream/main` vào `main`.
`vi` là branch mặc định trên GitHub và luôn được giữ trùng với `main`. **Mọi máy cài theo nhánh `vi`**,
nên nhớ đồng bộ `vi` sau mỗi lần merge, nếu không các máy sẽ không nhận được bản mới.

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

File upstream mới thêm sẽ vào thẳng bằng tiếng Anh; dịch dần nếu cần (ít nhất là dòng `description`
của skill mới, vì đó là dòng hiện trong menu `/`).

Sau đó chạy validator, push `main` và đồng bộ `vi`:

```bash
node scripts/ci/validate-agents.js && node scripts/ci/validate-commands.js \
  && node scripts/ci/validate-skills.js && node scripts/ci/validate-rules.js \
  && node scripts/ci/catalog.js
git push origin main
git switch vi && git merge --ff-only main && git push origin vi
```

Nếu `catalog.js` báo lệch số lượng (upstream thêm/bớt agent, skill, command), sửa con số trong dòng
comment catalog ở đầu `AGENTS.md` và trong câu tiếng Việt ngay phía trên nó.

Cuối cùng chạy lệnh `--update` ở phần "Cập nhật trên các máy" trên từng máy.

## Lưu ý

Một số test trong `tests/` so khớp nguyên văn câu tiếng Anh trong skill/agent nên sẽ fail trên branch `vi`.
Các validator cấu trúc (`scripts/ci/validate-agents.js`, `validate-commands.js`, `validate-skills.js`,
`validate-rules.js`) và `scripts/ci/catalog.js` đều pass.
