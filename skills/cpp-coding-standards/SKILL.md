---
name: cpp-coding-standards
description: Tiêu chuẩn coding C++ dựa trên C++ Core Guidelines (isocpp.github.io). Dùng khi viết, review hoặc refactor code C++ để thực thi các thực hành hiện đại, an toàn và idiomatic.
metadata:
  origin: ECC
---

# Tiêu chuẩn Coding C++ (C++ Core Guidelines)

Tiêu chuẩn coding toàn diện cho C++ hiện đại (C++17/20/23) được rút ra từ [C++ Core Guidelines](https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines). Thực thi type safety, resource safety, tính bất biến (immutable) và sự rõ ràng.

## Khi nào dùng

- Viết code C++ mới (class, hàm, template)
- Review hoặc refactor code C++ hiện có
- Đưa ra các quyết định kiến trúc trong dự án C++
- Thực thi phong cách nhất quán trên một codebase C++
- Lựa chọn giữa các tính năng ngôn ngữ (ví dụ `enum` vs `enum class`, raw pointer vs smart pointer)

### Khi nào KHÔNG dùng

- Dự án không phải C++
- Codebase C legacy không thể áp dụng các tính năng C++ hiện đại
- Ngữ cảnh embedded/bare-metal nơi một số guideline xung đột với ràng buộc phần cứng (hãy áp dụng có chọn lọc)

## Nguyên tắc xuyên suốt

Các chủ đề này lặp lại xuyên suốt toàn bộ guideline và tạo thành nền tảng:

1. **RAII ở mọi nơi** (P.8, R.1, E.6, CP.20): Gắn vòng đời tài nguyên với vòng đời đối tượng
2. **Bất biến (immutable) theo mặc định** (P.10, Con.1-5, ES.25): Bắt đầu với `const`/`constexpr`; tính khả biến là ngoại lệ
3. **Type safety** (P.4, I.4, ES.46-49, Enum.3): Dùng hệ thống type để ngăn lỗi ngay lúc compile
4. **Thể hiện ý định** (P.3, F.1, NL.1-2, T.10): Tên, type và concept nên truyền đạt mục đích
5. **Giảm thiểu độ phức tạp** (F.2-3, ES.5, Per.4-5): Code đơn giản là code đúng
6. **Value semantics hơn pointer semantics** (C.10, R.3-5, F.20, CP.31): Ưu tiên trả về theo giá trị và các đối tượng có scope

## Triết lý & Interface (P.*, I.*)

### Các rule chính

| Rule | Tóm tắt |
|------|---------|
| **P.1** | Thể hiện ý tưởng trực tiếp trong code |
| **P.3** | Thể hiện ý định |
| **P.4** | Lý tưởng nhất, một chương trình nên an toàn về type một cách tĩnh |
| **P.5** | Ưu tiên kiểm tra lúc compile hơn kiểm tra lúc chạy |
| **P.8** | Đừng làm rò rỉ bất kỳ tài nguyên nào |
| **P.10** | Ưu tiên dữ liệu bất biến hơn dữ liệu khả biến |
| **I.1** | Làm cho interface tường minh |
| **I.2** | Tránh biến global không phải const |
| **I.4** | Làm cho interface có type chính xác và mạnh |
| **I.11** | KHÔNG BAO GIỜ chuyển quyền sở hữu bằng raw pointer hoặc reference |
| **I.23** | Giữ số lượng tham số hàm ở mức thấp |

### NÊN

```cpp
// P.10 + I.4: Immutable, strongly typed interface
struct Temperature {
    double kelvin;
};

Temperature boil(const Temperature& water);
```

### KHÔNG NÊN

```cpp
// Weak interface: unclear ownership, unclear units
double boil(double* temp);

// Non-const global variable
int g_counter = 0;  // I.2 violation
```

## Hàm (F.*)

### Các rule chính

| Rule | Tóm tắt |
|------|---------|
| **F.1** | Đóng gói các thao tác có ý nghĩa thành các hàm được đặt tên cẩn thận |
| **F.2** | Một hàm nên thực hiện một thao tác logic duy nhất |
| **F.3** | Giữ hàm ngắn và đơn giản |
| **F.4** | Nếu một hàm có thể được đánh giá lúc compile, hãy khai báo nó `constexpr` |
| **F.6** | Nếu hàm của bạn không được phép throw, hãy khai báo nó `noexcept` |
| **F.8** | Ưu tiên hàm thuần (pure function) |
| **F.16** | Với tham số "in", truyền các type copy rẻ theo giá trị và các type còn lại theo `const&` |
| **F.20** | Với giá trị "out", ưu tiên giá trị trả về hơn tham số output |
| **F.21** | Để trả về nhiều giá trị "out", ưu tiên trả về một struct |
| **F.43** | KHÔNG BAO GIỜ trả về pointer hoặc reference tới một đối tượng cục bộ |

### Truyền tham số

```cpp
// F.16: Cheap types by value, others by const&
void print(int x);                           // cheap: by value
void analyze(const std::string& data);       // expensive: by const&
void transform(std::string s);               // sink: by value (will move)

// F.20 + F.21: Return values, not output parameters
struct ParseResult {
    std::string token;
    int position;
};

ParseResult parse(std::string_view input);   // GOOD: return struct

// BAD: output parameters
void parse(std::string_view input,
           std::string& token, int& pos);    // avoid this
```

### Hàm thuần và constexpr

```cpp
// F.4 + F.8: Pure, constexpr where possible
constexpr int factorial(int n) noexcept {
    return (n <= 1) ? 1 : n * factorial(n - 1);
}

static_assert(factorial(5) == 120);
```

### Anti-Pattern

- Trả về `T&&` từ hàm (F.45)
- Dùng `va_arg` / variadic kiểu C (F.55)
- Capture theo reference trong lambda được truyền cho thread khác (F.53)
- Trả về `const T` làm cản trở move semantics (F.49)

## Class & Phân cấp Class (C.*)

### Các rule chính

| Rule | Tóm tắt |
|------|---------|
| **C.2** | Dùng `class` nếu tồn tại invariant; `struct` nếu các data member biến đổi độc lập |
| **C.9** | Giảm thiểu việc phơi bày member |
| **C.20** | Nếu có thể tránh định nghĩa các thao tác mặc định, hãy tránh (Rule of Zero) |
| **C.21** | Nếu bạn định nghĩa hoặc `=delete` bất kỳ copy/move/destructor nào, hãy xử lý tất cả (Rule of Five) |
| **C.35** | Destructor của base class: public virtual hoặc protected non-virtual |
| **C.41** | Một constructor nên tạo ra một đối tượng được khởi tạo đầy đủ |
| **C.46** | Khai báo constructor một tham số là `explicit` |
| **C.67** | Một class đa hình nên chặn copy/move công khai |
| **C.128** | Hàm virtual: chỉ định đúng một trong `virtual`, `override` hoặc `final` |

### Rule of Zero

```cpp
// C.20: Let the compiler generate special members
struct Employee {
    std::string name;
    std::string department;
    int id;
    // No destructor, copy/move constructors, or assignment operators needed
};
```

### Rule of Five

```cpp
// C.21: If you must manage a resource, define all five
class Buffer {
public:
    explicit Buffer(std::size_t size)
        : data_(std::make_unique<char[]>(size)), size_(size) {}

    ~Buffer() = default;

    Buffer(const Buffer& other)
        : data_(std::make_unique<char[]>(other.size_)), size_(other.size_) {
        std::copy_n(other.data_.get(), size_, data_.get());
    }

    Buffer& operator=(const Buffer& other) {
        if (this != &other) {
            auto new_data = std::make_unique<char[]>(other.size_);
            std::copy_n(other.data_.get(), other.size_, new_data.get());
            data_ = std::move(new_data);
            size_ = other.size_;
        }
        return *this;
    }

    Buffer(Buffer&&) noexcept = default;
    Buffer& operator=(Buffer&&) noexcept = default;

private:
    std::unique_ptr<char[]> data_;
    std::size_t size_;
};
```

### Phân cấp Class

```cpp
// C.35 + C.128: Virtual destructor, use override
class Shape {
public:
    virtual ~Shape() = default;
    virtual double area() const = 0;  // C.121: pure interface
};

class Circle : public Shape {
public:
    explicit Circle(double r) : radius_(r) {}
    double area() const override { return 3.14159 * radius_ * radius_; }

private:
    double radius_;
};
```

### Anti-Pattern

- Gọi hàm virtual trong constructor/destructor (C.82)
- Dùng `memset`/`memcpy` trên các type không tầm thường (C.90)
- Cung cấp các đối số mặc định khác nhau cho hàm virtual và hàm override nó (C.140)
- Biến data member thành `const` hoặc reference, làm chặn move/copy (C.12)

## Quản lý tài nguyên (R.*)

### Các rule chính

| Rule | Tóm tắt |
|------|---------|
| **R.1** | Quản lý tài nguyên tự động bằng RAII |
| **R.3** | Một raw pointer (`T*`) là không sở hữu (non-owning) |
| **R.5** | Ưu tiên các đối tượng có scope; đừng cấp phát heap không cần thiết |
| **R.10** | Tránh `malloc()`/`free()` |
| **R.11** | Tránh gọi `new` và `delete` một cách tường minh |
| **R.20** | Dùng `unique_ptr` hoặc `shared_ptr` để biểu diễn quyền sở hữu |
| **R.21** | Ưu tiên `unique_ptr` hơn `shared_ptr` trừ khi chia sẻ quyền sở hữu |
| **R.22** | Dùng `make_shared()` để tạo `shared_ptr` |

### Cách dùng Smart Pointer

```cpp
// R.11 + R.20 + R.21: RAII with smart pointers
auto widget = std::make_unique<Widget>("config");  // unique ownership
auto cache  = std::make_shared<Cache>(1024);        // shared ownership

// R.3: Raw pointer = non-owning observer
void render(const Widget* w) {  // does NOT own w
    if (w) w->draw();
}

render(widget.get());
```

### Pattern RAII

```cpp
// R.1: Resource acquisition is initialization
class FileHandle {
public:
    explicit FileHandle(const std::string& path)
        : handle_(std::fopen(path.c_str(), "r")) {
        if (!handle_) throw std::runtime_error("Failed to open: " + path);
    }

    ~FileHandle() {
        if (handle_) std::fclose(handle_);
    }

    FileHandle(const FileHandle&) = delete;
    FileHandle& operator=(const FileHandle&) = delete;
    FileHandle(FileHandle&& other) noexcept
        : handle_(std::exchange(other.handle_, nullptr)) {}
    FileHandle& operator=(FileHandle&& other) noexcept {
        if (this != &other) {
            if (handle_) std::fclose(handle_);
            handle_ = std::exchange(other.handle_, nullptr);
        }
        return *this;
    }

private:
    std::FILE* handle_;
};
```

### Anti-Pattern

- `new`/`delete` trần (R.11)
- `malloc()`/`free()` trong code C++ (R.10)
- Nhiều lần cấp phát tài nguyên trong một biểu thức duy nhất (R.13 -- nguy cơ về exception safety)
- `shared_ptr` ở nơi `unique_ptr` là đủ (R.21)

## Biểu thức & Câu lệnh (ES.*)

### Các rule chính

| Rule | Tóm tắt |
|------|---------|
| **ES.5** | Giữ scope nhỏ |
| **ES.20** | Luôn khởi tạo một đối tượng |
| **ES.23** | Ưu tiên cú pháp khởi tạo `{}` |
| **ES.25** | Khai báo đối tượng `const` hoặc `constexpr` trừ khi có ý định sửa đổi |
| **ES.28** | Dùng lambda để khởi tạo phức tạp cho các biến `const` |
| **ES.45** | Tránh hằng số ma thuật; dùng hằng số có tên |
| **ES.46** | Tránh các phép chuyển đổi số học narrowing/mất dữ liệu |
| **ES.47** | Dùng `nullptr` thay vì `0` hoặc `NULL` |
| **ES.48** | Tránh cast |
| **ES.50** | Đừng cast bỏ `const` |

### Khởi tạo

```cpp
// ES.20 + ES.23 + ES.25: Always initialize, prefer {}, default to const
const int max_retries{3};
const std::string name{"widget"};
const std::vector<int> primes{2, 3, 5, 7, 11};

// ES.28: Lambda for complex const initialization
const auto config = [&] {
    Config c;
    c.timeout = std::chrono::seconds{30};
    c.retries = max_retries;
    c.verbose = debug_mode;
    return c;
}();
```

### Anti-Pattern

- Biến chưa khởi tạo (ES.20)
- Dùng `0` hoặc `NULL` làm pointer (ES.47 -- dùng `nullptr`)
- Cast kiểu C (ES.48 -- dùng `static_cast`, `const_cast`, v.v.)
- Cast bỏ `const` (ES.50)
- Magic number không có hằng số có tên (ES.45)
- Trộn số học signed và unsigned (ES.100)
- Dùng lại tên trong các scope lồng nhau (ES.12)

## Xử lý lỗi (E.*)

### Các rule chính

| Rule | Tóm tắt |
|------|---------|
| **E.1** | Phát triển chiến lược xử lý lỗi sớm trong thiết kế |
| **E.2** | Throw một exception để báo hiệu rằng một hàm không thể thực hiện nhiệm vụ được giao |
| **E.6** | Dùng RAII để ngăn rò rỉ |
| **E.12** | Dùng `noexcept` khi việc throw là bất khả thi hoặc không thể chấp nhận |
| **E.14** | Dùng các type do người dùng định nghĩa có mục đích thiết kế riêng làm exception |
| **E.15** | Throw theo giá trị, catch theo reference |
| **E.16** | Destructor, giải phóng bộ nhớ và swap không bao giờ được thất bại |
| **E.17** | Đừng cố catch mọi exception trong mọi hàm |

### Phân cấp Exception

```cpp
// E.14 + E.15: Custom exception types, throw by value, catch by reference
class AppError : public std::runtime_error {
public:
    using std::runtime_error::runtime_error;
};

class NetworkError : public AppError {
public:
    NetworkError(const std::string& msg, int code)
        : AppError(msg), status_code(code) {}
    int status_code;
};

void fetch_data(const std::string& url) {
    // E.2: Throw to signal failure
    throw NetworkError("connection refused", 503);
}

void run() {
    try {
        fetch_data("https://api.example.com");
    } catch (const NetworkError& e) {
        log_error(e.what(), e.status_code);
    } catch (const AppError& e) {
        log_error(e.what());
    }
    // E.17: Don't catch everything here -- let unexpected errors propagate
}
```

### Anti-Pattern

- Throw các type built-in như `int` hoặc string literal (E.14)
- Catch theo giá trị (nguy cơ slicing) (E.15)
- Các block catch rỗng âm thầm nuốt lỗi
- Dùng exception để điều khiển luồng (E.3)
- Xử lý lỗi dựa trên trạng thái global như `errno` (E.28)

## Hằng số & Tính bất biến (Con.*)

### Tất cả các rule

| Rule | Tóm tắt |
|------|---------|
| **Con.1** | Theo mặc định, làm cho đối tượng bất biến |
| **Con.2** | Theo mặc định, làm cho member function `const` |
| **Con.3** | Theo mặc định, truyền pointer và reference tới `const` |
| **Con.4** | Dùng `const` cho các giá trị không thay đổi sau khi construct |
| **Con.5** | Dùng `constexpr` cho các giá trị có thể tính lúc compile |

```cpp
// Con.1 through Con.5: Immutability by default
class Sensor {
public:
    explicit Sensor(std::string id) : id_(std::move(id)) {}

    // Con.2: const member functions by default
    const std::string& id() const { return id_; }
    double last_reading() const { return reading_; }

    // Only non-const when mutation is required
    void record(double value) { reading_ = value; }

private:
    const std::string id_;  // Con.4: never changes after construction
    double reading_{0.0};
};

// Con.3: Pass by const reference
void display(const Sensor& s) {
    std::cout << s.id() << ": " << s.last_reading() << '\n';
}

// Con.5: Compile-time constants
constexpr double PI = 3.14159265358979;
constexpr int MAX_SENSORS = 256;
```

## Đồng thời & Song song (CP.*)

### Các rule chính

| Rule | Tóm tắt |
|------|---------|
| **CP.2** | Tránh data race |
| **CP.3** | Giảm thiểu việc chia sẻ tường minh dữ liệu có thể ghi |
| **CP.4** | Hãy nghĩ theo task, thay vì theo thread |
| **CP.8** | Đừng dùng `volatile` để đồng bộ hóa |
| **CP.20** | Dùng RAII, đừng bao giờ dùng `lock()`/`unlock()` trần |
| **CP.21** | Dùng `std::scoped_lock` để lấy nhiều mutex |
| **CP.22** | KHÔNG BAO GIỜ gọi code không xác định trong khi đang giữ lock |
| **CP.42** | Đừng wait mà không có điều kiện |
| **CP.44** | Nhớ đặt tên cho các `lock_guard` và `unique_lock` của bạn |
| **CP.100** | Đừng dùng lập trình lock-free trừ khi thực sự bắt buộc |

### Khóa an toàn

```cpp
// CP.20 + CP.44: RAII locks, always named
class ThreadSafeQueue {
public:
    void push(int value) {
        std::lock_guard<std::mutex> lock(mutex_);  // CP.44: named!
        queue_.push(value);
        cv_.notify_one();
    }

    int pop() {
        std::unique_lock<std::mutex> lock(mutex_);
        // CP.42: Always wait with a condition
        cv_.wait(lock, [this] { return !queue_.empty(); });
        const int value = queue_.front();
        queue_.pop();
        return value;
    }

private:
    std::mutex mutex_;             // CP.50: mutex with its data
    std::condition_variable cv_;
    std::queue<int> queue_;
};
```

### Nhiều Mutex

```cpp
// CP.21: std::scoped_lock for multiple mutexes (deadlock-free)
void transfer(Account& from, Account& to, double amount) {
    std::scoped_lock lock(from.mutex_, to.mutex_);
    from.balance_ -= amount;
    to.balance_ += amount;
}
```

### Anti-Pattern

- `volatile` để đồng bộ hóa (CP.8 -- nó chỉ dành cho hardware I/O)
- Detach thread (CP.26 -- việc quản lý vòng đời gần như bất khả thi)
- Lock guard không đặt tên: `std::lock_guard<std::mutex>(m);` bị hủy ngay lập tức (CP.44)
- Giữ lock trong khi gọi callback (CP.22 -- nguy cơ deadlock)
- Lập trình lock-free khi không có chuyên môn sâu (CP.100)

## Template & Lập trình tổng quát (T.*)

### Các rule chính

| Rule | Tóm tắt |
|------|---------|
| **T.1** | Dùng template để nâng cao mức trừu tượng |
| **T.2** | Dùng template để biểu diễn thuật toán cho nhiều type đối số |
| **T.10** | Chỉ định concept cho mọi đối số template |
| **T.11** | Dùng concept chuẩn bất cứ khi nào có thể |
| **T.13** | Ưu tiên ký hiệu viết tắt cho các concept đơn giản |
| **T.43** | Ưu tiên `using` hơn `typedef` |
| **T.120** | Chỉ dùng template metaprogramming khi thực sự cần |
| **T.144** | Đừng specialize function template (hãy overload thay vào đó) |

### Concept (C++20)

```cpp
#include <concepts>

// T.10 + T.11: Constrain templates with standard concepts
template<std::integral T>
T gcd(T a, T b) {
    while (b != 0) {
        a = std::exchange(b, a % b);
    }
    return a;
}

// T.13: Shorthand concept syntax
void sort(std::ranges::random_access_range auto& range) {
    std::ranges::sort(range);
}

// Custom concept for domain-specific constraints
template<typename T>
concept Serializable = requires(const T& t) {
    { t.serialize() } -> std::convertible_to<std::string>;
};

template<Serializable T>
void save(const T& obj, const std::string& path);
```

### Anti-Pattern

- Template không ràng buộc trong các namespace hiển thị (T.47)
- Specialize function template thay vì overload (T.144)
- Template metaprogramming ở nơi `constexpr` là đủ (T.120)
- `typedef` thay vì `using` (T.43)

## Thư viện chuẩn (SL.*)

### Các rule chính

| Rule | Tóm tắt |
|------|---------|
| **SL.1** | Dùng thư viện bất cứ khi nào có thể |
| **SL.2** | Ưu tiên thư viện chuẩn hơn các thư viện khác |
| **SL.con.1** | Ưu tiên `std::array` hoặc `std::vector` hơn mảng C |
| **SL.con.2** | Ưu tiên `std::vector` theo mặc định |
| **SL.str.1** | Dùng `std::string` để sở hữu chuỗi ký tự |
| **SL.str.2** | Dùng `std::string_view` để tham chiếu tới chuỗi ký tự |
| **SL.io.50** | Tránh `endl` (dùng `'\n'` -- `endl` buộc phải flush) |

```cpp
// SL.con.1 + SL.con.2: Prefer vector/array over C arrays
const std::array<int, 4> fixed_data{1, 2, 3, 4};
std::vector<std::string> dynamic_data;

// SL.str.1 + SL.str.2: string owns, string_view observes
std::string build_greeting(std::string_view name) {
    return "Hello, " + std::string(name) + "!";
}

// SL.io.50: Use '\n' not endl
std::cout << "result: " << value << '\n';
```

## Enumeration (Enum.*)

### Các rule chính

| Rule | Tóm tắt |
|------|---------|
| **Enum.1** | Ưu tiên enumeration hơn macro |
| **Enum.3** | Ưu tiên `enum class` hơn `enum` thường |
| **Enum.5** | Đừng dùng ALL_CAPS cho enumerator |
| **Enum.6** | Tránh enumeration không tên |

```cpp
// Enum.3 + Enum.5: Scoped enum, no ALL_CAPS
enum class Color { red, green, blue };
enum class LogLevel { debug, info, warning, error };

// BAD: plain enum leaks names, ALL_CAPS clashes with macros
enum { RED, GREEN, BLUE };           // Enum.3 + Enum.5 + Enum.6 violation
#define MAX_SIZE 100                  // Enum.1 violation -- use constexpr
```

## File nguồn & Đặt tên (SF.*, NL.*)

### Các rule chính

| Rule | Tóm tắt |
|------|---------|
| **SF.1** | Dùng `.cpp` cho file code và `.h` cho file interface |
| **SF.7** | Đừng viết `using namespace` ở scope global trong header |
| **SF.8** | Dùng `#include` guard cho mọi file `.h` |
| **SF.11** | File header nên tự chứa (self-contained) |
| **NL.5** | Tránh mã hóa thông tin type vào tên (không dùng Hungarian notation) |
| **NL.8** | Dùng phong cách đặt tên nhất quán |
| **NL.9** | Chỉ dùng ALL_CAPS cho tên macro |
| **NL.10** | Ưu tiên tên theo `underscore_style` |

### Header Guard

```cpp
// SF.8: Include guard (or #pragma once)
#ifndef PROJECT_MODULE_WIDGET_H
#define PROJECT_MODULE_WIDGET_H

// SF.11: Self-contained -- include everything this header needs
#include <string>
#include <vector>

namespace project::module {

class Widget {
public:
    explicit Widget(std::string name);
    const std::string& name() const;

private:
    std::string name_;
};

}  // namespace project::module

#endif  // PROJECT_MODULE_WIDGET_H
```

### Quy ước đặt tên

```cpp
// NL.8 + NL.10: Consistent underscore_style
namespace my_project {

constexpr int max_buffer_size = 4096;  // NL.9: not ALL_CAPS (it's not a macro)

class tcp_connection {                 // underscore_style class
public:
    void send_message(std::string_view msg);
    bool is_connected() const;

private:
    std::string host_;                 // trailing underscore for members
    int port_;
};

}  // namespace my_project
```

### Anti-Pattern

- `using namespace std;` trong header ở scope global (SF.7)
- Header phụ thuộc vào thứ tự include (SF.10, SF.11)
- Hungarian notation như `strName`, `iCount` (NL.5)
- ALL_CAPS cho bất cứ thứ gì ngoài macro (NL.9)

## Hiệu năng (Per.*)

### Các rule chính

| Rule | Tóm tắt |
|------|---------|
| **Per.1** | Đừng tối ưu hóa mà không có lý do |
| **Per.2** | Đừng tối ưu hóa sớm |
| **Per.6** | Đừng đưa ra khẳng định về hiệu năng mà không có đo đạc |
| **Per.7** | Thiết kế để cho phép tối ưu hóa |
| **Per.10** | Dựa vào hệ thống type tĩnh |
| **Per.11** | Chuyển tính toán từ lúc chạy sang lúc compile |
| **Per.19** | Truy cập bộ nhớ một cách có thể dự đoán |

### Hướng dẫn

```cpp
// Per.11: Compile-time computation where possible
constexpr auto lookup_table = [] {
    std::array<int, 256> table{};
    for (int i = 0; i < 256; ++i) {
        table[i] = i * i;
    }
    return table;
}();

// Per.19: Prefer contiguous data for cache-friendliness
std::vector<Point> points;           // GOOD: contiguous
std::vector<std::unique_ptr<Point>> indirect_points; // BAD: pointer chasing
```

### Anti-Pattern

- Tối ưu hóa mà không có dữ liệu profiling (Per.1, Per.6)
- Chọn code mức thấp "thông minh" thay vì các abstraction rõ ràng (Per.4, Per.5)
- Bỏ qua bố cục dữ liệu và hành vi cache (Per.19)

## Checklist tham khảo nhanh

Trước khi đánh dấu công việc C++ hoàn thành:

- [ ] Không có `new`/`delete` trần -- dùng smart pointer hoặc RAII (R.11)
- [ ] Đối tượng được khởi tạo ngay khi khai báo (ES.20)
- [ ] Biến là `const`/`constexpr` theo mặc định (Con.1, ES.25)
- [ ] Member function là `const` khi có thể (Con.2)
- [ ] `enum class` thay vì `enum` thường (Enum.3)
- [ ] `nullptr` thay vì `0`/`NULL` (ES.47)
- [ ] Không có narrowing conversion (ES.46)
- [ ] Không có cast kiểu C (ES.48)
- [ ] Constructor một tham số là `explicit` (C.46)
- [ ] Đã áp dụng Rule of Zero hoặc Rule of Five (C.20, C.21)
- [ ] Destructor của base class là public virtual hoặc protected non-virtual (C.35)
- [ ] Template được ràng buộc bằng concept (T.10)
- [ ] Không có `using namespace` trong header ở scope global (SF.7)
- [ ] Header có include guard và tự chứa (SF.8, SF.11)
- [ ] Lock dùng RAII (`scoped_lock`/`lock_guard`) (CP.20)
- [ ] Exception là type tùy chỉnh, throw theo giá trị, catch theo reference (E.14, E.15)
- [ ] `'\n'` thay vì `std::endl` (SL.io.50)
- [ ] Không có magic number (ES.45)
