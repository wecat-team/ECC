---
name: windows-desktop-e2e
description: E2E testing cho ứng dụng desktop native của Windows (WPF, WinForms, Win32/MFC, Qt) dùng pywinauto và Windows UI Automation. Dùng khi viết E2E test cho ứng dụng desktop native của Windows bằng pywinauto hoặc UI Automation.
metadata:
  origin: ECC
---

# E2E Testing cho Windows Desktop

Kiểm thử end-to-end cho ứng dụng desktop native của Windows bằng **pywinauto** chạy trên Windows UI Automation (UIA). Bao gồm WPF, WinForms, Win32/MFC và Qt (5.x / 6.x) — với hướng dẫn riêng cho Qt trong một mục chuyên biệt.

## Khi nào kích hoạt

- Viết hoặc chạy E2E test cho ứng dụng desktop native của Windows
- Thiết lập bộ test GUI desktop từ đầu
- Chẩn đoán các test tự động hóa desktop chập chờn (flaky) hoặc thất bại
- Bổ sung khả năng kiểm thử (AutomationId, accessible name) cho ứng dụng hiện có
- Tích hợp E2E desktop vào pipeline CI/CD (GitHub Actions `windows-latest`)

### Khi nào KHÔNG dùng

- Ứng dụng web → dùng skill `e2e-testing` (Playwright)
- Ứng dụng Electron / CEF / WebView2 → lớp HTML cần tự động hóa trình duyệt, không phải UIA
- Ứng dụng mobile → dùng công cụ riêng của từng nền tảng (UIAutomator, XCUITest)
- Unit test hoặc integration test thuần không cần GUI đang chạy

## Khái niệm cốt lõi

Mọi tự động hóa desktop trên Windows đều dựa vào **UI Automation (UIA)**, một API accessibility có sẵn của Windows. Mỗi framework được hỗ trợ đều expose một cây các phần tử UIA với các thuộc tính mà Claude có thể đọc và thao tác:

```
Your test (Python)
    └── pywinauto (UIA backend)
        └── Windows UI Automation API   ← built into Windows, framework-agnostic
            └── App's UIA provider      ← each framework ships its own
                └── Running .exe
```

**Chất lượng UIA theo framework:**

| Framework | AutomationId | Độ tin cậy | Ghi chú |
|-----------|-------------|-------------|-------|
| WPF | 5/5 | Xuất sắc | `x:Name` ánh xạ trực tiếp sang AutomationId |
| WinForms | 4/5 | Tốt | `AccessibleName` = AutomationId |
| UWP / WinUI 3 | 5/5 | Xuất sắc | Được Microsoft hỗ trợ đầy đủ |
| Qt 6.x | 5/5 | Xuất sắc | Accessibility bật mặc định; tên class đổi thành `Qt6*` |
| Qt 5.15+ | 4/5 | Tốt | Module Accessibility đã được cải thiện |
| Qt 5.7–5.14 | 3/5 | Tạm được | Cần `QT_ACCESSIBILITY=1`; objectName đặt thủ công |
| Win32 / MFC | 3/5 | Tạm được | Control ID truy cập được; thường phải khớp theo text |

## Thiết lập và điều kiện tiên quyết

```bash
# Python 3.8+, Windows only
pip install pywinauto pytest pytest-html Pillow pytest-timeout
# Optional: screen recording
# Install ffmpeg and add to PATH: https://ffmpeg.org/download.html
```

Xác minh UIA truy cập được:

```python
from pywinauto import Desktop
Desktop(backend="uia").windows()  # lists all top-level windows
```

Cài **Accessibility Insights for Windows** (miễn phí, của Microsoft) — công cụ tương đương DevTools của bạn để kiểm tra cây phần tử UIA trước khi viết bất kỳ test nào.

## Thiết lập khả năng kiểm thử (theo Framework)

Việc có tác động lớn nhất bạn có thể làm là **gán cho mọi control tương tác một AutomationId ổn định** trước khi viết test.

### WPF

```xml
<!-- XAML: x:Name becomes AutomationId automatically -->
<TextBox x:Name="usernameInput" />
<PasswordBox x:Name="passwordInput" />
<Button x:Name="btnLogin" Content="Login" />
<TextBlock x:Name="lblError" />
```

### WinForms

```csharp
// Set in designer or code
usernameInput.AccessibleName = "usernameInput";
passwordInput.AccessibleName = "passwordInput";
btnLogin.AccessibleName = "btnLogin";
lblError.AccessibleName = "lblError";
```

### Win32 / MFC

```cpp
// Control resource IDs in .rc file are exposed as AutomationId strings
// IDC_EDIT_USERNAME -> AutomationId "1001"
// Prefer SetWindowText for Name; add IAccessible for richer support
```

### Qt — xem mục chuyên biệt bên dưới

---

## Page Object Model

```
tests/
├── conftest.py          # app launch fixture, failure screenshot
├── pytest.ini
├── config.py
├── pages/
│   ├── __init__.py      # required for imports
│   ├── base_page.py     # locators, wait, screenshot helpers
│   ├── login_page.py
│   └── main_page.py
├── tests/
│   ├── __init__.py
│   ├── test_login.py
│   └── test_main_flow.py
└── artifacts/           # screenshots, videos, logs
```

### base_page.py

```python
import os, time
from pywinauto import Desktop
from config import ACTION_TIMEOUT, ARTIFACT_DIR

class BasePage:
    def __init__(self, window):
        self.window = window

    # --- Locators (priority order) ---

    def by_id(self, auto_id, **kw):
        """AutomationId — most stable. Use as first choice."""
        return self.window.child_window(auto_id=auto_id, **kw)

    def by_name(self, name, **kw):
        """Visible text / accessible name."""
        return self.window.child_window(title=name, **kw)

    def by_class(self, cls, index=0, **kw):
        """Control class + index — fragile, avoid if possible."""
        return self.window.child_window(class_name=cls, found_index=index, **kw)

    # --- Waits ---

    def wait_visible(self, spec, timeout=ACTION_TIMEOUT):
        spec.wait("visible", timeout=timeout)
        return spec

    def wait_gone(self, spec, timeout=ACTION_TIMEOUT):
        spec.wait_not("visible", timeout=timeout)
        return spec

    def wait_window(self, title, timeout=ACTION_TIMEOUT):
        """Wait for a new top-level window (dialogs, child windows)."""
        dlg = Desktop(backend="uia").window(title=title)
        dlg.wait("visible", timeout=timeout)
        return dlg

    def wait_until(self, fn, timeout=ACTION_TIMEOUT, interval=0.3):
        """Poll an arbitrary condition — use when UIA events are unreliable."""
        deadline = time.time() + timeout
        while time.time() < deadline:
            try:
                if fn():
                    return True
            except Exception:
                pass
            time.sleep(interval)
        raise TimeoutError(f"Condition not met within {timeout}s")

    # --- Actions ---

    def click(self, spec):
        self.wait_visible(spec)
        spec.click_input()

    def type_text(self, spec, text):
        self.wait_visible(spec)
        ctrl = spec.wrapper_object()
        try:
            ctrl.set_edit_text(text)
        except Exception as e:
            # Qt 5.x fallback: UIA Value Pattern may be incomplete
            import sys, pywinauto.keyboard as kb
            print(f"[windows-desktop-e2e] set_edit_text failed ({e}), using keyboard fallback", file=sys.stderr)
            ctrl.click_input()
            kb.send_keys("^a")
            kb.send_keys(text, with_spaces=True)

    def get_text(self, spec):
        ctrl = spec.wrapper_object()
        for attr in ("window_text", "get_value"):
            try:
                v = getattr(ctrl, attr)()
                if v:
                    return v
            except Exception:
                pass
        return ""

    # --- Artifacts ---

    def screenshot(self, name):
        os.makedirs(ARTIFACT_DIR, exist_ok=True)
        path = os.path.join(ARTIFACT_DIR, f"{name}.png")
        self.window.capture_as_image().save(path)
        return path
```

### login_page.py

```python
from pages.base_page import BasePage

class LoginPage(BasePage):
    @property
    def username(self): return self.by_id("usernameInput")

    @property
    def password(self): return self.by_id("passwordInput")

    @property
    def btn_login(self): return self.by_id("btnLogin")

    @property
    def error_label(self): return self.by_id("lblError")

    def login(self, user, pwd):
        self.type_text(self.username, user)
        self.type_text(self.password, pwd)
        self.click(self.btn_login)

    def login_ok(self, user, pwd, main_title="Main Window"):
        self.login(user, pwd)
        return self.wait_window(main_title)

    def login_fail(self, user, pwd):
        self.login(user, pwd)
        self.wait_visible(self.error_label)
        return self.get_text(self.error_label)
```

### conftest.py

> Với dự án mới, ưu tiên dùng **Tier 1 sandbox fixture** (xem bên dưới) — nó bổ sung cô lập filesystem mà không tốn thêm chi phí. Fixture cơ bản này chỉ dành cho các thiết lập tối giản/legacy.

```python
import os, pytest
os.environ["QT_ACCESSIBILITY"] = "1"  # Required for Qt 5.x UIA support

from pywinauto import Application
from config import APP_PATH, MAIN_WINDOW_TITLE, LAUNCH_TIMEOUT, ARTIFACT_DIR

@pytest.fixture
def app(request):
    if not APP_PATH:
        pytest.exit("APP_PATH environment variable is not set", returncode=1)
    proc = Application(backend="uia").start(APP_PATH, timeout=LAUNCH_TIMEOUT)
    win  = proc.window(title=MAIN_WINDOW_TITLE)
    win.wait("visible", timeout=LAUNCH_TIMEOUT)
    yield win
    # Screenshot on failure
    if getattr(getattr(request.node, "rep_call", None), "failed", False):
        os.makedirs(ARTIFACT_DIR, exist_ok=True)
        try:
            win.capture_as_image().save(
                os.path.join(ARTIFACT_DIR, f"FAIL_{request.node.name}.png")
            )
        except Exception:
            pass
    # Graceful exit first, force-kill as fallback
    # proc is a pywinauto Application — use wait_for_process_exit(), not wait_for_process()
    try:
        win.close()
        proc.wait_for_process_exit(timeout=5)
    except Exception:
        proc.kill()

@pytest.hookimpl(tryfirst=True, hookwrapper=True)
def pytest_runtest_makereport(item, call):
    outcome = yield
    setattr(item, f"rep_{outcome.get_result().when}", outcome.get_result())
```

### config.py

```python
import os
APP_PATH          = os.environ.get("APP_PATH", "")           # set via env — no default path
MAIN_WINDOW_TITLE = os.environ.get("APP_TITLE", "")
LAUNCH_TIMEOUT    = int(os.environ.get("LAUNCH_TIMEOUT", "15"))
ACTION_TIMEOUT    = int(os.environ.get("ACTION_TIMEOUT", "10"))
ARTIFACT_DIR      = os.path.join(os.path.dirname(__file__), "artifacts")
```

### pytest.ini

```ini
[pytest]
testpaths = tests
markers =
    smoke: fast smoke tests for critical paths
    flaky: known-unstable tests
addopts = -v --tb=short --html=artifacts/report.html --self-contained-html
```

## Chiến lược Locator

```
AutomationId  >  Name (text)  >  ClassName + index  >  XPath
  (stable)         (readable)       (fragile)           (last resort)
```

Kiểm tra bằng Accessibility Insights → pane **Properties** → tìm `AutomationId` trước.

```python
# Inspect at runtime — paste into a REPL to explore the tree
win.print_control_identifiers()
# or narrow scope:
win.child_window(auto_id="groupBox1").print_control_identifiers()
```

## Pattern chờ (Wait)

```python
# Wait for control to appear
page.wait_visible(page.by_id("statusLabel"))

# Wait for control to disappear (e.g. loading spinner)
page.wait_gone(page.by_id("spinnerOverlay"))

# Wait for a dialog to pop up
dlg = page.wait_window("Confirm Delete")

# Custom condition (e.g. text changes)
page.wait_until(lambda: page.get_text(page.by_id("lblStatus")) == "Ready")
```

**KHÔNG BAO GIỜ dùng `time.sleep()` làm cơ chế đồng bộ chính** — hãy dùng `wait()` hoặc `wait_until()`.

## Quản lý Artifact

```python
# Screenshot on demand
page.screenshot("after_login")

# Full-screen capture (when window is off-screen or minimised)
import pyautogui
pyautogui.screenshot("artifacts/fullscreen.png")

# Screen recording with ffmpeg (start before test, stop after)
import subprocess

def start_recording(name):
    return subprocess.Popen([
        "ffmpeg", "-f", "gdigrab", "-framerate", "10",
        "-i", "desktop", "-y", f"artifacts/videos/{name}.mp4"
    ], stdin=subprocess.PIPE, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def stop_recording(proc):
    proc.stdin.write(b"q"); proc.stdin.flush(); proc.wait(timeout=10)
```

## Trace theo từng bước (opt-in)

Screenshot khi thất bại mặc định thường quá sơ sài để chẩn đoán test chập chờn. Trace ở mức từng bước dưới đây **mặc định tắt** — chỉ bật khi tái hiện một trường hợp flaky.

### Bật

```bash
E2E_TRACE=1 pytest tests/test_login.py -v
# Include typed text in the JSONL log (DO NOT use on tests that type credentials/PII):
E2E_TRACE=1 E2E_TRACE_INCLUDE_TEXT=1 pytest ...
```

### Patch vào BasePage

```python
import os, json, time
TRACE_ENABLED      = os.environ.get("E2E_TRACE") == "1"
TRACE_INCLUDE_TEXT = os.environ.get("E2E_TRACE_INCLUDE_TEXT") == "1"

class BasePage:
    _step = 0

    def _trace(self, action, spec=None, text=None):
        if not TRACE_ENABLED:
            return
        BasePage._step += 1
        idx = f"{BasePage._step:03d}"
        os.makedirs(ARTIFACT_DIR, exist_ok=True)
        try:
            self.window.capture_as_image().save(
                os.path.join(ARTIFACT_DIR, f"step_{idx}_{action}.png"))
        except Exception:
            pass  # capture failure must not break the test
        rec = {
            "ts": time.time(), "step": BasePage._step, "action": action,
            "locator": getattr(spec, "criteria", None),
            "text": text if TRACE_INCLUDE_TEXT else ("<redacted>" if text else None),
        }
        with open(os.path.join(ARTIFACT_DIR, "trace.jsonl"), "a") as f:
            f.write(json.dumps(rec) + "\n")

    def click(self, spec):
        self.wait_visible(spec); self._trace("click_before", spec)
        spec.click_input();      self._trace("click_after",  spec)

    def type_text(self, spec, text):
        self.wait_visible(spec); self._trace("type_before", spec, text)
        # ... existing set_edit_text / keyboard fallback ...
        self._trace("type_after", spec)
```

### Lưu ý

- **PII / credential**: nội dung `type_text` mặc định là `<redacted>`. KHÔNG BAO GIỜ đặt `E2E_TRACE_INCLUDE_TEXT=1` trên các luồng đăng nhập hoặc thanh toán.
- **Overhead**: ~50–200ms mỗi thao tác + một file PNG mỗi bước trên đĩa. Đừng bật trên CI matrix mặc định — chỉ bật trên job chuyên để tái hiện flake.
- **Artifact phình to**: một luồng dài tạo ra hàng chục MB; hãy điều chỉnh `retention-days` cho phù hợp.
- **Vệ sinh khi chạy song song/chạy lại**: ví dụ đơn giản này ghi nối tiếp (append) vào `trace.jsonl` và dùng bộ đếm cấp class. Hãy xóa thư mục artifact trước khi chạy lại, và dùng thư mục artifact riêng cho từng worker khi test song song.
- **Khoảng trống bao phủ**: các thao tác thực hiện ngoài `BasePage` (gọi `pywinauto` thô trong code test) không được trace.

## Xử lý test chập chờn (Flaky)

```python
# Quarantine — equivalent to Playwright's test.fixme()
@pytest.mark.skip(reason="Flaky: animation race on slow CI. Issue #42")
def test_animated_transition(self, app): ...

# Skip in CI only
@pytest.mark.skipif(os.environ.get("CI") == "true", reason="Flaky in CI #43")
def test_heavy_load(self, app): ...
```

Nguyên nhân thường gặp và cách khắc phục:

| Nguyên nhân | Cách khắc phục |
|-------|-----|
| Control chưa sẵn sàng | Thay `time.sleep` bằng `wait_visible` |
| Window không được focus | Thêm `win.set_focus()` trước khi tương tác |
| Animation đang chạy | `wait_until(lambda: not loading_indicator.exists())` |
| Thời điểm xuất hiện dialog | `wait_window(title, timeout=15)` |
| Display của CI chưa sẵn sàng | Đặt `DISPLAY` hoặc dùng virtual desktop trong CI |
| `set_edit_text` ném NotImplementedError | Thiếu UIA ValuePattern (thường gặp trên Qt 5.x) — `BasePage.type_text` đã tự fallback sang `keyboard.send_keys` |
| Control tồn tại nhưng `wait_visible` bị timeout | Window bị minimise hoặc nằm ngoài màn hình — gọi `win.restore()` + `win.set_focus()` trước khi chờ |

## Cô lập test và Sandbox

Ba tầng cô lập — dùng tầng nhẹ nhất đáp ứng nhu cầu của bạn.

### Tier 1 — Cô lập Filesystem (mặc định, luôn dùng)

Mỗi test có `APPDATA` / `LOCALAPPDATA` / `TEMP` riêng thông qua `subprocess.Popen` và `Application.connect()`. Fixture `tmp_path` của pytest tự động xử lý việc dọn dẹp.

```python
# conftest.py — replace the basic `app` fixture with this
import os, subprocess, pytest
from pywinauto import Application
from config import APP_PATH, APP_ARGS, APP_TITLE, LAUNCH_TIMEOUT, ACTION_TIMEOUT, ARTIFACT_DIR

@pytest.fixture(scope="function")
def app(request, tmp_path):
    """Fresh process + isolated user-data dirs per test."""
    if not APP_PATH:
        pytest.exit("APP_PATH not set", returncode=1)

    # Redirect all per-user storage to an isolated tmp directory
    sandbox_env = os.environ.copy()
    sandbox_env["QT_ACCESSIBILITY"]  = "1"
    sandbox_env["APPDATA"]           = str(tmp_path / "AppData" / "Roaming")
    sandbox_env["LOCALAPPDATA"]      = str(tmp_path / "AppData" / "Local")
    sandbox_env["TEMP"] = sandbox_env["TMP"] = str(tmp_path / "Temp")
    for p in (sandbox_env["APPDATA"], sandbox_env["LOCALAPPDATA"], sandbox_env["TEMP"]):
        os.makedirs(p, exist_ok=True)

    if not APP_TITLE:
        pytest.exit("APP_TITLE environment variable is not set", returncode=1)

    # shlex.split handles quoted args with spaces; plain split() breaks on them
    import shlex
    # Launch via subprocess so we can pass env; connect pywinauto by PID
    proc = subprocess.Popen(
        [APP_PATH] + shlex.split(APP_ARGS),
        env=sandbox_env,
    )
    pw_app = Application(backend="uia").connect(process=proc.pid, timeout=LAUNCH_TIMEOUT)
    win    = pw_app.window(title=APP_TITLE)
    win.wait("visible", timeout=LAUNCH_TIMEOUT)
    yield win

    if getattr(getattr(request.node, "rep_call", None), "failed", False):
        os.makedirs(ARTIFACT_DIR, exist_ok=True)
        try:
            win.capture_as_image().save(
                os.path.join(ARTIFACT_DIR, f"FAIL_{request.node.name}.png")
            )
        except Exception:
            pass
    try:
        win.close()
        proc.wait(timeout=5)
    except Exception:
        proc.kill()
    # tmp_path is cleaned up automatically by pytest

@pytest.hookimpl(tryfirst=True, hookwrapper=True)
def pytest_runtest_makereport(item, call):
    outcome = yield
    setattr(item, f"rep_{outcome.get_result().when}", outcome.get_result())
```

### Tier 2 — Windows Job Object (tùy chọn: kiểm soát vòng đời process)

Gắn process vào một Job Object để nó **tự động bị kết thúc** khi job handle của test fixture bị GC. Đồng thời ngăn ứng dụng sinh ra các child process thoát khỏi bước dọn dẹp của fixture.

> **Phạm vi cô lập:** Job Object KHÔNG ảo hóa quyền truy cập filesystem hay chặn lưu lượng mạng. Cô lập ghi file và mạng đòi hỏi AppContainer, quy tắc Windows Firewall, hoặc Tier 3 (Windows Sandbox). Chỉ dùng Tier 2 để kiểm soát vòng đời process và child process.

Không cần thêm dependency nào.

```python
import ctypes, ctypes.wintypes as wt

def restrict_process(pid: int):
    """
    Attach the process to a Job Object that prevents it from:
    - spawning processes outside the job (LIMIT_KILL_ON_JOB_CLOSE)
    Does NOT block network — use Windows Firewall rules for that.
    """
    JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE = 0x00002000
    # Minimal rights: SET_QUOTA (0x0100) | TERMINATE (0x0001)
    PROCESS_SET_QUOTA_AND_TERMINATE    = 0x0101

    kernel32 = ctypes.windll.kernel32
    job   = kernel32.CreateJobObjectW(None, None)
    hproc = kernel32.OpenProcess(PROCESS_SET_QUOTA_AND_TERMINATE, False, pid)

    # Correct struct layout — LimitFlags is at offset +16, not +44
    class JOBOBJECT_BASIC_LIMIT_INFORMATION(ctypes.Structure):
        _fields_ = [
            ("PerProcessUserTimeLimit", wt.LARGE_INTEGER),
            ("PerJobUserTimeLimit",     wt.LARGE_INTEGER),
            ("LimitFlags",             wt.DWORD),
            ("MinimumWorkingSetSize",   ctypes.c_size_t),
            ("MaximumWorkingSetSize",   ctypes.c_size_t),
            ("ActiveProcessLimit",      wt.DWORD),
            ("Affinity",               ctypes.c_size_t),
            ("PriorityClass",          wt.DWORD),
            ("SchedulingClass",        wt.DWORD),
        ]

    info = JOBOBJECT_BASIC_LIMIT_INFORMATION()
    info.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
    ok = kernel32.SetInformationJobObject(job, 2, ctypes.byref(info), ctypes.sizeof(info))
    if not ok:
        raise ctypes.WinError()
    kernel32.AssignProcessToJobObject(job, hproc)
    kernel32.CloseHandle(hproc)
    return job  # keep alive — job closes (kills proc) when GC'd

# After proc = subprocess.Popen(...):  job = restrict_process(proc.pid)
```

### Tier 3 — Windows Sandbox (cô lập toàn bộ OS cho CI)

Khi cần một image Windows sạch cho mỗi lần chạy (không còn registry key sót lại, không dùng chung trạng thái GPU, cô lập thực sự), hãy chạy **toàn bộ test suite** bên trong [Windows Sandbox](https://learn.microsoft.com/windows/security/application-security/application-isolation/windows-sandbox/windows-sandbox-overview).

**Yêu cầu:** Windows 10/11 Pro hoặc Enterprise, đã bật Virtualization.

Tạo `e2e-sandbox.wsb` ở thư mục gốc dự án:

```xml
<Configuration>
  <MappedFolders>
    <!-- App binary (read-only) -->
    <MappedFolder>
      <HostFolder>C:\path\to\your\build\Release</HostFolder>
      <SandboxFolder>C:\app</SandboxFolder>
      <ReadOnly>true</ReadOnly>
    </MappedFolder>
    <!-- Test suite (read-write for artifacts) -->
    <MappedFolder>
      <HostFolder>C:\path\to\your\e2e_test</HostFolder>
      <SandboxFolder>C:\e2e_test</SandboxFolder>
      <ReadOnly>false</ReadOnly>
    </MappedFolder>
  </MappedFolders>
  <LogonCommand>
    <!--
      Windows Sandbox starts with no Python. Install it silently first,
      then install deps and run tests. Artifacts are written back to the
      host via the MappedFolder above.
    -->
    <Command>powershell -Command "
      winget install --id Python.Python.3.11 --silent --accept-package-agreements;
      $env:PATH += ';' + $env:LOCALAPPDATA + '\Programs\Python\Python311\Scripts';
      cd C:\e2e_test;
      pip install -r requirements.txt;
      pytest tests\ -v
    "</Command>
  </LogonCommand>
</Configuration>
```

Khởi chạy: `WindowsSandbox.exe e2e-sandbox.wsb`

> pywinauto và ứng dụng đều chạy **bên trong** sandbox (bắt buộc cùng một session).
> Artifact được ghi ngược về host qua thư mục được map.

### So sánh các Tier

| Tier | Cô lập | Chi phí thiết lập | Chạy được trên CI | Dùng khi |
|------|-----------|-----------|-------------|----------|
| 1 — chuyển hướng env qua `tmp_path` | Filesystem | Không | Luôn luôn | Mặc định cho mọi test |
| 2 — Job Object | Cây process | Thấp | Luôn luôn | Ngăn child process thoát ra ngoài |
| 3 — Windows Sandbox | Toàn bộ OS | Trung bình | Cần image Pro/Enterprise | Chạy phòng sạch (clean-room) hằng đêm |

### Ngăn test bị treo

Thêm `pytest-timeout` để giới hạn thời gian của mỗi test. Trong `pytest.ini` đặt `timeout = 60` và `timeout_method = thread`. Lưu ý: phương thức `thread` không thể kill các subprocess của ứng dụng Qt trên Windows — hãy thêm `atexit.register(lambda: [p.kill() for p in psutil.Process().children(recursive=True)])` trong `conftest.py` để dọn các process mồ côi.

## Tích hợp CI/CD

```yaml
# .github/workflows/e2e-desktop.yml
name: Desktop E2E
on: [push, pull_request]

jobs:
  e2e:
    runs-on: windows-latest   # real GUI environment, no Xvfb needed
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
        with: { python-version: "3.11" }

      - name: Install deps
        run: pip install pywinauto pytest pytest-html Pillow

      - name: Build app
        run: cmake --build build --config Release  # adjust to your build system

      - name: Run E2E
        env:
          APP_PATH: ${{ github.workspace }}\build\Release\MyApp.exe
          APP_TITLE: "My Application"
          CI: "true"
        run: pytest tests/ --html=artifacts/report.html --self-contained-html --junitxml=artifacts/results.xml -v

      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: e2e-artifacts
          path: artifacts/
          retention-days: 14
```

## Đặc thù của Qt

### Bật UIA trong Qt 5.x

Accessibility của Qt 5.x bị tắt mặc định trong một số bản build (đặc biệt 5.7–5.14). Hãy đặt biến môi trường **trước** khi khởi chạy. Qt 6.x bật accessibility theo mặc định — bỏ qua bước này với Qt 6.

```python
# conftest.py — add at module top
import os
os.environ["QT_ACCESSIBILITY"] = "1"
```

Hoặc export trong CI:

```yaml
env:
  QT_ACCESSIBILITY: "1"
```

### Thêm định danh ổn định cho Qt Widget

```cpp
// Preferred: both objectName and accessibleName
void setTestId(QWidget* w, const char* id) {
    w->setObjectName(id);
    w->setAccessibleName(id);  // becomes UIA Name property
}

// In your dialog constructor:
setTestId(ui->usernameEdit, "usernameInput");
setTestId(ui->passwordEdit, "passwordInput");
setTestId(ui->loginButton,  "btnLogin");
setTestId(ui->errorLabel,   "lblError");
```

Tập trung mọi ID vào một header để tránh gõ sai:

```cpp
// test_ids.h
#define TID_USERNAME   "usernameInput"
#define TID_PASSWORD   "passwordInput"
#define TID_BTN_LOGIN  "btnLogin"
#define TID_LBL_ERROR  "lblError"
```

### Các điểm kỳ quặc riêng của Qt

**QComboBox** — dropdown là một window top-level riêng:

```python
from pywinauto import Desktop

def select_combo_item(page, combo_spec, item_text):
    page.click(combo_spec)
    # Dropdown appears as a new root-level window
    # class_name varies by Qt version — verify with Accessibility Insights
    # Qt 5.x: "Qt5QWindowIcon"  |  Qt 6.x: "Qt6QWindowIcon" — verify with Accessibility Insights
    popup = Desktop(backend="uia").window(class_name_re="Qt[56]QWindowIcon")
    popup.wait("visible", timeout=5)
    popup.child_window(title=item_text).click_input()
```

**QMessageBox / QDialog** — cũng là các window top-level riêng:

```python
dlg = page.wait_window("Confirm")          # wait for dialog title
dlg.child_window(title="OK").click_input() # click button inside it
```

**QTableWidget / QTableView** — truy cập hàng/ô:

```python
table = page.by_id("tblUsers").wrapper_object()
cell  = table.cell(row=0, column=1)
print(cell.window_text())
```

**Control tự vẽ** (chỉ có `paintEvent`, `QGraphicsView`, `QOpenGLWidget`) — UIA không thấy được bên trong chúng. Hãy dùng mục Fallback bên dưới.

## Fallback: Chế độ Screenshot

Khi một control không truy cập được qua UIA (tự vẽ, bên thứ ba, game engine):

```bash
pip install pyautogui Pillow opencv-python
```

```python
import pyautogui, cv2, numpy as np
from PIL import Image

def find_image_on_screen(template_path, confidence=0.85):
    """Locate a template image on screen. Returns (x, y) center or None."""
    screen   = np.array(pyautogui.screenshot())
    template = np.array(Image.open(template_path))
    result   = cv2.matchTemplate(
        cv2.cvtColor(screen, cv2.COLOR_RGB2BGR),
        cv2.cvtColor(template, cv2.COLOR_RGB2BGR),
        cv2.TM_CCOEFF_NORMED,
    )
    _, max_val, _, max_loc = cv2.minMaxLoc(result)
    if max_val >= confidence:
        h, w = template.shape[:2]
        return max_loc[0] + w // 2, max_loc[1] + h // 2
    return None

def click_image(template_path, confidence=0.85):
    pos = find_image_on_screen(template_path, confidence)
    if pos is None:
        raise RuntimeError(f"Image not found on screen: {template_path}")
    pyautogui.click(*pos)
```

### Quy tắc DPI / Scaling (chỉ áp dụng cho chế độ screenshot)

Việc khớp screenshot cực kỳ nhạy cảm với display scaling của Windows (100% / 125% / 150%). Ba quy tắc cứng:

1. **Chụp template ở cùng mức scale với máy đích.** Đừng cố cứu một sự lệch bằng `PIL.Image.resize` — `cv2.matchTemplate` rất mong manh trước các artefact do resample.
2. **Ghim (pin) display scaling của CI.** Trên `windows-latest` hãy thêm một bước như `Set-DisplayResolution 1920 1080 -Force` và tắt per-monitor DPI scaling, để kích thước screenshot tái lập được.
3. **Ghi lại mức scale cùng với mỗi artefact.** Khi chụp, ghi `GetDpiForWindow(hwnd) / 96` vào `artifacts/<test>/metadata.json` — việc phân tích sau sự cố trở nên rõ ràng thay vì đoán mò.

> DPI awareness ở cấp process (`SetProcessDpiAwarenessContext`) **có thể xung đột với cách xử lý DPI riêng của Qt** khi ứng dụng được test dựa trên Qt. Ưu tiên "template cùng scale + ghim CI" hơn là đổi chế độ DPI toàn process trong fixture.

### Debug độ tin cậy của việc khớp (Match Confidence)

Khi tinh chỉnh ngưỡng `confidence`, quy trình duy nhất hợp lý là **nhìn thấy** vị trí khớp rơi vào đâu. Helper bên dưới chỉ dùng để chẩn đoán — đừng gọi nó từ code test.

```python
def debug_match(template_path, out="artifacts/match_debug.png", confidence=0.85):
    """Diagnosis-only. Draw the best-match rectangle + score back on the current screen.

    NOT for production tests — use when calibrating confidence or chasing false matches.
    """
    import os, cv2, pyautogui, numpy as np
    screen = np.array(pyautogui.screenshot())[:, :, ::-1]
    tpl    = cv2.imread(template_path)
    if tpl is None:
        raise RuntimeError(f"Template unreadable: {template_path}")
    res    = cv2.matchTemplate(screen, tpl, cv2.TM_CCOEFF_NORMED)
    _, mv, _, ml = cv2.minMaxLoc(res)
    h, w   = tpl.shape[:2]
    colour = (0, 255, 0) if mv >= confidence else (0, 0, 255)  # green pass / red fail
    cv2.rectangle(screen, ml, (ml[0]+w, ml[1]+h), colour, 2)
    cv2.putText(screen, f"score={mv:.3f} thr={confidence}",
                (ml[0], max(20, ml[1]-6)),
                cv2.FONT_HERSHEY_SIMPLEX, 0.7, colour, 2)
    os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
    cv2.imwrite(out, screen)
    return mv
```

**Dùng có chừng mực** — việc khớp ảnh sẽ hỏng khi đổi DPI, đổi theme và khi bị che một phần.
Luôn thử UIA trước; chỉ fallback sang screenshot với các control thực sự không truy cập được.

## Anti-Pattern

```python
# BAD: fixed sleep
time.sleep(3)
page.click(page.by_id("btnSubmit"))

# GOOD: condition wait
page.wait_visible(page.by_id("btnSubmit"))
page.click(page.by_id("btnSubmit"))
```

```python
# BAD: brittle class+index locator as primary strategy
page.by_class("Edit", index=2).type_keys("hello")

# GOOD: AutomationId
page.by_id("usernameInput").set_edit_text("hello")
```

```python
# BAD: assert on pixel coordinates
assert btn.rectangle().left == 120

# GOOD: assert on content / state
assert page.get_text(page.by_id("lblStatus")) == "Logged in"
assert page.by_id("btnLogout").is_enabled()
```

```python
# BAD: share app instance across all tests (state leaks)
@pytest.fixture(scope="session")
def app(): ...

# GOOD: fresh process per test (or per class at most)
@pytest.fixture(scope="function")
def app(): ...
```

## Chạy test

```bash
# All tests
pytest tests/ -v

# Smoke only
pytest tests/ -m smoke -v

# Specific file
pytest tests/test_login.py -v

# With custom app path
APP_PATH="C:\build\Release\MyApp.exe" APP_TITLE="MyApp" pytest tests/ -v

# Detect flaky tests (repeat each 5 times)
pip install pytest-repeat
pytest tests/test_login.py --count=5 -v
```

## Skill liên quan

- `e2e-testing` — Playwright E2E cho ứng dụng web
- `cpp-testing` — Unit/integration test C++ với GoogleTest
- `cpp-coding-standards` — Phong cách và pattern code C++
