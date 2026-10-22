---
paths:
  - "**/*.pl"
  - "**/*.pm"
  - "**/*.t"
  - "**/*.psgi"
  - "**/*.cgi"
---
# Pattern Perl

> File này mở rộng [common/patterns.md](../common/patterns.md) với nội dung dành riêng cho Perl.

## Repository Pattern

Dùng **DBI** hoặc **DBIx::Class** sau một interface:

```perl
package MyApp::Repo::User;
use Moo;

has dbh => (is => 'ro', required => 1);

sub find_by_id ($self, $id) {
    my $sth = $self->dbh->prepare('SELECT * FROM users WHERE id = ?');
    $sth->execute($id);
    return $sth->fetchrow_hashref;
}
```

## DTO / Value Object

Dùng class **Moo** với **Types::Standard** (tương đương dataclass của Python):

```perl
package MyApp::DTO::User;
use Moo;
use Types::Standard qw(Str Int);

has name  => (is => 'ro', isa => Str, required => 1);
has email => (is => 'ro', isa => Str, required => 1);
has age   => (is => 'ro', isa => Int);
```

## Quản lý tài nguyên

- Luôn dùng **open ba đối số** với `autodie`
- Dùng **Path::Tiny** cho các thao tác file

```perl
use autodie;
use Path::Tiny;

my $content = path('config.json')->slurp_utf8;
```

## Interface của Module

Dùng `Exporter 'import'` với `@EXPORT_OK` — KHÔNG BAO GIỜ dùng `@EXPORT`:

```perl
use Exporter 'import';
our @EXPORT_OK = qw(parse_config validate_input);
```

## Quản lý Dependency

Dùng **cpanfile** + **carton** để cài đặt có thể tái lập:

```bash
carton install
carton exec prove -lr t/
```

## Tham chiếu

Xem skill: `perl-patterns` để có các pattern và idiom Perl hiện đại toàn diện.
