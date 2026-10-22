---
paths:
  - "**/*.css"
  - "**/*.scss"
  - "**/*.sass"
  - "**/*.less"
  - "**/*.html"
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.vue"
  - "**/*.svelte"
---
> File này mở rộng [common/hooks.md](../common/hooks.md) với các khuyến nghị về hook riêng cho web.

# Hook Web

## Các hook PostToolUse được khuyến nghị

Ưu tiên công cụ cục bộ của dự án. Không nối hook với việc thực thi package từ xa dùng một lần.

### Format khi lưu

Dùng entrypoint formatter sẵn có của dự án sau khi sửa:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "command": "pnpm prettier --write \"$FILE_PATH\"",
        "description": "Format edited frontend files"
      }
    ]
  }
}
```

Các lệnh cục bộ tương đương qua `yarn prettier` hoặc `npm exec prettier --` đều ổn khi chúng dùng dependency do repo sở hữu.

### Kiểm tra Lint

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "command": "pnpm eslint --fix \"$FILE_PATH\"",
        "description": "Run ESLint on edited frontend files"
      }
    ]
  }
}
```

### Kiểm tra Type

Dùng `--incremental` để các lần chạy lại tái sử dụng `.tsbuildinfo` trước đó (1-3 giây trên code không đổi thay vì 30-60 giây mỗi lần). Bọc trong `timeout` để một tsc bị treo được OS dọn đi thay vì tích tụ qua các lần sửa — việc này ngăn tình trạng dồn nhiều process xảy ra khi các lần sửa kích hoạt nhanh hơn tốc độ tsc hoàn tất.

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "command": "timeout 60 pnpm tsc --noEmit --pretty false --incremental --tsBuildInfoFile node_modules/.cache/tsc-hook.tsbuildinfo",
        "description": "Type-check after frontend edits (incremental + timeout-capped)"
      }
    ]
  }
}
```

**Vì sao cả hai flag đều quan trọng:**
- Không có `--incremental`, mỗi lần sửa phải kiểm tra lại toàn bộ chương trình từ đầu. Trên một dự án Next.js thực tế, điều này chồng chất rất nhanh: sửa cách nhau 5-10 giây + tsc chạy 30-60 giây = N process tsc chạy đồng thời.
- Không có `timeout`, một tsc bị treo (thay đổi dependency bắc cầu, type-checker kẹt ở một type đệ quy) sẽ không bao giờ thoát và bị mồ côi khi shell cha thoát.
- `--tsBuildInfoFile` là bắt buộc vì `--noEmit` thường chặn việc ghi buildinfo; chỉ định đường dẫn tường minh giúp incremental tiếp tục hoạt động.

Nếu bạn dùng Windows không có GNU coreutils, hãy thay `timeout 60` bằng một wrapper PowerShell hoặc dựa vào hook Stop/SessionEnd để dọn các process tsc cũ.

### Lint CSS

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "command": "pnpm stylelint --fix \"$FILE_PATH\"",
        "description": "Lint edited stylesheets"
      }
    ]
  }
}
```

## Hook PreToolUse

### Chặn kích thước file

Chặn các lần ghi quá lớn dựa trên nội dung đầu vào của tool, không dựa trên một file có thể chưa tồn tại:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write",
        "command": "node -e \"let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{const i=JSON.parse(d);const c=i.tool_input?.content||'';const lines=c.split('\\n').length;if(lines>800){console.error('[Hook] BLOCKED: File exceeds 800 lines ('+lines+' lines)');console.error('[Hook] Split into smaller modules');process.exit(2)}console.log(d)})\"",
        "description": "Block writes that exceed 800 lines"
      }
    ]
  }
}
```

## Hook Stop

### Xác minh build cuối cùng

```json
{
  "hooks": {
    "Stop": [
      {
        "command": "pnpm build",
        "description": "Verify the production build at session end"
      }
    ]
  }
}
```

## Thứ tự

Thứ tự khuyến nghị:
1. format
2. lint
3. type check
4. xác minh build
