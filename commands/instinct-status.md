---
name: instinct-status
description: Hiển thị các instinct đã học (project + global) kèm độ tin cậy
command: true
---

# Lệnh Instinct Status

Hiển thị các instinct đã học của dự án hiện tại cùng các instinct global, nhóm theo domain.

## Triển khai

Chạy instinct CLI, xác định gốc plugin ECC đang hoạt động theo cùng cách
`hooks/hooks.json` và các slash command khác (`/sessions`, `/skill-health`)
làm — biến môi trường → cài đặt chuẩn → các gốc plugin đã biết → plugin cache → dự phòng.
Cách này tránh sự lệch xảy ra khi `CLAUDE_PLUGIN_ROOT` chưa được đặt
mà thư mục legacy `~/.claude/skills/continuous-learning-v2/` vẫn
tồn tại (#2037).

```bash
ECC_ROOT="$(node -e "var r=(function(){var p=require('path'),f=require('fs'),o=require('os');var e=process.env.CLAUDE_PLUGIN_ROOT;if(e&&e.trim())return e.trim();var d=(process.env.CLAUDE_CONFIG_DIR||'').trim()||p.join(o.homedir(),'.claude');if(d==='~')d=o.homedir();else if(d.charAt(0)==='~'&&(d.charAt(1)==='/'||d.charCodeAt(1)===92))d=p.join(o.homedir(),d.slice(2));d=p.resolve(d);function L(x){try{return require(p.join(x,'scripts','lib','resolve-ecc-root')).resolveEccRoot()}catch(_){return null}}var r=L(d);if(r)return r;var s=['ecc','ecc@ecc','marketplaces/ecc','everything-claude-code','everything-claude-code@everything-claude-code','marketplaces/everything-claude-code'];for(var i=0;i<s.length;i++){r=L(p.join(d,'plugins',s[i]));if(r)return r}function D(x){try{return f.readdirSync(x,{withFileTypes:true}).filter(function(z){return z.isDirectory()}).map(function(z){return z.name})}catch(e){if(e.code==='ENOENT')return [];throw e}}var g=['ecc','everything-claude-code'];for(var j=0;j<g.length;j++){var c=p.join(d,'plugins','cache',g[j]);var O=D(c);for(var k=0;k<O.length;k++){var q=p.join(c,O[k]);var V=D(q);for(var m=0;m<V.length;m++){r=L(p.join(q,V[m]));if(r)return r}}}return d})();console.log(r)")" &&
python3 "$ECC_ROOT/skills/continuous-learning-v2/scripts/instinct-cli.py" status
```

## Cách dùng

```
/instinct-status
```

## Cần làm gì

1. Phát hiện context dự án hiện tại (git remote/hash đường dẫn)
2. Đọc instinct của dự án từ `~/.claude/homunculus/projects/<project-id>/instincts/`
3. Đọc instinct global từ `~/.claude/homunculus/instincts/`
4. Merge theo quy tắc ưu tiên (project ghi đè global khi trùng ID)
5. Hiển thị nhóm theo domain kèm thanh độ tin cậy và thống kê quan sát

## Định dạng output

```
============================================================
  INSTINCT STATUS - 12 total
============================================================

  Project: my-app (a1b2c3d4e5f6)
  Project instincts: 8
  Global instincts:  4

## PROJECT-SCOPED (my-app)
  ### WORKFLOW (3)
    ███████░░░  70%  grep-before-edit [project]
              trigger: when modifying code

## GLOBAL (apply to all projects)
  ### SECURITY (2)
    █████████░  85%  validate-user-input [global]
              trigger: when handling user input
```
