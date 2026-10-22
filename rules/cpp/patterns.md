---
paths:
  - "**/*.cpp"
  - "**/*.hpp"
  - "**/*.cc"
  - "**/*.hh"
  - "**/*.cxx"
  - "**/*.h"
  - "**/CMakeLists.txt"
---
# Pattern C++

> File này mở rộng [common/patterns.md](../common/patterns.md) với nội dung dành riêng cho C++.

## RAII (Resource Acquisition Is Initialization)

Gắn vòng đời của tài nguyên với vòng đời của object:

```cpp
class FileHandle {
public:
    explicit FileHandle(const std::string& path) : file_(std::fopen(path.c_str(), "r")) {}
    ~FileHandle() { if (file_) std::fclose(file_); }
    FileHandle(const FileHandle&) = delete;
    FileHandle& operator=(const FileHandle&) = delete;
private:
    std::FILE* file_;
};
```

## Rule of Five/Zero

- **Rule of Zero**: Ưu tiên các class không cần destructor, copy/move constructor hoặc phép gán tùy chỉnh
- **Rule of Five**: Nếu bạn định nghĩa bất kỳ cái nào trong destructor/copy-ctor/copy-assign/move-ctor/move-assign, hãy định nghĩa cả năm

## Value Semantics

- Truyền các kiểu nhỏ/đơn giản (trivial) theo giá trị
- Truyền các kiểu lớn bằng `const&`
- Trả về theo giá trị (dựa vào RVO/NRVO)
- Dùng move semantics cho các sink parameter

## Xử lý lỗi

- Dùng exception cho các tình huống ngoại lệ
- Dùng `std::optional` cho các giá trị có thể không tồn tại
- Dùng `std::expected` (C++23) hoặc các result type cho các lỗi có thể dự đoán

## Tham chiếu

Xem skill: `cpp-coding-standards` để có các pattern và anti-pattern C++ toàn diện.
