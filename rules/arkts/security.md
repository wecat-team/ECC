---
paths:
  - "**/*.ets"
  - "**/*.ts"
  - "**/module.json5"
---
# Bảo mật HarmonyOS / ArkTS

> File này mở rộng [common/security.md](../common/security.md) với các thực hành bảo mật riêng cho HarmonyOS.

## Quản lý Permission

### Khai báo Permission trong module.json5

Mọi lời gọi system API yêu cầu permission đều PHẢI được khai báo:

```json5
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET",
        "reason": "$string:internet_permission_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "always"
        }
      }
    ]
  }
}
```

### Checklist Permission

Trước khi gọi system API, hãy xác minh:

- [ ] Permission đã được khai báo trong `module.json5`
- [ ] Chuỗi lý do xin permission đã được định nghĩa trong resource (với các permission hiển thị cho người dùng)
- [ ] Đã triển khai yêu cầu permission lúc runtime cho các permission nhạy cảm (camera, vị trí, v.v.)
- [ ] Kiểm tra permission trước khi gọi API, kèm fallback nhẹ nhàng khi bị từ chối

### Yêu cầu Permission lúc Runtime

```typescript
import { abilityAccessCtrl, bundleManager, Permissions } from '@kit.AbilityKit';

async function checkAndRequestPermission(permission: Permissions): Promise<boolean> {
  const atManager = abilityAccessCtrl.createAtManager();
  const bundleInfo = await bundleManager.getBundleInfoForSelf(
    bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
  );
  const tokenId = bundleInfo.appInfo.accessTokenId;
  const grantStatus = await atManager.checkAccessToken(tokenId, permission);

  if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
    return true;
  }

  const result = await atManager.requestPermissionsFromUser(getContext(), [permission]);
  return result.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
}
```

## Quản lý Secret

- **KHÔNG BAO GIỜ** hardcode API key, token hoặc mật khẩu trong file nguồn `.ets`/`.ts`
- Dùng HarmonyOS Preferences API cho cấu hình không nhạy cảm
- Dùng HarmonyOS Keystore cho credential nhạy cảm
- Cấu hình theo từng môi trường nên được quản lý qua build profile

```typescript
// BAD: hardcoded secret
const API_KEY: string = 'sk-xxxxxxxxxxxx';

// GOOD: from build profile config (non-sensitive)
import { BuildProfile } from 'BuildProfile';
const endpoint = BuildProfile.API_ENDPOINT;

// GOOD: use HUKS to encrypt/decrypt data without exposing key material
import { huks } from '@kit.UniversalKeystoreKit';
async function decryptWithKeystore(alias: string, nonce: Uint8Array, aad: Uint8Array, cipherData: Uint8Array): Promise<Uint8Array> {
  const options: huks.HuksOptions = {
    properties: [
      { tag: huks.HuksTag.HUKS_TAG_ALGORITHM, value: huks.HuksKeyAlg.HUKS_ALG_AES },
      { tag: huks.HuksTag.HUKS_TAG_PURPOSE, value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT },
      { tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE, value: huks.HuksCipherMode.HUKS_MODE_GCM },
      { tag: huks.HuksTag.HUKS_TAG_PADDING, value: huks.HuksKeyPadding.HUKS_PADDING_NONE },
      { tag: huks.HuksTag.HUKS_TAG_NONCE, value: nonce },
      { tag: huks.HuksTag.HUKS_TAG_ASSOCIATED_DATA, value: aad }
    ],
    inData: cipherData
  };
  const handle = await huks.initSession(alias, options);
  const result = await huks.finishSession(handle.handle, options);
  return result.outData;
}
```

## Kiểm tra đầu vào (Input Validation)

- Validate mọi input của người dùng trước khi xử lý
- Sanitize dữ liệu trước khi hiển thị trên UI để ngăn injection
- Validate tham số deep link trước khi điều hướng

```typescript
// Validate before navigation
function handleDeepLink(uri: string): void {
  const allowedPaths: string[] = ['detail', 'settings', 'profile'];
  const parsed = new URL(uri);
  const path = parsed.pathname.replace('/', '');

  if (!allowedPaths.includes(path)) {
    hilog.warn(0x0000, 'DeepLink', 'Invalid deep link path: %{public}s', path);
    return;
  }

  navPathStack.pushPath({ name: path });
}
```

## Bảo mật mạng

- Luôn dùng HTTPS cho các request mạng
- Validate certificate của server
- Triển khai timeout và chính sách retry cho request
- KHÔNG BAO GIỜ log dữ liệu nhạy cảm (token, credential của người dùng) trong log request/response mạng

## Bảo mật lưu trữ dữ liệu

- Dùng encrypted preferences cho dữ liệu cục bộ nhạy cảm
- Xóa dữ liệu nhạy cảm khỏi bộ nhớ khi không còn cần
- Triển khai quản lý vòng đời dữ liệu phù hợp
- Cân nhắc phân loại dữ liệu (công khai, nội bộ, bảo mật) khi chọn cơ chế lưu trữ

## Bảo mật Dependency

- Chỉ dùng dependency từ nguồn đáng tin cậy (ohpm registry chính thức)
- Xác minh phiên bản dependency trong `oh-package.json5`
- Thường xuyên kiểm tra các lỗ hổng đã biết trong thư viện bên thứ ba
- Ghim (pin) phiên bản dependency để tránh cập nhật ngoài ý muốn
