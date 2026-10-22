---
name: skill-health
description: Hiển thị dashboard sức khỏe danh mục skill kèm biểu đồ và phân tích. Dùng cho dashboard định lượng về mức sử dụng/tỷ lệ thành công; với audit định tính về tuân thủ hoặc chất lượng hãy dùng skill skill-stocktake.
command: true
---

# Dashboard sức khỏe Skill

Hiển thị dashboard sức khỏe toàn diện cho mọi skill trong danh mục, gồm sparkline tỷ lệ thành công, gom cụm mẫu lỗi, các amendment đang chờ và lịch sử phiên bản.

## Triển khai

Chạy CLI skill health ở chế độ dashboard:

```bash
ECC_ROOT="$(node -e "var r=(function(){var p=require('path'),f=require('fs'),o=require('os');var e=process.env.CLAUDE_PLUGIN_ROOT;if(e&&e.trim())return e.trim();var d=(process.env.CLAUDE_CONFIG_DIR||'').trim()||p.join(o.homedir(),'.claude');if(d==='~')d=o.homedir();else if(d.charAt(0)==='~'&&(d.charAt(1)==='/'||d.charCodeAt(1)===92))d=p.join(o.homedir(),d.slice(2));d=p.resolve(d);function L(x){try{return require(p.join(x,'scripts','lib','resolve-ecc-root')).resolveEccRoot()}catch(_){return null}}var r=L(d);if(r)return r;var s=['ecc','ecc@ecc','marketplaces/ecc','everything-claude-code','everything-claude-code@everything-claude-code','marketplaces/everything-claude-code'];for(var i=0;i<s.length;i++){r=L(p.join(d,'plugins',s[i]));if(r)return r}function D(x){try{return f.readdirSync(x,{withFileTypes:true}).filter(function(z){return z.isDirectory()}).map(function(z){return z.name})}catch(e){if(e.code==='ENOENT')return [];throw e}}var g=['ecc','everything-claude-code'];for(var j=0;j<g.length;j++){var c=p.join(d,'plugins','cache',g[j]);var O=D(c);for(var k=0;k<O.length;k++){var q=p.join(c,O[k]);var V=D(q);for(var m=0;m<V.length;m++){r=L(p.join(q,V[m]));if(r)return r}}}return d})();console.log(r)")" &&
node "$ECC_ROOT/scripts/skills-health.js" --dashboard
```

Chỉ cho một panel cụ thể:

```bash
ECC_ROOT="$(node -e "var r=(function(){var p=require('path'),f=require('fs'),o=require('os');var e=process.env.CLAUDE_PLUGIN_ROOT;if(e&&e.trim())return e.trim();var d=(process.env.CLAUDE_CONFIG_DIR||'').trim()||p.join(o.homedir(),'.claude');if(d==='~')d=o.homedir();else if(d.charAt(0)==='~'&&(d.charAt(1)==='/'||d.charCodeAt(1)===92))d=p.join(o.homedir(),d.slice(2));d=p.resolve(d);function L(x){try{return require(p.join(x,'scripts','lib','resolve-ecc-root')).resolveEccRoot()}catch(_){return null}}var r=L(d);if(r)return r;var s=['ecc','ecc@ecc','marketplaces/ecc','everything-claude-code','everything-claude-code@everything-claude-code','marketplaces/everything-claude-code'];for(var i=0;i<s.length;i++){r=L(p.join(d,'plugins',s[i]));if(r)return r}function D(x){try{return f.readdirSync(x,{withFileTypes:true}).filter(function(z){return z.isDirectory()}).map(function(z){return z.name})}catch(e){if(e.code==='ENOENT')return [];throw e}}var g=['ecc','everything-claude-code'];for(var j=0;j<g.length;j++){var c=p.join(d,'plugins','cache',g[j]);var O=D(c);for(var k=0;k<O.length;k++){var q=p.join(c,O[k]);var V=D(q);for(var m=0;m<V.length;m++){r=L(p.join(q,V[m]));if(r)return r}}}return d})();console.log(r)")" &&
node "$ECC_ROOT/scripts/skills-health.js" --dashboard --panel failures
```

Cho đầu ra đọc được bằng máy:

```bash
ECC_ROOT="$(node -e "var r=(function(){var p=require('path'),f=require('fs'),o=require('os');var e=process.env.CLAUDE_PLUGIN_ROOT;if(e&&e.trim())return e.trim();var d=(process.env.CLAUDE_CONFIG_DIR||'').trim()||p.join(o.homedir(),'.claude');if(d==='~')d=o.homedir();else if(d.charAt(0)==='~'&&(d.charAt(1)==='/'||d.charCodeAt(1)===92))d=p.join(o.homedir(),d.slice(2));d=p.resolve(d);function L(x){try{return require(p.join(x,'scripts','lib','resolve-ecc-root')).resolveEccRoot()}catch(_){return null}}var r=L(d);if(r)return r;var s=['ecc','ecc@ecc','marketplaces/ecc','everything-claude-code','everything-claude-code@everything-claude-code','marketplaces/everything-claude-code'];for(var i=0;i<s.length;i++){r=L(p.join(d,'plugins',s[i]));if(r)return r}function D(x){try{return f.readdirSync(x,{withFileTypes:true}).filter(function(z){return z.isDirectory()}).map(function(z){return z.name})}catch(e){if(e.code==='ENOENT')return [];throw e}}var g=['ecc','everything-claude-code'];for(var j=0;j<g.length;j++){var c=p.join(d,'plugins','cache',g[j]);var O=D(c);for(var k=0;k<O.length;k++){var q=p.join(c,O[k]);var V=D(q);for(var m=0;m<V.length;m++){r=L(p.join(q,V[m]));if(r)return r}}}return d})();console.log(r)")" &&
node "$ECC_ROOT/scripts/skills-health.js" --dashboard --json
```

## Cách dùng

```
/skill-health                    # Full dashboard view
/skill-health --panel failures   # Only failure clustering panel
/skill-health --json             # Machine-readable JSON output
```

## Cần làm gì

1. Chạy script skills-health.js với flag --dashboard
2. Hiển thị đầu ra cho người dùng
3. Nếu có skill nào đang suy giảm, hãy làm nổi bật chúng và đề xuất chạy /evolve
4. Nếu có amendment đang chờ, hãy đề xuất xem xét chúng

## Các panel

- **Success Rate (30d)** — Biểu đồ sparkline cho thấy tỷ lệ thành công hằng ngày của từng skill
- **Failure Patterns** — Các lý do lỗi được gom cụm kèm biểu đồ cột ngang
- **Pending Amendments** — Các đề xuất amendment đang chờ review
- **Version History** — Dòng thời gian các snapshot phiên bản của từng skill

## Lưu trữ snapshot

Việc tạo snapshot và rollback yêu cầu bộ lưu trữ có thể ghi và hỗ trợ hardlink. API versioning kiểm tra khả năng đó trước khi tạo hoặc thay đổi lịch sử phiên bản và từ chối bộ lưu trữ không được hỗ trợ mà không có copy fallback. Hãy dùng vị trí hỗ trợ hardlink cho các snapshot mới. Việc đọc lịch sử health và phiên bản hiện có không yêu cầu tạo hard link.
