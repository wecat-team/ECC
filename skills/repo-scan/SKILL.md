---
name: repo-scan
description: "Bootstrap pointer cài đặt skill repo-scan bên ngoài từ một commit đã ghim (pinned), có thể review. Dùng khi cần cài repo-scan trước khi chạy audit tài sản mã nguồn đa stack (cross-stack source-code asset audit); pointer ECC này không tự thực hiện audit."
metadata:
  origin: community
---

# repo-scan

> Mỗi hệ sinh thái đều có trình quản lý dependency riêng, nhưng không có công cụ nào nhìn xuyên suốt C++, Android, iOS và Web để cho bạn biết: bao nhiêu code thực sự là của bạn, phần nào là của bên thứ ba, và phần nào là gánh nặng vô ích.

## Khi nào dùng

- Tiếp quản một codebase legacy lớn và cần cái nhìn tổng quan về cấu trúc
- Trước khi refactor lớn — xác định phần nào là lõi, phần nào trùng lặp, phần nào đã chết
- Audit các dependency bên thứ ba được nhúng trực tiếp vào mã nguồn (không khai báo trong package manager)
- Chuẩn bị architecture decision record cho việc tái tổ chức monorepo

## Cài đặt

```bash
# Clone first so the pinned commit can be reviewed before installation
set -euo pipefail

REPO_SCAN_COMMIT=2742664ebcad1450c208eda0ae45d3c17fad5dd8
REPO_SCAN_INSTALL_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/repo-scan"
REPO_SCAN_INSTALL_PARENT="$(dirname "$REPO_SCAN_INSTALL_DIR")"
mkdir -p "$REPO_SCAN_INSTALL_PARENT"
REPO_SCAN_TMP="$(mktemp -d "$REPO_SCAN_INSTALL_PARENT/.repo-scan-install.XXXXXX")"
REPO_SCAN_TOKEN="${REPO_SCAN_TMP##*.}"
REPO_SCAN_STAGE="$REPO_SCAN_TMP/stage-$REPO_SCAN_TOKEN"
REPO_SCAN_BACKUP="$REPO_SCAN_TMP/backup-$REPO_SCAN_TOKEN"
REPO_SCAN_LOCK="$REPO_SCAN_INSTALL_PARENT/.repo-scan-install.lock"
REPO_SCAN_KEEP_TMP=0
REPO_SCAN_LOCK_HELD=0
REPO_SCAN_MV_HAS_NO_TARGET=0
cleanup_repo_scan_install() {
  if [ "$REPO_SCAN_KEEP_TMP" -eq 0 ]; then
    rm -rf -- "$REPO_SCAN_TMP"
  fi
  if [ "$REPO_SCAN_LOCK_HELD" -eq 1 ] && ! rmdir -- "$REPO_SCAN_LOCK"; then
    printf 'Could not release installation lock at %s\n' "$REPO_SCAN_LOCK" >&2
  fi
}
trap cleanup_repo_scan_install EXIT
mkdir "$REPO_SCAN_TMP/mv-probe-source"
if mv -T -- "$REPO_SCAN_TMP/mv-probe-source" \
  "$REPO_SCAN_TMP/mv-probe-destination" 2>/dev/null; then
  REPO_SCAN_MV_HAS_NO_TARGET=1
  rmdir "$REPO_SCAN_TMP/mv-probe-destination"
else
  rmdir "$REPO_SCAN_TMP/mv-probe-source"
fi
move_repo_scan_dir() {
  REPO_SCAN_MOVE_SOURCE=$1
  REPO_SCAN_MOVE_DESTINATION=$2
  REPO_SCAN_MOVE_NAME=${REPO_SCAN_MOVE_SOURCE##*/}
  if [ -e "$REPO_SCAN_MOVE_DESTINATION" ] || [ -L "$REPO_SCAN_MOVE_DESTINATION" ]; then
    return 1
  fi
  if [ "$REPO_SCAN_MV_HAS_NO_TARGET" -eq 1 ]; then
    mv -T -- "$REPO_SCAN_MOVE_SOURCE" "$REPO_SCAN_MOVE_DESTINATION"
    return
  fi
  if ! mv -- "$REPO_SCAN_MOVE_SOURCE" "$REPO_SCAN_MOVE_DESTINATION"; then
    return 1
  fi
  if [ -e "$REPO_SCAN_MOVE_DESTINATION/$REPO_SCAN_MOVE_NAME" ] || \
    [ -L "$REPO_SCAN_MOVE_DESTINATION/$REPO_SCAN_MOVE_NAME" ]; then
    if ! mv -- "$REPO_SCAN_MOVE_DESTINATION/$REPO_SCAN_MOVE_NAME" \
      "$REPO_SCAN_MOVE_SOURCE"; then
      REPO_SCAN_KEEP_TMP=1
      printf 'Move conflict recovery failed; staged data remains at %s\n' \
        "$REPO_SCAN_MOVE_DESTINATION/$REPO_SCAN_MOVE_NAME" >&2
    fi
    return 1
  fi
}

git clone --filter=blob:none --no-checkout \
  https://github.com/haibindev/repo-scan.git "$REPO_SCAN_TMP/source"
git -C "$REPO_SCAN_TMP/source" checkout --detach "$REPO_SCAN_COMMIT"
mkdir -p "$REPO_SCAN_STAGE"
git -C "$REPO_SCAN_TMP/source" archive "$REPO_SCAN_COMMIT" | \
  tar -xf - -C "$REPO_SCAN_STAGE"

# Review "$REPO_SCAN_TMP/source" before approving installation.
printf 'Type install to replace %s after reviewing the pinned source: ' \
  "$REPO_SCAN_INSTALL_DIR" >&2
read -r REPO_SCAN_CONFIRM
if [ "$REPO_SCAN_CONFIRM" != install ]; then
  printf 'Installation cancelled.\n' >&2
  exit 1
fi
if ! mkdir -- "$REPO_SCAN_LOCK" 2>/dev/null; then
  printf 'Another repo-scan installation holds the lock at %s\n' \
    "$REPO_SCAN_LOCK" >&2
  exit 1
fi
REPO_SCAN_LOCK_HELD=1

if [ -e "$REPO_SCAN_INSTALL_DIR" ] || [ -L "$REPO_SCAN_INSTALL_DIR" ]; then
  move_repo_scan_dir "$REPO_SCAN_INSTALL_DIR" "$REPO_SCAN_BACKUP"
fi
if ! move_repo_scan_dir "$REPO_SCAN_STAGE" "$REPO_SCAN_INSTALL_DIR"; then
  if [ -e "$REPO_SCAN_BACKUP" ] || [ -L "$REPO_SCAN_BACKUP" ]; then
    if [ -e "$REPO_SCAN_INSTALL_DIR" ] || [ -L "$REPO_SCAN_INSTALL_DIR" ]; then
      REPO_SCAN_KEEP_TMP=1
      printf 'Replacement failed and target was recreated; previous installation preserved at %s\n' \
        "$REPO_SCAN_BACKUP" >&2
    elif ! move_repo_scan_dir "$REPO_SCAN_BACKUP" "$REPO_SCAN_INSTALL_DIR"; then
      REPO_SCAN_KEEP_TMP=1
      printf 'Replacement and rollback failed; previous installation preserved at %s\n' \
        "$REPO_SCAN_BACKUP" >&2
    fi
  fi
  exit 1
fi
```

> Hãy review mã nguồn trước khi cài đặt bất kỳ agent skill nào.

Việc cài đặt chỉ hoàn tất bước bootstrap. Hãy tải lại agent harness, rồi gọi lại `repo-scan`. Pointer ECC này cài đặt skill bên ngoài nhưng không tự chạy scan.

## Năng lực cốt lõi

| Năng lực | Mô tả |
|---|---|
| **Cross-stack scanning** | C/C++, Java/Android, iOS (OC/Swift), Web (TS/JS/Vue) trong một lượt |
| **Phân loại file** | Mỗi file được gắn nhãn là code dự án, bên thứ ba hoặc build artifact |
| **Phát hiện thư viện** | Hơn 50 thư viện đã biết (FFmpeg, Boost, OpenSSL…) kèm trích xuất phiên bản |
| **Kết luận bốn mức** | Core Asset / Extract & Merge / Rebuild / Deprecate |
| **Báo cáo HTML** | Trang tương tác giao diện tối với điều hướng drill-down |
| **Hỗ trợ monorepo** | Quét phân cấp với báo cáo tổng hợp + báo cáo từng sub-project |

## Các mức độ sâu của phân tích

| Mức | Số file đọc | Use Case |
|---|---|---|
| `fast` | 1-2 mỗi module | Kiểm kê nhanh các thư mục khổng lồ |
| `standard` | 2-5 mỗi module | Audit mặc định với kiểm tra đầy đủ dependency + kiến trúc |
| `deep` | 5-10 mỗi module | Bổ sung thread safety, quản lý bộ nhớ, tính nhất quán của API |
| `full` | Tất cả file | Review toàn diện trước khi merge |

## Cách hoạt động

1. **Phân loại bề mặt repo**: liệt kê file, rồi gắn nhãn từng file là code dự án, code bên thứ ba được nhúng, hoặc build artifact.
2. **Phát hiện thư viện nhúng**: kiểm tra tên thư mục, header, file license và dấu hiệu phiên bản để xác định các dependency được đóng gói kèm và phiên bản khả dĩ.
3. **Chấm điểm từng module**: nhóm file theo module hoặc subsystem, rồi gán một trong bốn kết luận dựa trên quyền sở hữu, mức độ trùng lặp và chi phí bảo trì.
4. **Làm nổi bật rủi ro cấu trúc**: chỉ ra các artifact vô ích, wrapper bị nhân bản, code vendored đã lỗi thời, và các module nên được extract, rebuild hoặc deprecate.
5. **Tạo báo cáo**: trả về bản tóm tắt ngắn gọn cùng đầu ra HTML tương tác với drill-down theo từng module để có thể review audit một cách bất đồng bộ.

## Ví dụ

Trên một monorepo C++ gồm 50.000 file:
- Phát hiện FFmpeg 2.x (đời 2015) vẫn đang chạy trong production
- Phát hiện cùng một SDK wrapper bị nhân bản 3 lần
- Xác định 636 MB build artifact Debug/ipch/obj đã bị commit
- Phân loại: 3 MB code dự án so với 596 MB bên thứ ba

## Best Practice

- Bắt đầu với mức `standard` cho lần audit đầu tiên
- Dùng `fast` cho monorepo có hơn 100 module để kiểm kê nhanh
- Chạy `deep` dần dần trên các module được đánh dấu cần refactor
- Xem lại phân tích cross-module để phát hiện trùng lặp giữa các sub-project

## Liên kết

- [GitHub Repository](https://github.com/haibindev/repo-scan)
