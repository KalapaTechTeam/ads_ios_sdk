# KalapaAdsDemo

App iOS mẫu tích hợp [KalapaAdsSDK](../README.md) qua CocoaPods, giống cách một app đối tác sẽ làm. Dùng để xem thử các loại quảng cáo, mini-app và luồng mở mini-app từ thông báo trên thiết bị thật hoặc simulator, và để tham khảo code tích hợp.

## Chạy app

Yêu cầu: Xcode 16 trở lên, CocoaPods.

```bash
cd Demo
pod install
open KalapaAdsDemo.xcworkspace
```

Chạy trên simulator không cần cấu hình gì thêm. Chạy trên máy thật thì vào target **KalapaAdsDemo → Signing & Capabilities**, chọn Team của anh/chị, và đổi Bundle Identifier nếu cần.

App kết nối server quảng cáo thật. Mini-app mặc định là bản UAT (`https://uat.moneyiq.vn/mini-app`), nên test không tạo hồ sơ vay thật.

## Các màn hình

| Màn | Nội dung |
|---|---|
| **Native Ads** | 1–3 vị trí native ad (UIKit) với các template strip, promo card, product card. Bấm vào ad để mở mini-app. Log ghi các sự kiện load, impression, viewable, click, đóng, mini-app |
| **SwiftUI** | Native ad đặt trong một feed SwiftUI bằng `NativeAdSlot` |
| **Banner** / **Interstitial** | Định dạng quảng cáo HTML |
| **Mini-app trực tiếp** | `KalapaAds.openMiniApp` không qua quảng cáo: URL mặc định, URL tự nhập, URL không được phép, bật/tắt nút đóng của SDK, và gửi thông báo thử |
| **Settings** (biểu tượng bánh răng) | Ad unit, thông tin user gửi sang mini-app, URL mini-app mặc định |

## Settings

| Mục | Ý nghĩa |
|---|---|
| Ad unit native | Một hoặc nhiều ad unit, cách nhau bằng dấu phẩy. Các vị trí ở màn Native lần lượt dùng từng ad unit. Có hiệu lực ngay ở lần mở màn sau |
| `user_id`, `full_name`, `phone_number`, `amount`, `period` | Truyền vào `KalapaAdsConfig`, được SDK gắn vào URL mini-app. Để trống thì SDK không gửi |
| URL mặc định (`miniAppURL`) | Trang mở khi gọi `openMiniApp()` không truyền URL |

SDK đọc config **một lần khi app khởi động**. Sửa thông tin user hoặc URL mini-app xong thì phải **tắt hẳn app rồi mở lại** để áp dụng.

`source` gửi sang mini-app được SDK tự lấy từ bundle ID của app, bỏ các phần `com`/`vn`. Với bundle ID `vn.kalapa.ads.demo`, giá trị là `kalapa.ads.demo`.

## Thử mở mini-app từ thông báo

1. Vào **Mini-app trực tiếp**.
2. Nhập URL, hoặc để trống để mở URL mặc định.
3. Bấm **Gửi thông báo mở URL đã nhập (sau 5 giây)**. Lần đầu app hỏi quyền gửi thông báo.
4. Trong 5 giây đó, thử một trong ba trường hợp:
   - ở lại trong app;
   - về màn hình chính của máy;
   - vuốt tắt hẳn app.
5. Bấm vào thông báo: mini-app mở. Kết quả hiện trong log của màn, hoặc bằng alert nếu màn đó không mở.

## Code tích hợp nên xem

| File | Nội dung |
|---|---|
| [AppDelegate.swift](KalapaAdsDemo/App/AppDelegate.swift) | Gọi `KalapaAds.initialize`, đặt delegate thông báo ngay khi app khởi động |
| [DemoSettings.swift](KalapaAdsDemo/Common/DemoSettings.swift) | Dựng `KalapaAdsConfig`, kèm `logHandler` in log của SDK ra console |
| [NativeDemoViewController.swift](KalapaAdsDemo/Screens/Native/NativeDemoViewController.swift) | `NativeAdController` + `NativeAdView`, xử lý `NativeAdControllerDelegate` |
| [SwiftUIDemoView.swift](KalapaAdsDemo/Screens/SwiftUI/SwiftUIDemoView.swift) | `@StateObject NativeAdController` + `NativeAdSlot` |
| [MiniAppDemoViewController.swift](KalapaAdsDemo/Screens/MiniApp/MiniAppDemoViewController.swift) | `KalapaAds.openMiniApp` và các kết quả `MiniAppOutcome` |
| [DemoNotifications.swift](KalapaAdsDemo/Common/DemoNotifications.swift) | Gửi local notification và mở mini-app khi user bấm vào |

Log của SDK in ra console Xcode với tiền tố `[KalapaAds]`. Ý nghĩa các mã lỗi: [docs/ERRORS.md](../docs/ERRORS.md).
