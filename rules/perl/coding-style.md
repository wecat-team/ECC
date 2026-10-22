---
paths:
  - "**/*.pl"
  - "**/*.pm"
  - "**/*.t"
  - "**/*.psgi"
  - "**/*.cgi"
---
# Phong cách code Perl

> File này mở rộng [common/coding-style.md](../common/coding-style.md) với nội dung dành riêng cho Perl.

## Tiêu chuẩn

- Luôn `use v5.36` (bật `strict`, `warnings`, `say`, subroutine signature)
- Dùng subroutine signature — KHÔNG BAO GIỜ giải nén `@_` thủ công
- Ưu tiên `say` hơn `print` kèm newline tường minh

## Bất biến (Immutability)

- Dùng **Moo** với `is => 'ro'` và `Types::Standard` cho mọi attribute
- KHÔNG BAO GIỜ dùng trực tiếp blessed hashref — luôn dùng accessor của Moo/Moose
- **Lưu ý ngoại lệ OO**: Các attribute `has` của Moo có `builder` hoặc `default` được chấp nhận cho các giá trị chỉ đọc được tính toán

## Định dạng

Dùng **perltidy** với các thiết lập sau:

```
-i=4    # 4-space indent
-l=100  # 100 char line length
-ce     # cuddled else
-bar    # opening brace always right
```

## Linting

Dùng **perlcritic** ở severity 3 với các theme: `core`, `pbp`, `security`.

```bash
perlcritic --severity 3 --theme 'core || pbp || security' lib/
```

## Tham chiếu

Xem skill: `perl-patterns` để có các idiom và best practice Perl hiện đại toàn diện.
