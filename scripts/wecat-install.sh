#!/usr/bin/env bash
# Cài / cập nhật ECC bản tiếng Việt (wecat-team/ECC) cho Claude Code và Codex trên máy hiện tại.
#
#   curl -fsSL https://raw.githubusercontent.com/wecat-team/ECC/vi/scripts/wecat-install.sh | bash
#   bash scripts/wecat-install.sh [--update] [--claude-only|--codex-only] [--no-vi-rule]
#
# Chạy lại nhiều lần đều an toàn: mọi máy chạy cùng lệnh sẽ có cùng nguồn, cùng nhánh,
# cùng cấu hình hook và cùng quy tắc tiếng Việt.
# Biến môi trường: ECC_REPO (mặc định wecat-team/ECC), ECC_REF (mặc định vi),
# ECC_HOOKS (true|false, mặc định true), ECC_HOOK_PROFILE (minimal|standard|strict, mặc định standard),
# ECC_SOURCE (đường dẫn checkout cục bộ, chỉ dùng khi thử bản chưa push).
set -euo pipefail

REPO="${ECC_REPO:-wecat-team/ECC}"
REF="${ECC_REF:-vi}"
HOOKS="${ECC_HOOKS:-true}"
HOOK_PROFILE="${ECC_HOOK_PROFILE:-standard}"
SOURCE="${ECC_SOURCE:-}"
MATCH="${SOURCE:-$REPO}"
MODE=install
DO_CLAUDE=1
DO_CODEX=1
VI_RULE=1

for arg in "$@"; do
  case "$arg" in
    --update) MODE=update ;;
    --claude-only) DO_CODEX=0 ;;
    --codex-only) DO_CLAUDE=0 ;;
    --no-vi-rule) VI_RULE=0 ;;
    -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
    *) echo "Tham số không hợp lệ: $arg" >&2; exit 2 ;;
  esac
done

say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }

# Claude Desktop ships its own CLI; fall back to it when `claude` is not on PATH.
find_claude() {
  if command -v claude >/dev/null 2>&1; then command -v claude; return; fi
  local c
  for c in "$HOME"/.config/Claude/claude-code/*/*/claude \
           "$HOME/Library/Application Support/Claude/claude-code"/*/*/claude; do
    [ -x "$c" ] && echo "$c"
  done | sort -V | tail -1
}

VI_RULE_BEGIN='<!-- wecat-ecc:vi-rule:begin -->'
VI_RULE_END='<!-- wecat-ecc:vi-rule:end -->'
VI_RULE_TEXT='# Ngôn ngữ giao tiếp (WeCat)

- LUÔN LUÔN trả lời người dùng bằng tiếng Việt, kể cả khi agent, skill hoặc rule được viết bằng tiếng Anh.
- Giữ nguyên tiếng Anh cho code, tên biến, tên file, lệnh terminal, log/lỗi trích nguyên văn và thuật ngữ kỹ thuật quen dùng (commit, branch, PR, deploy, test, refactor...).
- Commit message, tên branch và comment trong code: theo quy ước có sẵn của repo; nếu repo chưa có quy ước, dùng tiếng Anh.
- Báo cáo review, kế hoạch và tóm tắt: viết tiếng Việt, ngắn gọn, đi thẳng vào vấn đề.'

# Write the language rule into a marked block so reruns replace it instead of duplicating it.
install_vi_rule() {
  local file="$1" tmp
  mkdir -p "$(dirname "$file")"
  touch "$file"
  tmp="$(mktemp)"
  awk -v b="$VI_RULE_BEGIN" -v e="$VI_RULE_END" '
    $0 == b { skip = 1; next }
    $0 == e { skip = 0; next }
    !skip { lines[++n] = $0 }
    END { while (n > 0 && lines[n] == "") n--; for (i = 1; i <= n; i++) print lines[i] }
  ' "$file" > "$tmp"
  {
    cat "$tmp"
    [ -s "$tmp" ] && printf '\n'
    printf '%s\n%s\n%s\n' "$VI_RULE_BEGIN" "$VI_RULE_TEXT" "$VI_RULE_END"
  } > "$file"
  rm -f "$tmp"
  say "Đã ghi quy tắc trả lời tiếng Việt vào $file"
}

setup_claude() {
  local claude settings="$HOME/.claude/settings.json"
  claude="$(find_claude)"
  if [ -z "$claude" ]; then
    warn "Không tìm thấy Claude Code CLI, bỏ qua Claude Code."
    return
  fi
  say "Claude Code: $claude"

  local cfg=(--config "hooks_enabled=$HOOKS" --config "hook_profile=$HOOK_PROFILE")
  if [ "$MODE" = update ]; then
    # The fork keeps upstream's version number, so `plugin update` would report "already at the
    # latest version". Refresh the marketplace and reinstall to pick up new commits.
    "$claude" plugin marketplace update ecc
    "$claude" plugin uninstall ecc@ecc --scope user 2>/dev/null || true
  else
    # An `ecc` marketplace from another source (e.g. upstream affaan-m/ECC) must go first.
    local current
    current="$("$claude" plugin marketplace list 2>/dev/null | grep -A1 -E '^[[:space:]]*(❯[[:space:]]*)?ecc$' || true)"
    if [ -n "$current" ] && ! grep -qiF "$MATCH" <<<"$current"; then
      say "Gỡ bản ECC cài từ nguồn khác"
      "$claude" plugin uninstall ecc@ecc --scope user 2>/dev/null || true
      "$claude" plugin marketplace remove ecc
      current=""
    fi
    if [ -z "$current" ]; then
      "$claude" plugin marketplace add "${SOURCE:-$REPO@$REF}"
    fi
  fi
  # Re-applying install with --config keeps the hook settings identical on every machine.
  "$claude" plugin install ecc@ecc --scope user "${cfg[@]}"

  # Pin the fork as the marketplace source (so Claude never re-adds upstream) and write the
  # hook options directly: `plugin install` skips --config when the plugin is already installed.
  if [ -f "$settings" ] && command -v node >/dev/null 2>&1; then
    node -e '
      const fs = require("fs"); const [p, repo, ref, source, hooks, profile] = process.argv.slice(1);
      const s = JSON.parse(fs.readFileSync(p, "utf8"));
      if (!source) {
        s.extraKnownMarketplaces = s.extraKnownMarketplaces || {};
        s.extraKnownMarketplaces.ecc = { source: { source: "github", repo, ref } };
      }
      s.enabledPlugins = s.enabledPlugins || {};
      s.enabledPlugins["ecc@ecc"] = true;
      s.pluginConfigs = s.pluginConfigs || {};
      s.pluginConfigs["ecc@ecc"] = { options: { hooks_enabled: hooks === "true", hook_profile: profile } };
      fs.writeFileSync(p, JSON.stringify(s, null, 2) + "\n");
    ' "$settings" "$REPO" "$REF" "$SOURCE" "$HOOKS" "$HOOK_PROFILE"
  else
    warn "Không có node hoặc settings.json; cấu hình hook chỉ áp dụng ở lần cài đầu."
  fi

  if [ "$VI_RULE" = 1 ]; then install_vi_rule "$HOME/.claude/CLAUDE.md"; fi
  say "Claude Code xong. Mở phiên mới (hoặc khởi động lại app Claude) để thấy menu / tiếng Việt."
}

setup_codex() {
  if ! command -v codex >/dev/null 2>&1; then
    warn "Không tìm thấy Codex CLI, bỏ qua Codex."
    return
  fi
  local codex_home="${CODEX_HOME:-$HOME/.codex}" current
  mkdir -p "$codex_home"
  say "Codex: $(codex --version 2>/dev/null)"

  if [ "$MODE" = update ]; then
    # Local-path marketplaces have nothing to upgrade; Git ones fetch the latest commit of the ref.
    codex plugin marketplace upgrade ecc 2>/dev/null || [ -n "$SOURCE" ] || warn "Không upgrade được marketplace ecc của Codex."
    codex plugin remove ecc@ecc 2>/dev/null || true
  else
    current="$(codex plugin marketplace list 2>/dev/null | awk '$1 == "ecc"' || true)"
    # Replace an `ecc` marketplace that points somewhere other than the fork.
    if [ -n "$current" ] && ! grep -qisF "$MATCH" "$codex_home/config.toml"; then
      say "Gỡ bản ECC cài từ nguồn khác"
      codex plugin remove ecc@ecc 2>/dev/null || true
      codex plugin marketplace remove ecc
      current=""
    fi
    if [ -z "$current" ]; then
      if [ -n "$SOURCE" ]; then codex plugin marketplace add "$SOURCE"; else codex plugin marketplace add "$REPO" --ref "$REF"; fi
    fi
  fi
  codex plugin add ecc@ecc

  if [ "$VI_RULE" = 1 ]; then install_vi_rule "$codex_home/AGENTS.md"; fi
  say "Codex xong. Mở phiên Codex mới; vào /hooks để review và trust hook của ECC nếu muốn dùng hook."
}

if [ "$DO_CLAUDE" = 1 ]; then setup_claude; fi
if [ "$DO_CODEX" = 1 ]; then setup_codex; fi
say "Hoàn tất ($REPO@$REF)."
