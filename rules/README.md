# Rules

## Cấu trúc

Các rule được tổ chức thành một tầng **common** cộng với các thư mục **riêng theo ngôn ngữ**:

```
rules/
├── common/          # Language-agnostic principles (always install)
│   ├── coding-style.md
│   ├── git-workflow.md
│   ├── testing.md
│   ├── performance.md
│   ├── patterns.md
│   ├── hooks.md
│   ├── agents.md
│   └── security.md
├── typescript/      # TypeScript/JavaScript specific
├── angular/         # Angular specific
├── vue/             # Vue 3 specific
├── nuxt/            # Nuxt 4 specific
├── python/          # Python specific
├── golang/          # Go specific
├── web/             # Web and frontend specific
├── react-native/    # React Native / Expo specific
├── swift/           # Swift specific
├── php/             # PHP specific
├── ruby/            # Ruby / Rails specific
└── arkts/           # HarmonyOS / ArkTS specific
```

- **common/** chứa các nguyên tắc phổ quát — không có ví dụ code riêng theo ngôn ngữ.
- **Các thư mục ngôn ngữ** mở rộng rule common bằng pattern, công cụ và ví dụ code riêng cho framework. Mỗi file tham chiếu tới file tương ứng trong common.

## Cài đặt

### Cách 1: Dùng script cài đặt (khuyến nghị)

```bash
# Cài common + một hoặc nhiều bộ rule riêng theo ngôn ngữ
./install.sh typescript
./install.sh angular
./install.sh vue
./install.sh nuxt
./install.sh python
./install.sh golang
./install.sh web
./install.sh react-native
./install.sh swift
./install.sh php
./install.sh ruby
./install.sh arkts

# Cài nhiều ngôn ngữ cùng lúc
./install.sh typescript python
```

### Cách 2: Cài đặt thủ công

> **Quan trọng:** Hãy sao chép nguyên cả thư mục — KHÔNG làm phẳng bằng `/*`.
> Thư mục common và các thư mục riêng theo ngôn ngữ chứa các file trùng tên.
> Làm phẳng chúng vào một thư mục sẽ khiến các file riêng theo ngôn ngữ ghi đè
> lên rule common, và phá vỡ các tham chiếu tương đối `../common/` mà các file
> riêng theo ngôn ngữ sử dụng.
>
> Hãy dùng namespace do ECC sở hữu bên dưới cho các bản cài Claude ở cấp người dùng. Các
> đích đến phẳng ở cấp package có thể xung đột với các rule pack không thuộc ECC và không
> khớp với hướng dẫn trong README chính.

```bash
# Create the ECC rule namespace once.
mkdir -p ~/.claude/rules/ecc

# Install common rules (required for all projects)
cp -r rules/common ~/.claude/rules/ecc/

# Install language-specific rules based on your project's tech stack
cp -r rules/typescript ~/.claude/rules/ecc/
cp -r rules/angular ~/.claude/rules/ecc/
cp -r rules/vue ~/.claude/rules/ecc/
cp -r rules/nuxt ~/.claude/rules/ecc/
cp -r rules/python ~/.claude/rules/ecc/
cp -r rules/golang ~/.claude/rules/ecc/
cp -r rules/web ~/.claude/rules/ecc/
cp -r rules/react-native ~/.claude/rules/ecc/
cp -r rules/swift ~/.claude/rules/ecc/
cp -r rules/php ~/.claude/rules/ecc/
cp -r rules/ruby ~/.claude/rules/ecc/
cp -r rules/arkts ~/.claude/rules/ecc/

# Attention ! ! ! Configure according to your actual project requirements; the configuration here is for reference only.
```

Với rule cục bộ của dự án, dùng cùng namespace đó dưới thư mục gốc của dự án:

```bash
mkdir -p .claude/rules/ecc
cp -r rules/common .claude/rules/ecc/
cp -r rules/typescript .claude/rules/ecc/
```

## Rules so với Skills

- **Rules** định nghĩa tiêu chuẩn, quy ước và checklist áp dụng rộng rãi (ví dụ "coverage test 80%", "không hardcode secret").
- **Skills** (thư mục `skills/`) cung cấp tài liệu tham khảo chuyên sâu, có thể áp dụng ngay cho các tác vụ cụ thể (ví dụ `python-patterns`, `golang-testing`).

Các file rule riêng theo ngôn ngữ tham chiếu tới các skill liên quan khi phù hợp. Rules cho biết _cần làm gì_; skills cho biết _làm như thế nào_.

## Thêm ngôn ngữ mới

Để thêm hỗ trợ cho một ngôn ngữ mới (ví dụ `rust/`):

1. Tạo thư mục `rules/rust/`
2. Thêm các file mở rộng rule common:
   - `coding-style.md` — công cụ định dạng, idiom, pattern xử lý lỗi
   - `testing.md` — test framework, công cụ coverage, cách tổ chức test
   - `patterns.md` — design pattern riêng theo ngôn ngữ
   - `hooks.md` — hook PostToolUse cho formatter, linter, type checker
   - `security.md` — quản lý secret, công cụ quét bảo mật
3. Mỗi file nên bắt đầu bằng:
   ```
   > This file extends [common/xxx.md](../common/xxx.md) with <Language> specific content.
   ```
4. Tham chiếu các skill hiện có nếu có, hoặc tạo skill mới trong `skills/`.

Với các miền không phải ngôn ngữ như `web/`, hãy theo cùng mô hình phân tầng khi có đủ hướng dẫn riêng cho miền đó có thể tái sử dụng để biện minh cho một ruleset độc lập.

## Độ ưu tiên của Rule

Khi rule riêng theo ngôn ngữ và rule common xung đột, **rule riêng theo ngôn ngữ được ưu tiên** (cái cụ thể ghi đè cái chung). Điều này theo mô hình cấu hình phân tầng tiêu chuẩn (tương tự độ đặc hiệu của CSS hoặc thứ tự ưu tiên của `.gitignore`).

- `rules/common/` định nghĩa các mặc định phổ quát áp dụng cho mọi dự án.
- `rules/golang/`, `rules/python/`, `rules/swift/`, `rules/php/`, `rules/typescript/`, `rules/react-native/`, v.v. ghi đè các mặc định đó ở những chỗ idiom của ngôn ngữ khác biệt.

### Ví dụ

`common/coding-style.md` khuyến nghị tính bất biến (immutability) như một nguyên tắc mặc định. File `golang/coding-style.md` riêng cho ngôn ngữ có thể ghi đè điều này:

> Go idiomatic dùng pointer receiver để thay đổi struct — xem [common/coding-style.md](common/coding-style.md) để biết nguyên tắc chung, nhưng ở đây ưu tiên cách thay đổi theo kiểu Go idiomatic.

### Rule common có ghi chú ghi đè

Các rule trong `rules/common/` có thể bị file riêng theo ngôn ngữ ghi đè được đánh dấu bằng:

> **Language note**: This rule may be overridden by language-specific rules for languages where this pattern is not idiomatic.
