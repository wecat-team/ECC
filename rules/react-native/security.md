---
paths:
  - "**/*.ts"
  - "**/*.tsx"
---
# Bảo mật React Native / Expo

> File này mở rộng [common/security.md](../common/security.md) với nội dung riêng cho React Native / Expo.
> Checklist bắt buộc trước khi commit và Security Response Protocol trong common/security.md vẫn được áp dụng.

## Bundle là công khai

Hãy coi mọi thứ được đóng gói trong app là kẻ tấn công có thể đọc được. Một binary di động có thể bị giải nén.

- KHÔNG BAO GIỜ đưa secret thật (API key riêng tư, service-role key, signing secret) vào JS bundle hoặc `app.config`.
- Public/anon key (ví dụ Supabase anon key, cấu hình Firebase) chỉ chấp nhận được KHI được bảo vệ bằng rule phía server (RLS, security rule). Thực thi phân quyền (authorization) ở backend, không bao giờ ở client.
- Giữ các thao tác đặc quyền phía sau server / edge function của riêng bạn.

## Lưu trữ secret và token

- Lưu auth token và các giá trị nhạy cảm trong `expo-secure-store` (Keychain / Keystore) — không bao giờ lưu trong `AsyncStorage` hay MMKV thuần.
- Không lưu secret bền vững trong state Redux/Zustand có thể bị serialize xuống đĩa.

## Cấu hình

- Đọc biến môi trường qua `expo-constants` / `extra` của `app.config.ts`, và chỉ dùng `EXPO_PUBLIC_*` cho các giá trị thực sự công khai.
- Giữ build secret trong EAS secrets, không để trong repo.

## Mạng và dữ liệu

- Chỉ dùng HTTPS; từ chối cleartext. Cân nhắc certificate pinning cho các app rủi ro cao.
- Kiểm tra (validate) TOÀN BỘ dữ liệu bên ngoài (API response, tham số deep link, push payload) bằng Zod trước khi dùng.
- Kiểm tra và làm sạch (sanitize) deep link và universal link — không bao giờ điều hướng hay cấp quyền truy cập dựa trên tham số chưa được kiểm tra.

## Quyền và quyền riêng tư

- Chỉ yêu cầu quyền thiết bị tối thiểu, vào đúng thời điểm cần, kèm lý do rõ ràng.
- Khai báo việc thu thập dữ liệu chính xác cho phần công bố quyền riêng tư trên App Store / Play Store.

## Dependency

- Chạy `expo-doctor` và `npm audit` thường xuyên; giữ Expo SDK và các dependency native luôn cập nhật.
- Dùng `/security-scan` (AgentShield) trên chính cấu hình agent.
