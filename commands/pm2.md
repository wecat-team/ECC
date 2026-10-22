---
description: Phân tích một dự án và sinh các lệnh dịch vụ PM2 cho các dịch vụ frontend, backend hoặc database được phát hiện.
---

# PM2 Init

Tự động phân tích dự án và sinh các lệnh dịch vụ PM2.

**Command**: `$ARGUMENTS`

---

## Workflow

1. Kiểm tra PM2 (cài qua `npm install -g pm2` nếu thiếu)
2. Quét dự án để xác định các dịch vụ (frontend/backend/database)
3. Sinh các file cấu hình và các file command riêng lẻ

---

## Phát hiện dịch vụ

| Loại | Cách nhận diện | Port mặc định |
|------|-----------|--------------|
| Vite | vite.config.* | 5173 |
| Next.js | next.config.* | 3000 |
| Nuxt | nuxt.config.* | 3000 |
| CRA | react-scripts in package.json | 3000 |
| Express/Node | thư mục server/backend/api + package.json | 3000 |
| FastAPI/Flask | requirements.txt / pyproject.toml | 8000 |
| Go | go.mod / main.go | 8080 |

**Thứ tự ưu tiên phát hiện port**: Người dùng chỉ định > .env > file cấu hình > đối số script > port mặc định

---

## Các file được sinh ra

```
project/
├── ecosystem.config.cjs              # PM2 config
├── {backend}/start.cjs               # Python wrapper (if applicable)
└── .claude/
    ├── commands/
    │   ├── pm2-all.md                # Start all + monit
    │   ├── pm2-all-stop.md           # Stop all
    │   ├── pm2-all-restart.md        # Restart all
    │   ├── pm2-{port}.md             # Start single + logs
    │   ├── pm2-{port}-stop.md        # Stop single
    │   ├── pm2-{port}-restart.md     # Restart single
    │   ├── pm2-logs.md               # View all logs
    │   └── pm2-status.md             # View status
    └── scripts/
        ├── pm2-logs-{port}.ps1       # Single service logs
        └── pm2-monit.ps1             # PM2 monitor
```

---

## Cấu hình Windows (QUAN TRỌNG)

### ecosystem.config.cjs

**PHẢI dùng phần mở rộng `.cjs`**

```javascript
module.exports = {
  apps: [
    // Node.js (Vite/Next/Nuxt)
    {
      name: 'project-3000',
      cwd: './packages/web',
      script: 'node_modules/vite/bin/vite.js',
      args: '--port 3000',
      interpreter: 'C:/Program Files/nodejs/node.exe',
      env: { NODE_ENV: 'development' }
    },
    // Python
    {
      name: 'project-8000',
      cwd: './backend',
      script: 'start.cjs',
      interpreter: 'C:/Program Files/nodejs/node.exe',
      env: { PYTHONUNBUFFERED: '1' }
    }
  ]
}
```

**Đường dẫn script theo framework:**

| Framework | script | args |
|-----------|--------|------|
| Vite | `node_modules/vite/bin/vite.js` | `--port {port}` |
| Next.js | `node_modules/next/dist/bin/next` | `dev -p {port}` |
| Nuxt | `node_modules/nuxt/bin/nuxt.mjs` | `dev --port {port}` |
| Express | `src/index.js` or `server.js` | - |

### Script wrapper Python (start.cjs)

```javascript
const { spawn } = require('child_process');
const proc = spawn('python', ['-m', 'uvicorn', 'app.main:app', '--host', '0.0.0.0', '--port', '8000', '--reload'], {
  cwd: __dirname, stdio: 'inherit', windowsHide: true
});
proc.on('close', (code) => process.exit(code));
```

---

## Template file command (nội dung tối thiểu)

### pm2-all.md (Khởi động tất cả + monit)
````markdown
Start all services and open PM2 monitor.
```bash
cd "{PROJECT_ROOT}" && pm2 start ecosystem.config.cjs && start wt.exe -d "{PROJECT_ROOT}" pwsh -NoExit -c "pm2 monit"
```
````

### pm2-all-stop.md
````markdown
Stop all services.
```bash
cd "{PROJECT_ROOT}" && pm2 stop all
```
````

### pm2-all-restart.md
````markdown
Restart all services.
```bash
cd "{PROJECT_ROOT}" && pm2 restart all
```
````

### pm2-{port}.md (Khởi động một dịch vụ + logs)
````markdown
Start {name} ({port}) and open logs.
```bash
cd "{PROJECT_ROOT}" && pm2 start ecosystem.config.cjs --only {name} && start wt.exe -d "{PROJECT_ROOT}" pwsh -NoExit -c "pm2 logs {name}"
```
````

### pm2-{port}-stop.md
````markdown
Stop {name} ({port}).
```bash
cd "{PROJECT_ROOT}" && pm2 stop {name}
```
````

### pm2-{port}-restart.md
````markdown
Restart {name} ({port}).
```bash
cd "{PROJECT_ROOT}" && pm2 restart {name}
```
````

### pm2-logs.md
````markdown
View all PM2 logs.
```bash
cd "{PROJECT_ROOT}" && pm2 logs
```
````

### pm2-status.md
````markdown
View PM2 status.
```bash
cd "{PROJECT_ROOT}" && pm2 status
```
````

### Script PowerShell (pm2-logs-{port}.ps1)
```powershell
Set-Location "{PROJECT_ROOT}"
pm2 logs {name}
```

### Script PowerShell (pm2-monit.ps1)
```powershell
Set-Location "{PROJECT_ROOT}"
pm2 monit
```

---

## Quy tắc chính

1. **File cấu hình**: `ecosystem.config.cjs` (không phải .js)
2. **Node.js**: Chỉ định trực tiếp đường dẫn bin + interpreter
3. **Python**: Script wrapper Node.js + `windowsHide: true`
4. **Mở cửa sổ mới**: `start wt.exe -d "{path}" pwsh -NoExit -c "command"`
5. **Nội dung tối thiểu**: Mỗi file command chỉ có mô tả 1-2 dòng + khối bash
6. **Thực thi trực tiếp**: Không cần AI phân tích, chỉ cần chạy lệnh bash

---

## Thực thi

Dựa trên `$ARGUMENTS`, thực hiện init:

1. Quét dự án để tìm các dịch vụ
2. Sinh `ecosystem.config.cjs`
3. Sinh `{backend}/start.cjs` cho các dịch vụ Python (nếu áp dụng)
4. Sinh các file command trong `.claude/commands/`
5. Sinh các file script trong `.claude/scripts/`
6. **Cập nhật CLAUDE.md của dự án** với thông tin PM2 (xem bên dưới)
7. **Hiển thị tóm tắt hoàn tất** kèm các lệnh terminal

---

## Sau Init: Cập nhật CLAUDE.md

Sau khi sinh file, nối mục PM2 vào `CLAUDE.md` của dự án (tạo nếu chưa có):

````markdown
## PM2 Services

| Port | Name | Type |
|------|------|------|
| {port} | {name} | {type} |

**Terminal Commands:**
```bash
pm2 start ecosystem.config.cjs   # First time
pm2 start all                    # After first time
pm2 stop all / pm2 restart all
pm2 start {name} / pm2 stop {name}
pm2 logs / pm2 status / pm2 monit
pm2 save                         # Save process list
pm2 resurrect                    # Restore saved list
```
````

**Quy tắc cập nhật CLAUDE.md:**
- Nếu mục PM2 đã tồn tại, thay thế nó
- Nếu chưa có, nối vào cuối
- Giữ nội dung tối thiểu và thiết yếu

---

## Sau Init: Hiển thị tóm tắt

Sau khi sinh xong mọi file, xuất ra:

```
## PM2 Init Complete

**Services:**

| Port | Name | Type |
|------|------|------|
| {port} | {name} | {type} |

**Claude Commands:** /pm2-all, /pm2-all-stop, /pm2-{port}, /pm2-{port}-stop, /pm2-logs, /pm2-status

**Terminal Commands:**
## First time (with config file)
pm2 start ecosystem.config.cjs && pm2 save

## After first time (simplified)
pm2 start all          # Start all
pm2 stop all           # Stop all
pm2 restart all        # Restart all
pm2 start {name}       # Start single
pm2 stop {name}        # Stop single
pm2 logs               # View logs
pm2 monit              # Monitor panel
pm2 resurrect          # Restore saved processes

**Tip:** Run `pm2 save` after first start to enable simplified commands.
```
