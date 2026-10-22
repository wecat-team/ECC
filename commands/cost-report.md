---
description: Tạo báo cáo chi phí Claude Code local từ log metrics của cost-tracker trong ECC. Dùng để xem tóm tắt trên terminal hoặc xuất CSV phần chi tiêu đã theo dõi; skill cost-tracking dùng cùng log metrics này cho các câu hỏi về chi phí/ngân sách theo yêu cầu trong hội thoại.
argument-hint: "[csv]"
---

# Cost Report

Tóm tắt chi tiêu Claude Code local theo ngày, model và session từ log metrics
mà hook `stop:cost-tracker` của ECC ghi ra.

## Dữ liệu nằm ở đâu

Tracker thêm vào `~/.claude/metrics/costs.jsonl` một JSON object cho mỗi lần
session dừng. Mỗi dòng là một **snapshot tích lũy của session đó**, nên báo cáo
lấy **dòng mới nhất cho mỗi `session_id`** rồi cộng tổng qua các session (cộng
mọi dòng sẽ bị đếm nhiều lần).

Schema của dòng:
`{ timestamp, session_id, transcript_path, model, input_tokens, output_tokens, cache_write_tokens, cache_read_tokens, estimated_cost_usd }`

## Lệnh này làm gì

1. Kiểm tra `~/.claude/metrics/costs.jsonl` có tồn tại không. Nếu không, hãy báo
   người dùng rằng tracker chưa được thiết lập (file được tạo sau khi session
   đầu tiên kết thúc với hook `stop:cost-tracker` được bật).
2. Rút gọn các dòng về snapshot mới nhất cho mỗi session và tổng hợp.
3. Trình bày một báo cáo gọn, hoặc xuất các dòng gần đây dưới dạng CSV khi đối số là `csv`.

Dùng `node` thay vì `sqlite3`/`jq` để lệnh hoạt động giống hệt nhau trên macOS,
Linux và Windows.

## Báo cáo

```bash
node -e '
const fs=require("fs"),os=require("os"),path=require("path");
const f=path.join(os.homedir(),".claude","metrics","costs.jsonl");
if(!fs.existsSync(f)){console.log("Cost tracker not set up: "+f+" not found. Enable the stop:cost-tracker hook and finish a session first.");process.exit(0);}
const rows=fs.readFileSync(f,"utf8").split(/\r?\n/).filter(Boolean).map(l=>{try{return JSON.parse(l)}catch{return null}}).filter(Boolean);
const bySession=new Map();
for(const r of rows){const k=r.session_id||r.transcript_path||r.timestamp;const p=bySession.get(k);if(!p||String(r.timestamp)>String(p.timestamp))bySession.set(k,r);}
const latest=[...bySession.values()];
const cost=r=>Number(r.estimated_cost_usd)||0;
const day=r=>String(r.timestamp||"").slice(0,10);
const today=new Date().toISOString().slice(0,10);
const d=new Date(Date.now()-864e5).toISOString().slice(0,10);
const sum=a=>a.reduce((s,r)=>s+cost(r),0);
const f4=n=>"$"+n.toFixed(4);
console.log("=== Cost summary ===");
console.log("today:     "+f4(sum(latest.filter(r=>day(r)===today))));
console.log("yesterday: "+f4(sum(latest.filter(r=>day(r)===d))));
console.log("total:     "+f4(sum(latest))+"  ("+latest.length+" sessions)");
const by=(key)=>{const m=new Map();for(const r of latest){const k=key(r)||"(unknown)";m.set(k,(m.get(k)||0)+cost(r));}return [...m.entries()].sort((a,b)=>b[1]-a[1]);};
console.log("\n=== By model ===");for(const [k,v] of by(r=>r.model))console.log(f4(v).padStart(12)+"  "+k);
console.log("\n=== Last 7 days ===");
const days=new Map();for(const r of latest){const k=day(r);days.set(k,(days.get(k)||0)+cost(r));}
[...days.entries()].sort((a,b)=>b[0]<a[0]?-1:1).slice(0,7).forEach(([k,v])=>console.log(k+"  "+f4(v)));
'
```

## Xuất CSV (`/cost-report csv`)

```bash
node -e '
const fs=require("fs"),os=require("os"),path=require("path");
const f=path.join(os.homedir(),".claude","metrics","costs.jsonl");
if(!fs.existsSync(f)){console.error("no data");process.exit(0);}
const rows=fs.readFileSync(f,"utf8").split(/\r?\n/).filter(Boolean).map(l=>{try{return JSON.parse(l)}catch{return null}}).filter(Boolean).slice(-100);
console.log("timestamp,session_id,model,input_tokens,output_tokens,cache_write_tokens,cache_read_tokens,estimated_cost_usd");
for(const r of rows)console.log([r.timestamp,r.session_id,r.model,r.input_tokens,r.output_tokens,r.cache_write_tokens,r.cache_read_tokens,r.estimated_cost_usd].join(","));
'
```

## Định dạng báo cáo

1. Tóm tắt: hôm nay, hôm qua, tổng cộng, số session.
2. Theo model: các model xếp hạng theo tổng chi phí.
3. Bảy ngày gần nhất: ngày và chi phí.

Hãy dựa vào các giá trị `estimated_cost_usd` đã được tính sẵn do tracker ghi;
không ước tính lại giá từ token thô ở đây.
