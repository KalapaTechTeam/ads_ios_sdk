# Lỗi và log của KalapaAdsSDK (iOS)

Tài liệu này dành cho hai nhóm người đọc:

- **Dev app tích hợp SDK:** SDK báo lỗi qua kênh nào, mỗi mã lỗi nghĩa là gì, app cần xử lý ra sao.
- **Team Kalapa (backend, QA, support):** đọc log trên `sdk-log.kalapa.vn` để biết lỗi xảy ra ở đâu và vì sao.

Mọi lỗi đều là `KLPAdError`. Mã lỗi (`code`) giống nhau trên iOS, Android và React Native.

---

## 1. App nhận lỗi ở đâu

| Tình huống | Kênh nhận | Giá trị |
|---|---|---|
| Load native ad | `NativeAdControllerDelegate.nativeAdController(_:didFinishLoading:)`, hoặc `controller.state` | `.noFill` hoặc `.failed(KLPAdError)` |
| User bấm ad nhưng mini-app không mở được | `NativeAdControllerDelegate.nativeAdController(_:didReceive:)` và `KalapaAds.miniAppListener` | `MiniAppEvent.openFailed(adId:error:)` |
| Gọi `KalapaAds.openMiniApp` | `completion` | `MiniAppOutcome.failed(KLPAdError)` |
| Mọi log của SDK | `KalapaAdsConfig.logHandler` | xem [mục 4](#4-log) |

```swift
func nativeAdController(_ controller: NativeAdController, didFinishLoading result: NativeAdLoadResult) {
    switch result {
    case .loaded:
        slot.isHidden = false
    case .noFill:
        slot.isHidden = true          // không có ad, không phải lỗi
    case .failed(let error):
        slot.isHidden = true
        print(error)                  // ví dụ: NO_VALID_CREATIVE, HTTP_ERROR(503)
    }
}
```

`KLPAdError` gồm:

| Thuộc tính | Ý nghĩa |
|---|---|
| `code` | Mã lỗi, xem [mục 2](#2-mã-lỗi) |
| `field` | Field gây lỗi trong JSON, ví dụ `target_url`, `content.theme.primary`. Chỉ có ở lỗi creative |
| `httpStatus` | Mã HTTP. Chỉ có ở `HTTP_ERROR` |
| `rejections` | Danh sách ad bị loại và lý do. Có ở `NO_VALID_CREATIVE` và `SLOT_TOO_SMALL` |
| `description` | Dạng chuỗi gọn để log: `CODE(field)(httpStatus)` |

**Nguyên tắc chung:** SDK không tự retry việc load ad. Khi nhận `.failed`, app ẩn slot rồi tự quyết định có gọi `load()` lại không, ví dụ khi user quay lại màn hình.

---

## 2. Mã lỗi

### 2.1 Lỗi khi load ad

| Mã | Khi nào | App nên làm gì |
|---|---|---|
| `NOT_INITIALIZED` | Gọi `load()` hoặc `openMiniApp` trước `KalapaAds.initialize(config:)` | Lỗi tích hợp: gọi `initialize` một lần lúc khởi động app |
| `NETWORK_ERROR` | Mất mạng, không kết nối được server | Ẩn slot. Có thể load lại khi có mạng |
| `TIMEOUT` | Server không trả lời trong `KalapaAdsConfig.requestTimeout` (mặc định 10 giây) | Ẩn slot |
| `HTTP_ERROR` | Server trả mã ngoài 2xx; xem `httpStatus` | Ẩn slot. Nếu là 4xx liên tục thì kiểm tra lại `adUnitId` |
| `PARSE_ERROR` | Body không phải JSON, hoặc thiếu mảng `ads` | Ẩn slot, báo team Kalapa |
| `NO_VALID_CREATIVE` | Server có trả ad, nhưng mọi ad đều sai dữ liệu. Lý do từng ad nằm trong `rejections` | Ẩn slot, báo team Kalapa kèm `rejections` |
| `SLOT_TOO_SMALL` | View nhỏ hơn template: strip cần 320×80, `promo_card`/`product_card` cần 320×250. Xảy ra lúc load (không ad nào vừa slot), hoặc khi slot co lại sau khi ad đã hiện (xoay màn hình, đổi layout) | Lỗi tích hợp: chỉnh kích thước `NativeAdView` |

`.noFill` **không phải lỗi**. Đó là trường hợp server không có ad cho user này, hoặc chỉ trả ad HTML kiểu cũ. App chỉ cần ẩn slot.

### 2.2 Lý do một ad bị loại (trong `rejections`)

Những mã này không bao giờ trả trực tiếp cho app, mà nằm trong `error.rejections[i].error`. SDK bỏ qua ad sai và dùng ad hợp lệ kế tiếp. Chỉ khi mọi ad đều sai thì app mới nhận `NO_VALID_CREATIVE`.

| Mã | Ý nghĩa | Ví dụ `field` |
|---|---|---|
| `UNSUPPORTED_TEMPLATE` | `template` không phải `strip`, `promo_card` hoặc `product_card` | `template` |
| `MISSING_REQUIRED_FIELD` | Thiếu field bắt buộc, field là `null`, hoặc chuỗi rỗng/toàn dấu cách | `target_url`, `content.title`, `theme` |
| `INVALID_FIELD_TYPE` | Field sai kiểu, ví dụ số thay cho chuỗi | `content.body`, `content.bullets[1]` |
| `INVALID_URL` | `target_url` không phải URL `https://` có host. Bị loại: `http://`, `moneyiq://`, `javascript:`, `tel:`, URL thiếu host… | `target_url` |
| `INVALID_COLOR` | Màu không đúng dạng `#RRGGBB` (không nhận alpha, không nhận `#RGB`) | `content.theme.primary` |
| `INVALID_SIZE` | `size` không phải số nguyên dương | `content.size` |
| `SIZE_TEMPLATE_MISMATCH` | `size` khác kích thước của template | `content.size` |
| `INVALID_BULLET_COUNT` | `product_card` không có đúng 3 bullet | `content.bullets` |
| `SLOT_TOO_SMALL` | Ad này lớn hơn slot | |

`theme` và `size` được đọc trong `content` trước, không có thì lấy ở cấp ad.

### 2.3 Lỗi khi mở mini-app

| Mã | Khi nào | App nên làm gì |
|---|---|---|
| `MINIAPP_INVALID_URL` | Ad flow: `target_url` còn placeholder lạ như `{ref}` (placeholder `placement={placement}` được SDK tự bỏ). `openMiniApp`: không truyền URL và config không có `miniAppURL`, hoặc host của URL không nằm trong `miniAppURL` / `miniAppAllowedHosts` | Ad flow: báo team Kalapa. `openMiniApp`: kiểm tra config |
| `MINIAPP_ALREADY_OPEN` | Đang có một mini-app mở, vì mỗi lúc chỉ mở được một mini-app | Chờ mini-app hiện tại đóng (`.closed`) rồi mở lại |
| `MINIAPP_PRESENTATION_FAILED` | Không present được màn hình mini-app. Các trường hợp: không có window đang active (app ở background); view controller dùng để present đang bị dismiss; hoặc view controller đó không nằm trong window nên iOS từ chối present | Mở lại khi app đang active. Với `openMiniApp`, truyền `presenter` đang hiển thị trên màn hình |

Khi user bấm ad mà mini-app không mở được, ad vẫn ở trên màn hình. Lưu ý: hiện SDK **vẫn tính 1 click** cho lần bấm đó.

---

## 3. Mini-app đóng

Mini-app đóng không phải lỗi. App nhận `MiniAppEvent.closed` (ad flow) hoặc `MiniAppOutcome.closed` (`openMiniApp`), kèm `reason`:

| `reason` | Ý nghĩa |
|---|---|
| `CALLBACK` | Trang tự đóng qua callback. `result` là `SUCCESS`, `FAILURE`, `CANCEL` hoặc `CLOSE` |
| `CLOSE_BUTTON` | User bấm nút đóng của SDK |
| `BACK_AT_ROOT` | User vuốt back khi đang ở trang đầu |
| `HOST_DISMISS` | App tự đóng màn hình mini-app |

`result` chỉ là điều trang báo lại, không phải xác nhận nghiệp vụ từ backend.

---

## 4. Log

### 4.1 Nhận log trong app

```swift
KalapaAds.initialize(config: KalapaAdsConfig(
    userId: "...",
    logHandler: { level, action, screenId, data, metadata in
        // Gọi trên main thread, với mọi mức log.
        MyLogger.log("[KalapaAds] \(level.stringValue) \(action) @\(screenId) \(data)")
    }
))
```

`logHandler` có cùng dạng với `logHandler` của eKYC và FaceOTP SDK. Ở bản Debug, SDK còn in log ra console với tiền tố `*** [KLP Ads] ***`.

### 4.2 Log gửi về Kalapa

- **Endpoint:** `POST https://sdk-log.kalapa.vn/api/events`. Cùng hệ thống log với eKYC và FaceOTP.
- **`source`:** luôn là `kalapa-ads`.
- **Mức log:** chỉ gửi từ `INFO` trở lên. `DEBUG` chỉ đến `logHandler`.
- **Request:** mỗi log gửi một request. Gặp 5xx, 429 hoặc mất mạng thì thử lại tối đa 3 lần (sau khoảng 1s, 4s, 16s). Gặp 4xx khác thì bỏ.
- **Lưu trữ:** log không được lưu xuống đĩa. Kill app hoặc mất mạng quá lâu thì log đó mất.

Payload (mỗi request là một mảng một phần tử):

```json
[{
  "action": "AD_LOAD_FAILED",
  "logLevel": "ERROR",
  "screenId": "NATIVE_AD",
  "sessionId": "8C1F…",
  "source": "kalapa-ads",
  "uid": "",
  "data": { "ad_unit_id": "be9abee4-…", "error_code": "NO_VALID_CREATIVE",
            "rejections": ["0:INVALID_URL(target_url)", "1:SLOT_TOO_SMALL"] },
  "metadata": { "timestamp": "1761730000123", "os_platform": "iOS", "os_version": "18.1",
                "device_model": "iPhone15,2", "device_brand": "Apple", "sdk_version": "0.1.0",
                "device_id": "<identifierForVendor>", "user_agent": "Kalapa-iOS/0.1.0" }
}]
```

`sessionId` đổi mỗi lần mở app. Dùng nó để gom các log của cùng một phiên.

### 4.3 Danh sách log

| `action` | Mức | `screenId` | Khi nào | `data` |
|---|---|---|---|---|
| `AD_LOAD_FAILED` | ERROR | `NATIVE_AD` | Load ad lỗi (mọi mã ở mục 2.1) | `ad_unit_id`, `error_code`, `http_status`?, `field`?, `rejections`? |
| `AD_NO_FILL` | DEBUG | `NATIVE_AD` | Không có ad (không gửi server) | `ad_unit_id` |
| `AD_SLOT_TOO_SMALL` | WARNING | `NATIVE_AD` | Slot co lại nhỏ hơn template sau khi ad đã hiện | `ad_unit_id`, `ad_id`, `ad_size`, `slot_size` (dạng `320x80`) |
| `AD_EVENT_DROPPED` | WARNING | `NATIVE_AD` | Backend từ chối event display/click (4xx); event bị bỏ | `event_type`, `ad_id`, `ad_unit_id`, `http_status`? |
| `MINIAPP_OPEN_FAILED` | ERROR | `MINI_APP` | Không mở được mini-app (mục 2.3) | `error_code`, `flow` (`ad`/`direct`), `ad_id`?, `reason`? (`no_url`, `host_not_allowed`) |
| `MINIAPP_LOAD_FAILED` | ERROR | `MINI_APP` | Trang mini-app load lỗi; user thấy màn hình thử lại | `error_domain`, `error_code` (mã `NSError`), `host`? |
| `MINIAPP_CRASHED` | ERROR | `MINI_APP` | WebKit kill trang (thiếu bộ nhớ, crash); user thấy màn hình thử lại | `host`? |
| `MINIAPP_NAVIGATION_BLOCKED` | WARNING | `MINI_APP` | Trang điều hướng sang scheme không được phép | `scheme`, `host`? |

Dấu `?` nghĩa là chỉ có khi có giá trị.

`rejections` có dạng `"<vị trí ad trong response>:<MÃ>(<field>)"`, ví dụ `"0:MISSING_REQUIRED_FIELD(target_url)"`.

### 4.4 Dữ liệu cá nhân

- Log **không bao giờ** chứa `user_id` (số CCCD), `full_name`, `phone_number`, `amount`, `period`, cũng không chứa URL mini-app đầy đủ (URL có kèm các field đó). Với mini-app, log chỉ ghi `host`.
- `uid` luôn rỗng.
- Trước khi gửi, SDK lọc thêm một lần: key nào có tên chứa `user_id`, `full_name`, `phone`, `amount`, `period`, `url`, `cccd`, `token`… sẽ bị bỏ, và tên key bị bỏ được ghi vào `redacted_keys`.
- `logHandler` của app nhận `data` chưa qua bộ lọc này, nhưng `data` do SDK tự tạo nên cũng không chứa các field kể trên.

---

## 5. Tra nhanh khi gặp lỗi

| Thấy gì | Xem ở đâu |
|---|---|
| Ad không hiện | `didFinishLoading`: `.noFill` là bình thường; `.failed` thì tra mã ở mục 2.1 |
| `NO_VALID_CREATIVE` | `rejections`: mỗi phần tử cho biết ad thứ mấy sai field nào, tra ở mục 2.2 |
| Bấm ad không có gì xảy ra | `didReceive miniAppEvent`: tìm `openFailed` và tra ở mục 2.3. Nếu không có event nào, ad chưa ở trạng thái hiển thị, hoặc user bấm 2 lần trong vòng 1 giây |
| Mini-app trắng hoặc hiện màn hình thử lại | Log `MINIAPP_LOAD_FAILED` / `MINIAPP_CRASHED` |
| Cần xem log của một máy | Lọc trên `sdk-log.kalapa.vn` theo `source = kalapa-ads` và `metadata.device_id` |

