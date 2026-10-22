---
name: generating-python-installer
description: "Chuyên gia installer Python cấp thương mại cho Windows: biên dịch cực hạn bằng Nuitka, làm gọn dist, phân tích footprint DLL và đóng gói Inno Setup để tạo ra installer nhỏ nhất, nhanh nhất. Dùng khi một ứng dụng Python phải được phát hành dưới dạng installer Windows tối thiểu, khởi động nhanh; không dùng cho việc chuyển script thành exe cơ bản. 中文触发：Nuitka 极限优化、Python 商业打包、极限编译 Python、dist 瘦身、DLL 分析、最小安装包、最快启动、商业级打包风格"
---

# Tạo Python Installer (Cấp thương mại)

Bạn là **chuyên gia triển khai thương mại Python**. Mục tiêu của bạn là installer Windows **nhỏ nhất, khởi động nhanh nhất, sạch nhất**. Cách tiếp cận cốt lõi là **"Nuitka folder mode (dist) + đóng gói Inno Setup"** — không build single-file, không có cửa sổ console thừa.

## Khi nào kích hoạt

Kích hoạt khi người dùng yêu cầu rõ ràng đóng gói Python **nâng cao** hoặc tối ưu dung lượng/tốc độ khởi động trên Windows:

- Biên dịch Nuitka cực hạn/cấp thương mại, build nhỏ nhất hoặc khởi động nhanh nhất
- Làm gọn thư mục `dist`, phân tích footprint DLL, đánh đổi dung lượng giữa 32-bit và 64-bit
- Đóng gói Inno Setup với metadata đầy đủ và gỡ cài đặt sạch, không để lại dấu vết

Skill này nhắm đến tối ưu nâng cao về dung lượng/khởi động — không phải chuyển đổi "script thành exe" một file cơ bản.

## Cách hoạt động

1. **Xác nhận tham số build** — tên ứng dụng, phiên bản, publisher, tên exe, thư mục nguồn/đầu ra, icon. KHÔNG BAO GIỜ tự động điền; hãy hỏi người dùng.
2. **Xác minh bản build nguồn** — đã tắt console, bật LTO, có VC++ runtime.
3. **Biên dịch bằng Nuitka** theo chiến lược loại trừ module và plugin bên dưới.
4. **Làm gọn thư mục `dist`** — loại bỏ debug symbol, cache, test và tài liệu, có biện pháp bảo vệ metadata cần thiết lúc runtime.
5. **Phân tích DLL** để tìm và cắt giảm các dependency lớn nhất.
6. **Đóng gói bằng Inno Setup** — nén LZMA2 ultra, metadata đầy đủ, gỡ cài đặt không để lại dấu vết, và VC++ redistributable khớp kiến trúc.

## Ví dụ

- "用 Nuitka 把这个 PySide2 项目打成最小体积的商业安装包" → chạy toàn bộ workflow: khuyến nghị 32-bit, loại trừ WebEngine/3D/Charts, làm gọn `dist`, đóng gói bằng Inno Setup.
- "我的 exe 有 400 MB，怎么瘦身到一半" → phân tích DLL, chuyển sang `opencv-python-headless`, bỏ `opengl32sw`, áp dụng làm gọn `dist`.
- "安装后在纯净系统打不开" → đảm bảo VC++ redistributable đúng kiến trúc được đóng gói trong script Inno Setup.

---

## Triết lý cốt lõi

Kiên định với giải pháp **"Nuitka folder mode (dist) + đóng gói Inno Setup"**. Từ chối bản single-file, từ chối cửa sổ console đen.

---

## Case study thực chiến (ứng dụng desktop PySide2 cấp production, 323 MB, gồm OpenCV / Playwright)

### Tổng quan project
- **Tổng dung lượng**: 323 MB
- **Công cụ đóng gói**: PyInstaller 4.7 (32-bit)
- **Dependency chính**: PySide2 (22.52 MB), OpenCV (62.38 MB), Playwright (76.74 MB)
- **Phiên bản Python**: Python 3.8 (32-bit)
- **Số lượng DLL**: 71 file, tổng cộng 93.23 MB

### Chiến lược tối ưu then chốt
1. PASS: **Dùng Python 32-bit** → giảm 20-30% dung lượng
2. PASS: **Nén thư viện chuẩn bằng base_library.zip** → 0.74 MB
3. PASS: **Loại trừ module gọn gàng** → không có pytest/unittest/setuptools
4. PASS: **Làm gọn plugin Qt** → chỉ giữ plugin cần thiết

### Phân bố dung lượng

| Thành phần | Dung lượng | Tỷ lệ | Gợi ý tối ưu |
|------|------|------|---------|
| playwright | 76.74 MB | 23.8% | Có thể bỏ nếu không cần thiết |
| OpenCV | 62.38 MB | 19.3% | Dùng opencv-python-headless |
| PySide2 | 22.52 MB | 7.0% | Loại trừ WebEngine/3D/Charts |
| Các dependency khác | 161.36 MB | 49.9% | - |

### So sánh hiệu quả kỳ vọng

| Loại project | Nuitka gốc | Sau tối ưu | Đo thực tế trên project tham chiếu |
|---------|------------|--------|----------------|
| Tkinter + thư viện chuẩn | 150-250 MB | **80-120 MB** | - |
| PyQt/PySide | 200-400 MB | **120-250 MB** | 323 MB (gồm OpenCV, v.v.) |
| Có numpy/pandas | 300-600 MB | **180-350 MB** | - |

---

## Workflow cốt lõi - WARNING: Thực hiện nghiêm ngặt

Khi người dùng yêu cầu đóng gói, thực hiện theo các bước sau:

**Bước 1: Bắt buộc xác nhận tham số (FAIL: Cấm dùng giá trị mặc định)**

> **WARNING: Quy tắc QUAN TRỌNG: PHẢI xác nhận lần lượt với người dùng tất cả các tham số dưới đây, CẤM tự động điền hoặc dùng giá trị mặc định!**

PHẢI hỏi và xác nhận với người dùng các thông tin sau (*chờ người dùng trả lời rõ ràng rồi mới được tiếp tục*):

| Tham số | Mô tả | Ví dụ |
|------|------|------|
| **Tên phần mềm** (App Name) | Tên hiển thị của phần mềm | `红墨批注` |
| **Số phiên bản** (Version) | Số phiên bản theo semantic versioning | `1.0.0` |
| **Publisher/Tên công ty** (Publisher) | Publisher hiển thị trong Control Panel | `YourCompany` |
| **Chương trình chính** (Exe Name) | Tên file thực thi chính | `RedInk.exe` |
| **Đường dẫn nguồn** (Source Dir) | Đường dẫn tuyệt đối của thư mục Nuitka dist | `D:\project\dist` |
| **Đường dẫn đầu ra** (Output Dir) | Nơi tạo ra installer | `D:\project\output` |
| **Đường dẫn icon** (Icon Path) | Đường dẫn tuyệt đối của file .ico (tùy chọn nhưng nên có) | `D:\project\icon.ico` |
| **Địa chỉ website** (URL) | Tùy chọn, dùng cho liên kết trong Control Panel | `https://example.com` |

**Mẫu câu hỏi:**
> "Vui lòng cung cấp các tham số đóng gói sau, tôi cần bạn xác nhận lần lượt:
> 1. Tên phần mềm:
> 2. Số phiên bản:
> 3. Publisher/Tên công ty:
> 4. Tên file chương trình chính (ví dụ xxx.exe):
> 5. Đường dẫn nguồn (thư mục Nuitka dist):
> 6. Đường dẫn đầu ra (nơi lưu installer):
> 7. Đường dẫn icon (file .ico, có thể để trống):
> 8. Địa chỉ website (có thể để trống):
>
> Vui lòng điền lần lượt, hoặc trả lời "bỏ qua" để dùng giá trị rỗng."

**Bước 2: Kiểm tra chất lượng file nguồn và biên dịch (then chốt)**
Trước khi sinh code, PHẢI đưa ra **xác nhận then chốt** sau cho người dùng (vì Inno Setup chỉ là công cụ đóng gói, không thể thay đổi thuộc tính chạy của chính chương trình):

> "WARNING: **Kiểm tra tham số biên dịch**:
> 1. **Bỏ cửa sổ đen**: Vui lòng xác nhận thư mục dist của bạn được biên dịch bằng `nuitka --windows-console-mode=disable`. (Nếu không, sau khi cài đặt vẫn sẽ có khung đen)
> 2. **Hiệu năng cao**: Vui lòng xác nhận đã dùng `--lto=yes` hay chưa. (Nếu không, tốc độ khởi động có thể không như mong muốn)
> 3. **Runtime library**: Vui lòng đảm bảo thư mục dist đã bao gồm các VC++ runtime cần thiết, để tránh không chạy được trên hệ thống sạch.
>
> **Nếu file nguồn đã sẵn sàng, hãy trả lời "xác nhận", nếu không hãy biên dịch lại trước.**"

**Bước 3: Sinh code**
Sau khi người dùng xác nhận, xuất ra code bao gồm **metadata đầy đủ** và **sửa lỗi icon gỡ cài đặt**.

---

## Biên dịch tối ưu cực hạn với Nuitka (dựa trên kinh nghiệm từ project tham chiếu)

### 1. Chiến lược chọn 32-bit hay 64-bit

**Lý do project tham chiếu dùng Python 32-bit**:

| Thành phần | Dung lượng 64-bit | Dung lượng 32-bit | Tiết kiệm |
|------|---------|---------|------|
| python3x.dll | ~4.5 MB | ~3.8 MB | 15% |
| Qt5Core.dll | ~8 MB | ~5 MB | 37% |
| numpy | ~30 MB | ~20 MB | 33% |
| **Tổng thể** | Chuẩn | **-20~30%** | - |

**Điều kiện nên dùng 32-bit**:
- PASS: Chương trình dùng bộ nhớ < 2GB
- PASS: Không xử lý file siêu lớn (< 2GB)
- PASS: Người dùng mục tiêu dùng máy tính văn phòng thông thường

**Cách biên dịch 32-bit**:
```bash
# 1. Cài Python 32-bit (có thể cùng tồn tại với 64-bit)
# Địa chỉ tải: https://www.python.org/downloads/windows/

# 2. Cài dependency bằng Python 32-bit
py -3.12-32 -m pip install -r requirements.txt

# 3. Biên dịch bằng Python 32-bit
py -3.12-32 -m nuitka --standalone ...你的参数
```

### 2. Danh sách loại trừ module (đã được project tham chiếu kiểm chứng)

**Danh sách loại trừ an toàn** (không cần lúc runtime):
```
unittest,test,pytest,_pytest,doctest,pdb,pdbpp,
setuptools,pip,distutils,pkg_resources,
email.mime,http.server,xmlrpc,pydoc
```

**Hiệu quả kỳ vọng**: tiết kiệm **30-50 MB**

### 3. Tối ưu riêng cho từng GUI framework

#### Tối ưu cực hạn cho Tkinter (khuyến nghị, nhẹ nhất)
```bash
nuitka --standalone --windows-console-mode=disable ^
    --lto=yes ^
    --jobs=8 ^
    --enable-plugin=tk-inter ^
    --enable-plugin=anti-bloat ^
    --noinclude-pytest-mode=nofollow ^
    --noinclude-setuptools-mode=nofollow ^
    --nofollow-import-to=unittest,test,pytest,_pytest,doctest,pdb,pdbpp ^
    --nofollow-import-to=setuptools,pip,distutils,pkg_resources ^
    --nofollow-import-to=email.mime,http.server,xmlrpc,pydoc ^
    --python-flag=no_docstrings ^
    --output-dir=dist ^
    --windows-icon-from-ico=icon.ico ^
    --remove-output ^
    main.py
```

**Dung lượng kỳ vọng**: 80-120 MB (sau tối ưu)

#### Tối ưu PyQt5 / PySide2
```bash
nuitka --standalone --windows-console-mode=disable ^
    --lto=yes ^
    --jobs=8 ^
    --enable-plugin=pyqt5 ^
    --enable-plugin=anti-bloat ^
    --noinclude-pytest-mode=nofollow ^
    --noinclude-setuptools-mode=nofollow ^
    --nofollow-import-to=unittest,test,pytest,_pytest,doctest,pdb ^
    --nofollow-import-to=setuptools,pip,distutils,pkg_resources ^
    --nofollow-import-to=PyQt5.QtWebEngine,PyQt5.QtWebEngineWidgets ^
    --nofollow-import-to=PyQt5.Qt3D,PyQt5.QtCharts ^
    --python-flag=no_docstrings ^
    --include-qt-plugins=sensible,styles,platforms ^
    --output-dir=dist ^
    --windows-icon-from-ico=icon.ico ^
    --remove-output ^
    main.py
```

**Dung lượng kỳ vọng**: 120-250 MB (sau tối ưu)

### 4. Mẫu script biên dịch một lệnh

**Lưu thành `build_optimized.bat` (thư mục gốc project)**:

```batch
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo Nuitka 极限优化编译（参考 参考项目）
echo ========================================

REM === 配置区域（请修改为你的实际值） ===
set APP_NAME=你的软件名
set MAIN_FILE=main.py
set ICON_FILE=icon.ico

REM === 自动检测 CPU 核心数 ===
REM 用 Windows 自带环境变量（wmic 在 Win11 22H2+ 已移除，探不到会让 --jobs=0 单线程编译）
set CPU_CORES=%NUMBER_OF_PROCESSORS%
if not defined CPU_CORES set CPU_CORES=4
set /a BUILD_JOBS=%CPU_CORES%

REM === 参考项目的模块排除清单 ===
set EXCLUDE_MODULES=unittest,test,pytest,_pytest,doctest,pdb,pdbpp
set EXCLUDE_MODULES=%EXCLUDE_MODULES%,setuptools,pip,distutils,pkg_resources
set EXCLUDE_MODULES=%EXCLUDE_MODULES%,email.mime,http.server,xmlrpc,pydoc

echo.
echo [1/4] 清理旧编译...
if exist dist rd /s /q dist
if exist build rd /s /q build

echo.
echo [2/4] Nuitka 编译中（应用 参考项目优化策略）...
echo - CPU 核心: %CPU_CORES% (使用 %BUILD_JOBS% 线程)
echo - 模块排除: %EXCLUDE_MODULES%
echo.

nuitka --standalone ^
    --windows-console-mode=disable ^
    --lto=yes ^
    --jobs=%BUILD_JOBS% ^
    --enable-plugin=anti-bloat ^
    --enable-plugin=tk-inter ^
    --noinclude-pytest-mode=nofollow ^
    --noinclude-setuptools-mode=nofollow ^
    --nofollow-import-to=%EXCLUDE_MODULES% ^
    --python-flag=no_docstrings ^
    --output-dir=dist ^
    --windows-icon-from-ico=%ICON_FILE% ^
    --remove-output ^
    %MAIN_FILE%

if %errorlevel% neq 0 (
    echo.
    echo [错误] 编译失败！
    pause
    exit /b 1
)

echo.
echo [3/4] 统计编译结果...
for /f %%a in ('powershell -NoProfile -Command "(Get-ChildItem -LiteralPath 'dist\%APP_NAME%.dist' -Recurse -File | Measure-Object -Property Length -Sum).Sum"') do set TOTAL_SIZE=%%a
set TOTAL_SIZE=%TOTAL_SIZE:,=%
set /a SIZE_MB=%TOTAL_SIZE% / 1048576
echo - 编译后体积: %SIZE_MB% MB

echo.
echo [4/4] 执行瘦身清理（参考 参考项目策略）...
powershell -ExecutionPolicy Bypass -File slim_dist.ps1 -DistPath "dist\%APP_NAME%.dist"

echo.
echo ========================================
echo 编译完成！
echo ========================================
pause
```

### 5. Script làm gọn dist (dọn dẹp ở mức project tham chiếu)

**Lưu thành `slim_dist.ps1` (cùng thư mục với build_optimized.bat)**:

```powershell
param(
    [string]$DistPath
)

$ErrorActionPreference = "Continue"  # 不静默吞错：删除失败会显示出来，避免假成功

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "dist 瘦身清理（参考 参考项目策略）" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if (-not (Test-Path $DistPath)) {
    Write-Host "[错误] 找不到目录: $DistPath" -ForegroundColor Red
    exit 1
}

# Thống kê dung lượng ban đầu
$InitialSize = (Get-ChildItem -Path $DistPath -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1MB
Write-Host "`n初始体积: $([math]::Round($InitialSize, 2)) MB" -ForegroundColor Yellow

# Đặc điểm của project tham chiếu: không có .pdb, .pyi, __pycache__, test, v.v.
Write-Host "`n[应用 参考项目的清理策略...]" -ForegroundColor Green

# 1. Xóa debug symbol
Write-Host "`n[1/7] 删除 .pdb 调试符号..." -ForegroundColor Green
$pdbFiles = Get-ChildItem -Path $DistPath -Recurse -Include *.pdb -File
$pdbSize = ($pdbFiles | Measure-Object -Property Length -Sum).Sum / 1MB
if ($pdbFiles.Count -gt 0) {
    $pdbFiles | Remove-Item -Force
    Write-Host "  删除 $($pdbFiles.Count) 个文件，节省 $([math]::Round($pdbSize, 2)) MB"
} else {
    Write-Host "  未发现 .pdb 文件（已优化）" -ForegroundColor Gray
}

# 2. Xóa type hint
Write-Host "`n[2/7] 删除 .pyi 类型提示..." -ForegroundColor Green
$pyiFiles = Get-ChildItem -Path $DistPath -Recurse -Include *.pyi -File
$pyiSize = ($pyiFiles | Measure-Object -Property Length -Sum).Sum / 1MB
if ($pyiFiles.Count -gt 0) {
    $pyiFiles | Remove-Item -Force
    Write-Host "  删除 $($pyiFiles.Count) 个文件，节省 $([math]::Round($pyiSize, 2)) MB"
} else {
    Write-Host "  未发现 .pyi 文件（已优化）" -ForegroundColor Gray
}

# 3. Xóa __pycache__
Write-Host "`n[3/7] 删除 __pycache__ 缓存..." -ForegroundColor Green
$pycacheDirs = Get-ChildItem -Path $DistPath -Recurse -Directory -Filter "__pycache__"
$pycacheSize = 0
foreach ($dir in $pycacheDirs) {
    $size = (Get-ChildItem -Path $dir.FullName -Recurse -File | Measure-Object -Property Length -Sum).Sum
    $pycacheSize += $size
    Remove-Item -Path $dir.FullName -Recurse -Force
}
if ($pycacheDirs.Count -gt 0) {
    Write-Host "  删除 $($pycacheDirs.Count) 个目录，节省 $([math]::Round($pycacheSize / 1MB, 2)) MB"
} else {
    Write-Host "  未发现 __pycache__（已优化）" -ForegroundColor Gray
}

# 4. Xóa thư mục test
Write-Host "`n[4/7] 删除 test/tests 测试目录..." -ForegroundColor Green
$testDirs = Get-ChildItem -Path $DistPath -Recurse -Directory | Where-Object { $_.Name -match '^tests?$' }
$testSize = 0
foreach ($dir in $testDirs) {
    $size = (Get-ChildItem -Path $dir.FullName -Recurse -File | Measure-Object -Property Length -Sum).Sum
    $testSize += $size
    Remove-Item -Path $dir.FullName -Recurse -Force
}
if ($testDirs.Count -gt 0) {
    Write-Host "  删除 $($testDirs.Count) 个目录，节省 $([math]::Round($testSize / 1MB, 2)) MB"
} else {
    Write-Host "  未发现测试目录（已优化）" -ForegroundColor Gray
}

# 5. Xóa tài liệu và ví dụ
Write-Host "`n[5/7] 删除 docs/examples 文档目录..." -ForegroundColor Green
$docDirs = Get-ChildItem -Path $DistPath -Recurse -Directory | Where-Object { $_.Name -match '^(docs|examples|samples|demo)$' }
$docSize = 0
foreach ($dir in $docDirs) {
    $size = (Get-ChildItem -Path $dir.FullName -Recurse -File | Measure-Object -Property Length -Sum).Sum
    $docSize += $size
    Remove-Item -Path $dir.FullName -Recurse -Force
}
if ($docDirs.Count -gt 0) {
    Write-Host "  删除 $($docDirs.Count) 个目录，节省 $([math]::Round($docSize / 1MB, 2)) MB"
} else {
    Write-Host "  未发现文档目录（已优化）" -ForegroundColor Gray
}

# 6. Xóa file .pyc
Write-Host "`n[6/7] 删除 .pyc 字节码..." -ForegroundColor Green
$pycFiles = Get-ChildItem -Path $DistPath -Recurse -Include *.pyc -File
$pycSize = ($pycFiles | Measure-Object -Property Length -Sum).Sum / 1MB
if ($pycFiles.Count -gt 0) {
    $pycFiles | Remove-Item -Force
    Write-Host "  删除 $($pycFiles.Count) 个文件，节省 $([math]::Round($pycSize, 2)) MB"
} else {
    Write-Host "  未发现 .pyc 文件（已优化）" -ForegroundColor Gray
}

# 7. Làm gọn metadata .dist-info
Write-Host "`n[7/7] 精简 .dist-info 元数据..." -ForegroundColor Green
$distInfoDirs = Get-ChildItem -Path $DistPath -Recurse -Directory -Filter "*.dist-info"
$removedCount = 0
$removedSize = 0
foreach ($infoDir in $distInfoDirs) {
    # Chỉ xóa các file ghi sổ lúc cài đặt; giữ METADATA và entry_points.txt (được importlib.metadata đọc lúc runtime, xóa sẽ làm hỏng việc phát hiện plugin)
    $filesToRemove = @("RECORD", "INSTALLER", "direct_url.json")
    foreach ($fileName in $filesToRemove) {
        $file = Join-Path $infoDir.FullName $fileName
        if (Test-Path $file) {
            $size = (Get-Item $file).Length
            $removedSize += $size
            Remove-Item $file -Force
            $removedCount++
        }
    }
}
if ($removedCount -gt 0) {
    Write-Host "  删除 $removedCount 个元数据文件，节省 $([math]::Round($removedSize / 1MB, 2)) MB"
} else {
    Write-Host "  未发现可清理的元数据（已优化）" -ForegroundColor Gray
}

# Thống kê dung lượng cuối cùng
$FinalSize = (Get-ChildItem -Path $DistPath -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1MB
$SavedSize = $InitialSize - $FinalSize
$SavedPercent = if ($InitialSize -gt 0) { ($SavedSize / $InitialSize) * 100 } else { 0 }

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "清理完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "初始体积: $([math]::Round($InitialSize, 2)) MB" -ForegroundColor Yellow
Write-Host "最终体积: $([math]::Round($FinalSize, 2)) MB" -ForegroundColor Green
Write-Host "节省空间: $([math]::Round($SavedSize, 2)) MB ($([math]::Round($SavedPercent, 1))%)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# So sánh với project tham chiếu
Write-Host "[对比参考]" -ForegroundColor Yellow
Write-Host "参考项目总体积: 323 MB (包含 PyQt, OpenCV, Playwright 等重量级库)" -ForegroundColor Gray
Write-Host "如果你的项目是纯 Tkinter + 标准库，目标应该在 80-150 MB" -ForegroundColor Gray
```

**Hiệu quả kỳ vọng**: tiết kiệm **15-30%** dung lượng

### 6. Công cụ phân tích dependency DLL

**Lưu thành `analyze_dlls.py` (dùng để tìm các file chiếm dung lượng lớn)**:

```python
"""
DLL 依赖分析工具
参考 参考项目的 DLL 管理策略，帮助识别体积大户和优化建议
"""
import sys
from pathlib import Path

def analyze_dlls(dist_path: str):
    """分析 dist 目录中的 DLL 依赖"""
    dist_dir = Path(dist_path)

    if not dist_dir.exists():
        print(f"[错误] 目录不存在: {dist_path}")
        return

    print("=" * 70)
    print("DLL 依赖分析（参考 参考项目策略）")
    print("=" * 70)

    # Thu thập tất cả DLL
    dll_files = list(dist_dir.rglob("*.dll"))

    if not dll_files:
        print("\n未发现 DLL 文件")
        return

    # Sắp xếp theo kích thước
    dll_data = [(dll, dll.stat().st_size) for dll in dll_files]
    dll_data.sort(key=lambda x: x[1], reverse=True)

    total_size = sum(size for _, size in dll_data)

    print(f"\n总 DLL 数量: {len(dll_files)}")
    print(f"总 DLL 体积: {total_size / 1024 / 1024:.2f} MB\n")

    # So sánh với project tham chiếu
    print("[对比参考] 参考项目的 DLL 情况:")
    print("  - 总数量: 71 个")
    print("  - 总体积: 93.23 MB")
    print("  - 最大的: libopenblas (26.85 MB), opengl32sw (15.25 MB)\n")

    # Phân tích các DLL lớn hơn 3MB
    large_dlls = [(dll, size) for dll, size in dll_data if size > 3 * 1024 * 1024]

    if large_dlls:
        print("=" * 70)
        print("WARNING:  大于 3MB 的 DLL（需重点关注）")
        print("=" * 70)

        for dll, size in large_dlls:
            size_mb = size / 1024 / 1024
            relative_path = dll.relative_to(dist_dir)
            name_lower = dll.name.lower()

            print(f"\n{size_mb:8.2f} MB  {dll.name}")
            print(f"           位置: {relative_path.parent}")

            # Gợi ý tối ưu
            suggestions = get_optimization_suggestion(name_lower)
            if suggestions:
                for suggestion in suggestions:
                    print(f"            {suggestion}")

    # Kiểm tra DLL dư thừa
    print("\n" + "=" * 70)
    print(" 冗余检查")
    print("=" * 70)

    # Kiểm tra bản debug
    debug_dlls = [dll for dll, _ in dll_data if dll.stem.endswith('d')]
    if debug_dlls:
        print(f"\nWARNING:  发现 {len(debug_dlls)} 个调试版本 DLL（可以删除）:")
        for dll in debug_dlls:
            print(f"  - {dll.name}")
    else:
        print("\nPASS: 未发现调试版本 DLL（已优化）")

    # VC++ Runtime
    vc_runtimes = [dll for dll, _ in dll_data if 'vcruntime' in dll.name.lower() or 'msvcp' in dll.name.lower()]
    if vc_runtimes:
        print(f"\n[VC++ Runtime 库] 发现 {len(vc_runtimes)} 个:")
        for dll in vc_runtimes:
            size_mb = dll.stat().st_size / 1024 / 1024
            print(f"  - {dll.name} ({size_mb:.2f} MB)")
        print("   这些是必需的，参考项目也包含了这些文件")

    # Danh sách đầy đủ DLL
    print("\n" + "=" * 70)
    print(" 完整 DLL 列表（按体积排序，前 20）")
    print("=" * 70)
    print(f"\n{'体积 (MB)':>10}  {'文件名':<30}  位置")
    print("-" * 70)

    for dll, size in dll_data[:20]:
        size_mb = size / 1024 / 1024
        relative_path = dll.relative_to(dist_dir)
        location = str(relative_path.parent) if relative_path.parent != Path('.') else "根目录"
        print(f"{size_mb:10.2f}  {dll.name:<30}  {location}")

    if len(dll_data) > 20:
        remaining_size = sum(size for _, size in dll_data[20:]) / 1024 / 1024
        print(f"... 还有 {len(dll_data) - 20} 个 DLL，共 {remaining_size:.2f} MB")


def get_optimization_suggestion(dll_name: str) -> list:
    """根据 DLL 名称给出优化建议"""
    suggestions = []

    if "openblas" in dll_name or "mkl" in dll_name:
        suggestions.append("数学运算库，参考项目的 libopenblas 有 26.85 MB")
        suggestions.append("如不需要高性能计算可考虑轻量版")

    elif "opencv" in dll_name or "ffmpeg" in dll_name:
        suggestions.append("OpenCV 相关，参考项目的 opencv_videoio_ffmpeg 有 18.48 MB")
        suggestions.append("考虑用 opencv-python-headless")

    elif "qt5" in dll_name or "qt6" in dll_name or "pyside" in dll_name:
        suggestions.append("Qt 库，参考项目的 Qt5Core 有 5.13 MB")
        suggestions.append("可排除不需要的模块（WebEngine, 3D, Charts）")

    elif "opengl" in dll_name and "sw" in dll_name:
        suggestions.append("OpenGL 软件渲染器，参考项目保留了 15.25 MB")
        suggestions.append("通常可以删除（使用硬件渲染）")

    elif "d3dcompiler" in dll_name:
        suggestions.append("DirectX 编译器，参考项目有 3.53 MB")

    elif "mfc140" in dll_name:
        suggestions.append("MFC 库，参考项目有 4.89 MB")

    return suggestions


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: python analyze_dlls.py <dist目录路径>")
        print("示例: python analyze_dlls.py dist/main.dist")
        sys.exit(1)

    analyze_dlls(sys.argv[1])
```

**Cách dùng**:
```bash
python analyze_dlls.py dist/你的软件名.dist
```

---

## Workflow tối ưu hoàn chỉnh

### Bước 1: Sửa cấu hình script biên dịch

Sửa `build_optimized.bat`, thay đổi 3 dòng này:

```batch
set APP_NAME=你的软件名      REM 改成实际名称
set MAIN_FILE=main.py        REM 你的主程序文件
set ICON_FILE=icon.ico       REM 你的图标文件
```

### Bước 2: Biên dịch + làm gọn một lệnh

```bash
# Chạy ở thư mục gốc project
build_optimized.bat
```

### Bước 3: Phân tích dependency DLL

```bash
python analyze_dlls.py dist/你的软件名.dist
```

### Bước 4: Tối ưu theo kết quả phân tích

**Nếu dùng OpenCV** → chuyển sang bản headless
```bash
pip uninstall opencv-python
pip install opencv-python-headless
```

**Nếu dùng Qt** → loại trừ các module không cần
```batch
# Thêm vào lệnh biên dịch
--nofollow-import-to=PyQt5.QtWebEngine,PyQt5.Qt3D,PyQt5.QtCharts
```

**Xóa software renderer** (nếu không cần)
```powershell
# Chạy trong thư mục dist
Remove-Item "opengl32sw.dll" -Force
```

---

## Giải pháp xử lý VC++ runtime

### Phương án 1: Static linking (khuyến nghị)
```bash
nuitka --static-libpython=yes ...
```

### Phương án 2: Gói kèm cài đặt runtime (khuyến nghị cho phát hành thương mại)
Thêm vào script Inno Setup:

```iss
; WARNING: VC++ 运行库架构必须与 Python/Nuitka 构建架构一致。
; 本 skill 推荐 32 位 Python，故默认捆绑 vc_redist.x86.exe；
; 若用 64 位 Python 编译，请把下面两处改为 vc_redist.x64.exe。
[Files]
Source: "{#MySourceDir}\..\vc_redist.x86.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Run]
Filename: "{tmp}\vc_redist.x86.exe"; Parameters: "/quiet /norestart"; StatusMsg: "正在安装运行库..."; Flags: waituntilterminated
```

> Địa chỉ tải: [Microsoft Visual C++ Redistributable](https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist)

---

## Mẫu script Inno Setup (Phiên bản thương mại tối thượng)

```iss
; =====================================================================
;  WARNING: 商业级 Python 安装脚本 (Inno Setup 6.x)
;  特性：LZMA2 极限压缩 | 全中文 | 完整元数据 | 无残留卸载
;  参考：参考项目(323 MB, LZMA2 压缩)
; =====================================================================

; --- 1. 参数定义 ---
#define MyAppName        "{{APP_NAME}}"
#define MyAppVersion     "{{APP_VERSION}}"
#define MyAppPublisher   "{{PUBLISHER}}"
#define MyAppURL         "{{APP_URL}}"
#define MyAppExeName     "{{EXE_NAME}}"
#define MySourceDir      "{{SOURCE_DIR}}"
#define MyOutputDir      "{{OUTPUT_DIR}}"
;#define MyIconPath      "{{ICON_PATH}}"

[Setup]
; --- 身份识别 ---
AppId={{GENERATE_RANDOM_GUID}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}

; --- 安装路径与权限 ---
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableDirPage=no
DisableProgramGroupPage=no
PrivilegesRequired=admin

; --- 输出设置 ---
OutputDir={#MyOutputDir}
OutputBaseFilename=Setup_{#MyAppName}_v{#MyAppVersion}

; --- 视觉体验 ---
WizardStyle=modern
#ifdef MyIconPath
SetupIconFile={#MyIconPath}
UninstallDisplayIcon={app}\{#MyAppExeName}
#endif

; ---  核心压缩 (参考 参考项目) ---
Compression=lzma2/ultra64
SolidCompression=yes
LZMAUseSeparateProcess=yes

; --- 架构 ---
; 注意：仅 64 位 Python 构建才设此项。本 skill 推荐 32 位 Python——
; 32 位构建请保持注释，使应用按 32 位安装并与上面捆绑的 vc_redist.x86.exe 匹配。
; 仅当用 64 位 Python 编译时才取消注释。
;ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Files]
Source: "{#MySourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[UninstallDelete]
Type: filesandordirs; Name: "{app}\*"

[Icons]
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\卸载 {#MyAppName}"; Filename: "{uninstallexe}"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
```

---

## Giải thích placeholder

| Placeholder | Mô tả | Giá trị ví dụ |
|--------|------|--------|
| `{{APP_NAME}}` | Tên hiển thị của phần mềm | `红墨批注` |
| `{{APP_VERSION}}` | Số phiên bản | `1.0.0` |
| `{{PUBLISHER}}` | Publisher/Tên công ty | `MyCompany` |
| `{{APP_URL}}` | Địa chỉ website | `https://example.com` |
| `{{EXE_NAME}}` | Tên file chương trình chính | `RedInk.exe` |
| `{{SOURCE_DIR}}` | Đường dẫn thư mục Nuitka dist | `D:\project\dist\RedInk.dist` |
| `{{OUTPUT_DIR}}` | Đường dẫn đầu ra của installer | `D:\project\output` |
| `{{ICON_PATH}}` | Đường dẫn file icon | `D:\project\icon.ico` |
| `{{GENERATE_RANDOM_GUID}}` | **Cần sinh GUID duy nhất** | Dùng Inno Setup "Tools > Generate GUID" |

---

## Câu hỏi thường gặp (FAQ)

### Q1: Cài xong nhấp đúp chương trình không phản ứng?
1. Mở CMD, chạy thủ công file exe để xem thông báo lỗi
2. Kiểm tra xem có thiếu VC++ runtime không
3. Kiểm tra xem biên dịch Nuitka có thành công không

### Q2: Installer quá lớn?
**Cách tối ưu**:
1. Biên dịch bằng Python 32-bit (tiết kiệm 20-30%)
2. Áp dụng danh sách loại trừ module của project tham chiếu
3. Bật plugin Anti-Bloat
4. Chạy script làm gọn thư mục dist
5. Phân tích DLL, loại bỏ các file lớn không cần thiết

### Q3: Phần mềm diệt virus báo nhầm?
**Giải pháp**:
- Gửi tới các hãng diệt virus lớn để xin đưa vào whitelist
- Mua chứng chỉ code signing (khuyến nghị: Sectigo, DigiCert)
- Tránh dùng nén UPX

### Q4: Khi cài đặt hiện thông báo Windows đã bảo vệ PC của bạn?
- Mua chứng chỉ EV code signing (được tin cậy ngay lập tức)
- Chứng chỉ code signing thông thường cần tích lũy lượng cài đặt để dần được tin cậy

---

## Ghi chép xử lý sự cố thực chiến (cập nhật 2026-02-07)

- **Cài xong báo thiếu python3xx.dll**: PHẢI dùng Nuitka `--standalone`; xác nhận dll này có trong dist; không build bản single-file.
- **Cài xong nhấp vào không phản ứng**: GUI có thể bị dependency nặng chặn trong giai đoạn khởi động; hoãn các dependency nặng đến khi "bắt đầu export" mới import; thêm log để điều tra.
- **Nuitka + MinGW báo lỗi với đường dẫn non-ASCII**: sao chép source sang thư mục ASCII rồi biên dịch; đặt `PYTHONIOENCODING=utf-8`.
- **Inno Setup cảnh báo `x64` đã bị deprecated (chỉ khi build 64-bit cần chế độ cài đặt 64-bit)**: đổi thành `ArchitecturesInstallIn64BitMode=x64compatible`; build 32-bit không cần mục này.
- **`--disable-console` đã bị deprecated**: dùng `--windows-console-mode=disable` thay thế.
- **dist xuất hiện `_nuitka_temp.exe`**: loại trừ nó trong [Files].

---

## Hiệu quả tối ưu kỳ vọng

| Tổ hợp tối ưu | Giảm dung lượng | Cải thiện khởi động | Mức rủi ro |
|----------|----------|----------|----------|
| Biên dịch cơ bản | Chuẩn | Chuẩn | Không |
| + `--lto=yes` | 5-10% | 10-20% | PASS: Không |
| + anti-bloat | 15-25% | - | PASS: Không |
| + Loại trừ module | 20-35% | 5% | PASS: Không |
| + Làm gọn dist | 25-40% | - | PASS: Không |
| + Biên dịch 32-bit | 40-60% | - | PASS: Không |
| **Tất cả kết hợp** | **45-65%** | **15-25%** | PASS: **Không có rủi ro** |

> WARNING: **Không khuyến nghị dùng nén UPX**, tuy có thể giảm dung lượng thêm nhưng rất dễ kích hoạt báo nhầm của phần mềm diệt virus.

---

**Được tối ưu dựa trên kinh nghiệm thực chiến của project tham chiếu, giúp bạn tạo installer cấp thương mại!**
