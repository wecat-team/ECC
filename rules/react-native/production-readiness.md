---
paths:
  - "**/*.ts"
  - "**/*.tsx"
---
# Sẵn sàng cho Production với React Native / Expo

> Mở rộng triết lý của ECC sang các mối quan tâm ở mức ship-grade mà các rule về style/pattern không thể tự mã hóa.
> Một codebase sạch là cần thiết nhưng chưa đủ cho production — các mục này là bắt buộc trước khi release.

## Kiến trúc

- Phát hành trên **New Architecture** (Fabric + TurboModules). Nó là mặc định trong các Expo SDK gần đây và là bắt buộc (không thể tắt) từ SDK 55+. Rà soát các dependency native về tính tương thích.
- Ghim phiên bản Expo SDK; nâng cấp có chủ đích bằng `npx expo install --check` và test trên cả hai nền tảng.

## Build & Release (EAS)

- Dùng **EAS Build** cho binary production và **EAS Submit** để đưa lên store. Không dựa vào các bản build cục bộ tùy tiện để release.
- Giữ các build profile riêng (`development`, `preview`, `production`) trong `eas.json`.
- Quản lý credential ký (signing) qua EAS; KHÔNG BAO GIỜ commit keystore hoặc provisioning profile.

## Cập nhật Over-the-Air

- Dùng **EAS Update** (`expo-updates`) cho các bản sửa chỉ liên quan đến JS, với chính sách runtime version được xác định rõ.
- KHÔNG BAO GIỜ đẩy thay đổi native qua OTA — chúng yêu cầu một bản build store mới.
- Triển khai dần dần và giữ khả năng rollback.

## Observability

- Tích hợp báo cáo crash + lỗi (ví dụ **Sentry** qua `@sentry/react-native`) trong bản build production.
- Thêm structured logging và, khi hữu ích, analytics — nhưng loại bỏ log chi tiết khỏi bản release.
- Bắt và hiển thị các trạng thái network/mutation thất bại; không được thất bại trong im lặng.

## Cấu hình & Versioning

- Tăng `version` và `ios.buildNumber` / `android.versionCode` cho mỗi lần release.
- Cấu hình công khai qua `EXPO_PUBLIC_*`; secret thật chỉ qua EAS secrets.
- Validate cấu hình bắt buộc khi khởi động và fail fast với thông báo rõ ràng.

## Cổng kiểm tra trước Release

Trước khi phát hành, tất cả phải pass:

- [ ] `tsc --noEmit` sạch
- [ ] `npx expo lint` sạch
- [ ] Test xanh, coverage >= 80% (xem testing.md)
- [ ] `npx expo-doctor` khỏe mạnh
- [ ] E2E các flow quan trọng (Maestro/Detox) pass trên một bản build thật
- [ ] Không có secret trong bundle (xem security.md)
- [ ] Crash reporting đang hoạt động và đã được xác minh
- [ ] Đã test trên thiết bị iOS và Android thật, không chỉ simulator
