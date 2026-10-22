---
name: perl-testing
description: Các pattern kiểm thử Perl dùng Test2::V0, Test::More, prove runner, mocking, coverage với Devel::Cover và phương pháp TDD. Dùng khi viết test Perl bằng Test2::V0 hoặc Test::More, hoặc đo coverage.
metadata:
  origin: ECC
---

# Pattern kiểm thử Perl

Chiến lược kiểm thử toàn diện cho ứng dụng Perl dùng Test2::V0, Test::More, prove và phương pháp TDD.

## Khi nào kích hoạt

- Viết code Perl mới (theo TDD: red, green, refactor)
- Thiết kế test suite cho module hoặc ứng dụng Perl
- Review test coverage của Perl
- Thiết lập hạ tầng kiểm thử Perl
- Migrate test từ Test::More sang Test2::V0
- Debug các test Perl bị fail

## Quy trình TDD

Luôn tuân theo chu trình RED-GREEN-REFACTOR.

```perl
# Step 1: RED — Write a failing test
# t/unit/calculator.t
use v5.36;
use Test2::V0;

use lib 'lib';
use Calculator;

subtest 'addition' => sub {
    my $calc = Calculator->new;
    is($calc->add(2, 3), 5, 'adds two numbers');
    is($calc->add(-1, 1), 0, 'handles negatives');
};

done_testing;

# Step 2: GREEN — Write minimal implementation
# lib/Calculator.pm
package Calculator;
use v5.36;
use Moo;

sub add($self, $a, $b) {
    return $a + $b;
}

1;

# Step 3: REFACTOR — Improve while tests stay green
# Run: prove -lv t/unit/calculator.t
```

## Nền tảng Test::More

Module kiểm thử chuẩn của Perl — được dùng rộng rãi, đi kèm core.

### Assertion cơ bản

```perl
use v5.36;
use Test::More;

# Plan upfront or use done_testing
# plan tests => 5;  # Fixed plan (optional)

# Equality
is($result, 42, 'returns correct value');
isnt($result, 0, 'not zero');

# Boolean
ok($user->is_active, 'user is active');
ok(!$user->is_banned, 'user is not banned');

# Deep comparison
is_deeply(
    $got,
    { name => 'Alice', roles => ['admin'] },
    'returns expected structure'
);

# Pattern matching
like($error, qr/not found/i, 'error mentions not found');
unlike($output, qr/password/, 'output hides password');

# Type check
isa_ok($obj, 'MyApp::User');
can_ok($obj, 'save', 'delete');

done_testing;
```

### SKIP và TODO

```perl
use v5.36;
use Test::More;

# Skip tests conditionally
SKIP: {
    skip 'No database configured', 2 unless $ENV{TEST_DB};

    my $db = connect_db();
    ok($db->ping, 'database is reachable');
    is($db->version, '15', 'correct PostgreSQL version');
}

# Mark expected failures
TODO: {
    local $TODO = 'Caching not yet implemented';
    is($cache->get('key'), 'value', 'cache returns value');
}

done_testing;
```

## Framework hiện đại Test2::V0

Test2::V0 là sự thay thế hiện đại cho Test::More — assertion phong phú hơn, chẩn đoán tốt hơn và có thể mở rộng.

### Tại sao chọn Test2?

- So sánh sâu (deep comparison) vượt trội với hash/array builder
- Output chẩn đoán tốt hơn khi fail
- Subtest với phạm vi (scoping) gọn gàng hơn
- Mở rộng được qua các plugin Test2::Tools::*
- Tương thích ngược với test Test::More

### So sánh sâu với Builder

```perl
use v5.36;
use Test2::V0;

# Hash builder — check partial structure
is(
    $user->to_hash,
    hash {
        field name  => 'Alice';
        field email => match(qr/\@example\.com$/);
        field age   => validator(sub { $_ >= 18 });
        # Ignore other fields
        etc();
    },
    'user has expected fields'
);

# Array builder
is(
    $result,
    array {
        item 'first';
        item match(qr/^second/);
        item DNE();  # Does Not Exist — verify no extra items
    },
    'result matches expected list'
);

# Bag — order-independent comparison
is(
    $tags,
    bag {
        item 'perl';
        item 'testing';
        item 'tdd';
    },
    'has all required tags regardless of order'
);
```

### Subtest

```perl
use v5.36;
use Test2::V0;

subtest 'User creation' => sub {
    my $user = User->new(name => 'Alice', email => 'alice@example.com');
    ok($user, 'user object created');
    is($user->name, 'Alice', 'name is set');
    is($user->email, 'alice@example.com', 'email is set');
};

subtest 'User validation' => sub {
    my $warnings = warns {
        User->new(name => '', email => 'bad');
    };
    ok($warnings, 'warns on invalid data');
};

done_testing;
```

### Kiểm thử Exception với Test2

```perl
use v5.36;
use Test2::V0;

# Test that code dies
like(
    dies { divide(10, 0) },
    qr/Division by zero/,
    'dies on division by zero'
);

# Test that code lives
ok(lives { divide(10, 2) }, 'division succeeds') or note($@);

# Combined pattern
subtest 'error handling' => sub {
    ok(lives { parse_config('valid.json') }, 'valid config parses');
    like(
        dies { parse_config('missing.json') },
        qr/Cannot open/,
        'missing file dies with message'
    );
};

done_testing;
```

## Tổ chức test và prove

### Cấu trúc thư mục

```text
t/
├── 00-load.t              # Verify modules compile
├── 01-basic.t             # Core functionality
├── unit/
│   ├── config.t           # Unit tests by module
│   ├── user.t
│   └── util.t
├── integration/
│   ├── database.t
│   └── api.t
├── lib/
│   └── TestHelper.pm      # Shared test utilities
└── fixtures/
    ├── config.json        # Test data files
    └── users.csv
```

### Lệnh prove

```bash
# Run all tests
prove -l t/

# Verbose output
prove -lv t/

# Run specific test
prove -lv t/unit/user.t

# Recursive search
prove -lr t/

# Parallel execution (8 jobs)
prove -lr -j8 t/

# Run only failing tests from last run
prove -l --state=failed t/

# Colored output with timer
prove -l --color --timer t/

# TAP output for CI
prove -l --formatter TAP::Formatter::JUnit t/ > results.xml
```

### Cấu hình .proverc

```text
-l
--color
--timer
-r
-j4
--state=save
```

## Fixture và Setup/Teardown

### Cô lập bằng Subtest

```perl
use v5.36;
use Test2::V0;
use File::Temp qw(tempdir);
use Path::Tiny;

subtest 'file processing' => sub {
    # Setup
    my $dir = tempdir(CLEANUP => 1);
    my $file = path($dir, 'input.txt');
    $file->spew_utf8("line1\nline2\nline3\n");

    # Test
    my $result = process_file("$file");
    is($result->{line_count}, 3, 'counts lines');

    # Teardown happens automatically (CLEANUP => 1)
};
```

### Test Helper dùng chung

Đặt các helper tái sử dụng trong `t/lib/TestHelper.pm` và nạp bằng `use lib 't/lib'`. Export các factory function như `create_test_db()`, `create_temp_dir()` và `fixture_path()` qua `Exporter`.

## Mocking

### Test::MockModule

```perl
use v5.36;
use Test2::V0;
use Test::MockModule;

subtest 'mock external API' => sub {
    my $mock = Test::MockModule->new('MyApp::API');

    # Good: Mock returns controlled data
    $mock->mock(fetch_user => sub ($self, $id) {
        return { id => $id, name => 'Mock User', email => 'mock@test.com' };
    });

    my $api = MyApp::API->new;
    my $user = $api->fetch_user(42);
    is($user->{name}, 'Mock User', 'returns mocked user');

    # Verify call count
    my $call_count = 0;
    $mock->mock(fetch_user => sub { $call_count++; return {} });
    $api->fetch_user(1);
    $api->fetch_user(2);
    is($call_count, 2, 'fetch_user called twice');

    # Mock is automatically restored when $mock goes out of scope
};

# Bad: Monkey-patching without restoration
# *MyApp::API::fetch_user = sub { ... };  # NEVER — leaks across tests
```

Với mock object nhẹ, dùng `Test::MockObject` để tạo các test double có thể inject với `->mock()` và verify các lời gọi bằng `->called_ok()`.

## Coverage với Devel::Cover

### Chạy Coverage

```bash
# Basic coverage report
cover -test

# Or step by step
perl -MDevel::Cover -Ilib t/unit/user.t
cover

# HTML report
cover -report html
open cover_db/coverage.html

# Specific thresholds
cover -test -report text | grep 'Total'

# CI-friendly: fail under threshold
cover -test && cover -report text -select '^lib/' \
  | perl -ne 'if (/Total.*?(\d+\.\d+)/) { exit 1 if $1 < 80 }'
```

### Integration Testing

Dùng SQLite in-memory cho test database, mock HTTP::Tiny cho test API.

```perl
use v5.36;
use Test2::V0;
use DBI;

subtest 'database integration' => sub {
    my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '', {
        RaiseError => 1,
    });
    $dbh->do('CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)');

    $dbh->prepare('INSERT INTO users (name) VALUES (?)')->execute('Alice');
    my $row = $dbh->selectrow_hashref('SELECT * FROM users WHERE name = ?', undef, 'Alice');
    is($row->{name}, 'Alice', 'inserted and retrieved user');
};

done_testing;
```

## Best Practice

### NÊN

- **Tuân theo TDD**: Viết test trước phần triển khai (red-green-refactor)
- **Dùng Test2::V0**: Assertion hiện đại, chẩn đoán tốt hơn
- **Dùng subtest**: Nhóm các assertion liên quan, cô lập state
- **Mock các dependency bên ngoài**: Mạng, database, file system
- **Dùng `prove -l`**: Luôn đưa lib/ vào `@INC`
- **Đặt tên test rõ ràng**: `'user login with invalid password fails'`
- **Test edge case**: Chuỗi rỗng, undef, zero, giá trị biên
- **Hướng tới coverage 80%+**: Tập trung vào các đường business logic
- **Giữ test nhanh**: Mock I/O, dùng database in-memory

### KHÔNG NÊN

- **Không test phần triển khai**: Hãy test hành vi và output, không phải phần nội bộ
- **Không chia sẻ state giữa các subtest**: Mỗi subtest phải độc lập
- **Không bỏ qua `done_testing`**: Đảm bảo mọi test đã lên kế hoạch đều chạy
- **Không mock quá mức**: Chỉ mock ở ranh giới, không mock code đang được test
- **Không dùng `Test::More` cho dự án mới**: Ưu tiên Test2::V0
- **Không bỏ qua test fail**: Mọi test phải pass trước khi merge
- **Không test module CPAN**: Hãy tin các thư viện hoạt động đúng
- **Không viết test dễ vỡ**: Tránh so khớp chuỗi quá cụ thể

## Tham chiếu nhanh

| Tác vụ | Lệnh / Pattern |
|---|---|
| Chạy mọi test | `prove -lr t/` |
| Chạy một test ở chế độ verbose | `prove -lv t/unit/user.t` |
| Chạy test song song | `prove -lr -j8 t/` |
| Báo cáo coverage | `cover -test && cover -report html` |
| Test bằng nhau | `is($got, $expected, 'label')` |
| So sánh sâu | `is($got, hash { field k => 'v'; etc() }, 'label')` |
| Test exception | `like(dies { ... }, qr/msg/, 'label')` |
| Test không có exception | `ok(lives { ... }, 'label')` |
| Mock một method | `Test::MockModule->new('Pkg')->mock(m => sub { ... })` |
| Bỏ qua test | `SKIP: { skip 'reason', $count unless $cond; ... }` |
| Test TODO | `TODO: { local $TODO = 'reason'; ... }` |

## Cạm bẫy thường gặp

### Quên `done_testing`

```perl
# Bad: Test file runs but doesn't verify all tests executed
use Test2::V0;
is(1, 1, 'works');
# Missing done_testing — silent bugs if test code is skipped

# Good: Always end with done_testing
use Test2::V0;
is(1, 1, 'works');
done_testing;
```

### Thiếu cờ `-l`

```bash
# Bad: Modules in lib/ not found
prove t/unit/user.t
# Can't locate MyApp/User.pm in @INC

# Good: Include lib/ in @INC
prove -l t/unit/user.t
```

### Mock quá mức

Hãy mock *dependency*, không mock code đang được test. Nếu test của bạn chỉ verify rằng một mock trả về đúng thứ bạn bảo nó trả về, thì nó chẳng test gì cả.

### Ô nhiễm test (Test Pollution)

Dùng biến `my` bên trong subtest — không bao giờ dùng `our` — để ngăn state rò rỉ giữa các test.

**Hãy nhớ**: Test là lưới an toàn của bạn. Giữ chúng nhanh, tập trung và độc lập. Dùng Test2::V0 cho dự án mới, prove để chạy và Devel::Cover để chịu trách nhiệm về coverage.
