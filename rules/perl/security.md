---
paths:
  - "**/*.pl"
  - "**/*.pm"
  - "**/*.t"
  - "**/*.psgi"
  - "**/*.cgi"
---
# Bảo mật Perl

> File này mở rộng [common/security.md](../common/security.md) với nội dung dành riêng cho Perl.

## Taint Mode

- Dùng flag `-T` cho mọi script CGI/hướng web
- Sanitize `%ENV` (`$ENV{PATH}`, `$ENV{CDPATH}`, v.v.) trước mọi lệnh bên ngoài

## Kiểm tra đầu vào (Input Validation)

- Dùng regex allowlist để untaint — KHÔNG BAO GIỜ dùng `/(.*)/s`
- Validate mọi input của người dùng bằng các pattern tường minh:

```perl
if ($input =~ /\A([a-zA-Z0-9_-]+)\z/) {
    my $clean = $1;
}
```

## File I/O

- **Chỉ dùng open ba đối số** — KHÔNG BAO GIỜ dùng open hai đối số
- Ngăn path traversal bằng `Cwd::realpath`:

```perl
use Cwd 'realpath';
my $safe_path = realpath($user_path);
die "Path traversal" unless $safe_path =~ m{\A/allowed/directory/};
```

## Thực thi tiến trình

- Dùng **`system()` dạng danh sách** — KHÔNG BAO GIỜ dùng dạng một chuỗi
- Dùng **IPC::Run3** để bắt output
- KHÔNG BAO GIỜ dùng backtick với nội suy biến

```perl
system('grep', '-r', $pattern, $directory);  # safe
```

## Phòng chống SQL Injection

Luôn dùng placeholder của DBI — KHÔNG BAO GIỜ nội suy vào SQL:

```perl
my $sth = $dbh->prepare('SELECT * FROM users WHERE email = ?');
$sth->execute($email);
```

## Quét bảo mật

Chạy **perlcritic** với theme security ở severity 4+:

```bash
perlcritic --severity 4 --theme security lib/
```

## Tham chiếu

Xem skill: `perl-security` để có các pattern bảo mật Perl toàn diện, taint mode và I/O an toàn.
