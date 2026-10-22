---
name: cpp-testing
description: Chỉ dùng khi viết/cập nhật/sửa test C++, cấu hình GoogleTest/CTest, chẩn đoán test lỗi hoặc flaky, hoặc thêm coverage/sanitizer.
metadata:
  origin: ECC
---

# C++ Testing (Agent Skill)

Workflow testing hướng agent cho C++ hiện đại (C++17/20) dùng GoogleTest/GoogleMock với CMake/CTest.

## Khi nào dùng

- Viết test C++ mới hoặc sửa test hiện có
- Thiết kế coverage unit/integration test cho các component C++
- Thêm test coverage, CI gating hoặc bảo vệ chống regression
- Cấu hình workflow CMake/CTest để thực thi nhất quán
- Điều tra test lỗi hoặc hành vi flaky
- Bật sanitizer để chẩn đoán bộ nhớ/race

### Khi nào KHÔNG dùng

- Triển khai tính năng sản phẩm mới mà không thay đổi test
- Refactor quy mô lớn không liên quan đến test coverage hoặc test lỗi
- Tinh chỉnh hiệu năng mà không có regression test để xác minh
- Dự án không phải C++ hoặc tác vụ không phải test

## Khái niệm cốt lõi

- **Vòng lặp TDD**: red → green → refactor (test trước, sửa tối thiểu, rồi dọn dẹp).
- **Cô lập (Isolation)**: ưu tiên dependency injection và fake hơn trạng thái global.
- **Bố cục test**: `tests/unit`, `tests/integration`, `tests/testdata`.
- **Mock vs fake**: mock cho tương tác, fake cho hành vi có state.
- **CTest discovery**: dùng `gtest_discover_tests()` để khám phá test ổn định.
- **Tín hiệu CI**: chạy một tập con trước, rồi toàn bộ suite với `--output-on-failure`.

## Workflow TDD

Theo vòng lặp RED → GREEN → REFACTOR:

1. **RED**: viết một test thất bại ghi lại hành vi mới
2. **GREEN**: triển khai thay đổi nhỏ nhất để pass
3. **REFACTOR**: dọn dẹp trong khi test vẫn xanh

```cpp
// tests/add_test.cpp
#include <gtest/gtest.h>

int Add(int a, int b); // Provided by production code.

TEST(AddTest, AddsTwoNumbers) { // RED
  EXPECT_EQ(Add(2, 3), 5);
}

// src/add.cpp
int Add(int a, int b) { // GREEN
  return a + b;
}

// REFACTOR: simplify/rename once tests pass
```

## Ví dụ code

### Unit Test cơ bản (gtest)

```cpp
// tests/calculator_test.cpp
#include <gtest/gtest.h>

int Add(int a, int b); // Provided by production code.

TEST(CalculatorTest, AddsTwoNumbers) {
    EXPECT_EQ(Add(2, 3), 5);
}
```

### Fixture (gtest)

```cpp
// tests/user_store_test.cpp
// Pseudocode stub: replace UserStore/User with project types.
#include <gtest/gtest.h>
#include <memory>
#include <optional>
#include <string>

struct User { std::string name; };
class UserStore {
public:
    explicit UserStore(std::string /*path*/) {}
    void Seed(std::initializer_list<User> /*users*/) {}
    std::optional<User> Find(const std::string &/*name*/) { return User{"alice"}; }
};

class UserStoreTest : public ::testing::Test {
protected:
    void SetUp() override {
        store = std::make_unique<UserStore>(":memory:");
        store->Seed({{"alice"}, {"bob"}});
    }

    std::unique_ptr<UserStore> store;
};

TEST_F(UserStoreTest, FindsExistingUser) {
    auto user = store->Find("alice");
    ASSERT_TRUE(user.has_value());
    EXPECT_EQ(user->name, "alice");
}
```

### Mock (gmock)

```cpp
// tests/notifier_test.cpp
#include <gmock/gmock.h>
#include <gtest/gtest.h>
#include <string>

class Notifier {
public:
    virtual ~Notifier() = default;
    virtual void Send(const std::string &message) = 0;
};

class MockNotifier : public Notifier {
public:
    MOCK_METHOD(void, Send, (const std::string &message), (override));
};

class Service {
public:
    explicit Service(Notifier &notifier) : notifier_(notifier) {}
    void Publish(const std::string &message) { notifier_.Send(message); }

private:
    Notifier &notifier_;
};

TEST(ServiceTest, SendsNotifications) {
    MockNotifier notifier;
    Service service(notifier);

    EXPECT_CALL(notifier, Send("hello")).Times(1);
    service.Publish("hello");
}
```

### CMake/CTest Quickstart

```cmake
# CMakeLists.txt (excerpt)
cmake_minimum_required(VERSION 3.20)
project(example LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(FetchContent)
# Prefer project-locked versions. If using a tag, use a pinned version per project policy.
set(GTEST_VERSION v1.17.0) # Adjust to project policy.
FetchContent_Declare(
  googletest
  # Google Test framework (official repository)
  URL https://github.com/google/googletest/archive/refs/tags/${GTEST_VERSION}.zip
)
FetchContent_MakeAvailable(googletest)

add_executable(example_tests
  tests/calculator_test.cpp
  src/calculator.cpp
)
target_link_libraries(example_tests GTest::gtest GTest::gmock GTest::gtest_main)

enable_testing()
include(GoogleTest)
gtest_discover_tests(example_tests)
```

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j
ctest --test-dir build --output-on-failure
```

## Chạy test

```bash
ctest --test-dir build --output-on-failure
ctest --test-dir build -R ClampTest
ctest --test-dir build -R "UserStoreTest.*" --output-on-failure
```

```bash
./build/example_tests --gtest_filter=ClampTest.*
./build/example_tests --gtest_filter=UserStoreTest.FindsExistingUser
```

## Debug test lỗi

1. Chạy lại riêng test đang lỗi bằng gtest filter.
2. Thêm logging có phạm vi quanh assertion bị lỗi.
3. Chạy lại với sanitizer được bật.
4. Mở rộng ra toàn bộ suite sau khi nguyên nhân gốc đã được sửa.

## Coverage

Ưu tiên cài đặt ở mức target thay vì flag toàn cục.

```cmake
option(ENABLE_COVERAGE "Enable coverage flags" OFF)

if(ENABLE_COVERAGE)
  if(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
    target_compile_options(example_tests PRIVATE --coverage)
    target_link_options(example_tests PRIVATE --coverage)
  elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    target_compile_options(example_tests PRIVATE -fprofile-instr-generate -fcoverage-mapping)
    target_link_options(example_tests PRIVATE -fprofile-instr-generate)
  endif()
endif()
```

GCC + gcov + lcov:

```bash
cmake -S . -B build-cov -DENABLE_COVERAGE=ON
cmake --build build-cov -j
ctest --test-dir build-cov
lcov --capture --directory build-cov --output-file coverage.info
lcov --remove coverage.info '/usr/*' --output-file coverage.info
genhtml coverage.info --output-directory coverage
```

Clang + llvm-cov:

```bash
cmake -S . -B build-llvm -DENABLE_COVERAGE=ON -DCMAKE_CXX_COMPILER=clang++
cmake --build build-llvm -j
LLVM_PROFILE_FILE="build-llvm/default.profraw" ctest --test-dir build-llvm
llvm-profdata merge -sparse build-llvm/default.profraw -o build-llvm/default.profdata
llvm-cov report build-llvm/example_tests -instr-profile=build-llvm/default.profdata
```

## Sanitizer

```cmake
option(ENABLE_ASAN "Enable AddressSanitizer" OFF)
option(ENABLE_UBSAN "Enable UndefinedBehaviorSanitizer" OFF)
option(ENABLE_TSAN "Enable ThreadSanitizer" OFF)

if(ENABLE_ASAN)
  add_compile_options(-fsanitize=address -fno-omit-frame-pointer)
  add_link_options(-fsanitize=address)
endif()
if(ENABLE_UBSAN)
  add_compile_options(-fsanitize=undefined -fno-omit-frame-pointer)
  add_link_options(-fsanitize=undefined)
endif()
if(ENABLE_TSAN)
  add_compile_options(-fsanitize=thread)
  add_link_options(-fsanitize=thread)
endif()
```

## Rào chắn cho Flaky Test

- KHÔNG BAO GIỜ dùng `sleep` để đồng bộ hóa; hãy dùng condition variable hoặc latch.
- Làm cho thư mục tạm là duy nhất cho mỗi test và luôn dọn chúng.
- Tránh phụ thuộc vào thời gian thực, mạng hoặc filesystem trong unit test.
- Dùng seed xác định cho các đầu vào ngẫu nhiên.

## Best Practice

### NÊN

- Giữ test có tính xác định và được cô lập
- Ưu tiên dependency injection hơn biến global
- Dùng `ASSERT_*` cho điều kiện tiên quyết, `EXPECT_*` cho nhiều kiểm tra
- Tách unit và integration test bằng CTest label hoặc thư mục
- Chạy sanitizer trong CI để phát hiện lỗi bộ nhớ và race

### KHÔNG NÊN

- Đừng phụ thuộc vào thời gian thực hoặc mạng trong unit test
- Đừng dùng sleep để đồng bộ hóa khi có thể dùng condition variable
- Đừng mock quá mức các value object đơn giản
- Đừng dùng so khớp chuỗi dễ vỡ cho các log không quan trọng

### Các cạm bẫy thường gặp

- **Dùng đường dẫn tạm cố định** → Tạo thư mục tạm duy nhất cho mỗi test và dọn chúng.
- **Dựa vào thời gian đồng hồ thật (wall clock)** → Inject một clock hoặc dùng nguồn thời gian giả.
- **Test đồng thời flaky** → Dùng condition variable/latch và chờ có giới hạn.
- **Trạng thái global ẩn** → Reset trạng thái global trong fixture hoặc loại bỏ global.
- **Mock quá mức** → Ưu tiên fake cho hành vi có state và chỉ mock các tương tác.
- **Thiếu các lần chạy sanitizer** → Thêm build ASan/UBSan/TSan trong CI.
- **Coverage trên build chỉ có debug** → Đảm bảo các target coverage dùng flag nhất quán.

## Phụ lục tùy chọn: Fuzzing / Property Testing

Chỉ dùng nếu dự án đã hỗ trợ LLVM/libFuzzer hoặc một thư viện property-testing.

- **libFuzzer**: tốt nhất cho các hàm thuần với I/O tối thiểu.
- **RapidCheck**: test dựa trên property để xác thực các invariant.

Harness libFuzzer tối thiểu (pseudocode: thay ParseConfig):

```cpp
#include <cstddef>
#include <cstdint>
#include <string>

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
    std::string input(reinterpret_cast<const char *>(data), size);
    // ParseConfig(input); // project function
    return 0;
}
```

## Các lựa chọn thay thế GoogleTest

- **Catch2**: header-only, matcher biểu đạt tốt
- **doctest**: nhẹ, chi phí compile tối thiểu
