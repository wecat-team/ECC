---
description: Pull các thay đổi mới nhất của repo ECC và cài đặt lại các target đang được quản lý hiện tại.
disable-model-invocation: true
---

# Auto Update

Cập nhật ECC từ repo upstream và tạo lại bản cài đặt được quản lý của context hiện tại bằng yêu cầu install-state ban đầu.

## Cách dùng

```bash
# Preview the update without mutating anything
ECC_ROOT="$(node -e "var r=(function(){var p=require('path'),f=require('fs'),o=require('os');var e=process.env.CLAUDE_PLUGIN_ROOT;if(e&&e.trim())return e.trim();var d=(process.env.CLAUDE_CONFIG_DIR||'').trim()||p.join(o.homedir(),'.claude');if(d==='~')d=o.homedir();else if(d.charAt(0)==='~'&&(d.charAt(1)==='/'||d.charCodeAt(1)===92))d=p.join(o.homedir(),d.slice(2));d=p.resolve(d);function L(x){try{return require(p.join(x,'scripts','lib','resolve-ecc-root')).resolveEccRoot({probe:p.join('scripts','auto-update.js')})}catch(_){return null}}var r=L(d);if(r)return r;var s=['ecc','ecc@ecc','marketplaces/ecc','everything-claude-code','everything-claude-code@everything-claude-code','marketplaces/everything-claude-code'];for(var i=0;i<s.length;i++){r=L(p.join(d,'plugins',s[i]));if(r)return r}function D(x){try{return f.readdirSync(x,{withFileTypes:true}).filter(function(z){return z.isDirectory()}).map(function(z){return z.name})}catch(e){if(e.code==='ENOENT')return [];throw e}}var g=['ecc','everything-claude-code'];for(var j=0;j<g.length;j++){var c=p.join(d,'plugins','cache',g[j]);var O=D(c);for(var k=0;k<O.length;k++){var q=p.join(c,O[k]);var V=D(q);for(var m=0;m<V.length;m++){r=L(p.join(q,V[m]));if(r)return r}}}return d})();console.log(r)")" &&
node "$ECC_ROOT/scripts/auto-update.js" --dry-run

# Update only Cursor-managed files in the current project
node "$ECC_ROOT/scripts/auto-update.js" --target cursor

# Override the ECC repo root explicitly
node "$ECC_ROOT/scripts/auto-update.js" --repo-root /path/to/ECC
```

## Ghi chú

- Lệnh này dùng yêu cầu install-state đã được ghi lại và chạy lại `install-apply.js` sau khi pull các thay đổi mới nhất của repo.
- Việc cài đặt lại là có chủ đích: nó xử lý các thay đổi đổi tên và xóa ở upstream mà `repair.js` không thể tái dựng an toàn chỉ từ các thao tác cũ (stale operation).
- Hãy dùng `--dry-run` trước nếu bạn muốn xem kế hoạch cài đặt lại được tái dựng trước khi thay đổi bất cứ thứ gì.
