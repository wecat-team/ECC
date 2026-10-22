---
paths:
  - "**/*.pl"
  - "**/*.pm"
  - "**/*.t"
  - "**/*.psgi"
  - "**/*.cgi"
---
# Kiểm thử Perl

> File này mở rộng [common/testing.md](../common/testing.md) với nội dung dành riêng cho Perl.

## Framework

Dùng **Test2::V0** cho dự án mới (không dùng Test::More):

```perl
use Test2::V0;

is($result, 42, 'answer is correct');

done_testing;
```

## Runner

```bash
prove -l t/              # adds lib/ to @INC
prove -lr -j8 t/         # recursive, 8 parallel jobs
```

Luôn dùng `-l` để đảm bảo `lib/` nằm trong `@INC`.

## Coverage

Dùng **Devel::Cover** — mục tiêu 80%+:

```bash
cover -test
```

## Mocking

- **Test::MockModule** — mock method trên các module có sẵn
- **Test::MockObject** — tạo test double từ đầu

## Cạm bẫy

- Luôn kết thúc file test bằng `done_testing`
- KHÔNG BAO GIỜ quên flag `-l` với `prove`

## Tham chiếu

Xem skill: `perl-testing` để có các pattern TDD Perl chi tiết với Test2::V0, prove và Devel::Cover.
