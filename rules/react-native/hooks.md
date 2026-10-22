---
paths:
  - "**/*.ts"
  - "**/*.tsx"
---
# Hook cho React Native / Expo

> File này mở rộng [common/hooks.md](../common/hooks.md) với hướng dẫn tự động hóa riêng cho React Native / Expo.

Đây là các tự động hóa PostToolUse được khuyến nghị để giữ code RN/Expo khỏe mạnh. Nối chúng vào hook runtime của bạn (hoặc chạy thủ công); điều chỉnh lệnh theo package manager của bạn.

## Các kiểm tra PostToolUse gợi ý (khi sửa *.ts/*.tsx)

- **Type check:** `tsc --noEmit` — bắt lỗi type sớm.
- **Lint:** `npx expo lint` (dùng `eslint-config-expo`; flat config `eslint.config.js` là mặc định từ SDK 53+).
- **Format:** `prettier --write` trên các file đã thay đổi.

## Trước release / định kỳ

- `npx expo-doctor` — kiểm tra tình trạng dependency native của Expo và cấu hình.
- `npx expo install --check` — giữ các dependency native khớp với Expo SDK đã cài.
- `npm audit` — quét lỗ hổng của dependency.

## Ghi chú

- Không chạy các bản build native nặng bên trong hook lúc sửa nhanh; giữ hook lúc sửa ở mức typecheck/lint/format.
- Dành `eas build` / E2E cho các lệnh tường minh hoặc CI, không dùng cho tự động hóa mỗi lần sửa.
- Giữ chúng nhất quán với các điều khiển hook runtime của ECC (`ECC_HOOK_PROFILE`, `ECC_DISABLED_HOOKS`).
