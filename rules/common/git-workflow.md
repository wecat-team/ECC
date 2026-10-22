# Quy trình Git

## Định dạng Commit Message
```
<type>: <description>

<optional body>
```

Type: feat, fix, refactor, docs, test, chore, perf, ci

Lưu ý: Các bản cài đặt do ECC quản lý đặt `"includeCoAuthoredBy": false` trong `~/.claude/settings.json`, nên commit mặc định không có trailer `Co-Authored-By`. Để giữ attribution của Claude, đặt `"includeCoAuthoredBy": true` hoặc cấu hình `attribution`; ECC không bao giờ ghi đè lựa chọn tường minh.

## Quy trình Pull Request

Khi tạo PR:
1. Phân tích toàn bộ lịch sử commit (không chỉ commit mới nhất)
2. Dùng `git diff [base-branch]...HEAD` để xem mọi thay đổi
3. Soạn tóm tắt PR đầy đủ
4. Bao gồm test plan kèm các TODO
5. Push với flag `-u` nếu là branch mới

> Để xem quy trình phát triển đầy đủ (lập kế hoạch, TDD, code review) trước các thao tác git,
> xem [development-workflow.md](./development-workflow.md).
