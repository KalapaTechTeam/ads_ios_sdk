# KalapaAdsSDK cho iOS

Hướng dẫn tích hợp Kalapa Ads SDK vào app iOS.

SDK hiển thị quảng cáo của Kalapa Ads Network, chủ yếu là sản phẩm tài chính như vay và thẻ tín dụng. SDK có:

- **Native ad:** quảng cáo vẽ bằng UIKit theo 3 template `strip`, `promo_card`, `product_card`. Dùng được với UIKit và SwiftUI.
- **Mini-app:** khi user bấm ad, SDK mở trang mini-app toàn màn hình. App cũng có thể tự mở mini-app không qua ad, ví dụ khi user bấm thông báo.
- **Banner và interstitial dạng HTML:** định dạng cũ chuyển sang từ KalapaScoreSDK, xem [mục 8](#8-banner-và-interstitial-định-dạng-cũ).

Mã lỗi và log: [docs/ERRORS.md](docs/ERRORS.md).

---

## 1. Yêu cầu

| | |
|---|---|
| iOS | 15.1 trở lên |
| Swift | 5.9 trở lên |
| Cài đặt | CocoaPods |
| Framework hệ thống | UIKit, WebKit, SwiftUI, Combine (CocoaPods tự link) |

## 2. Cài đặt

Thêm vào `Podfile`:

```ruby
platform :ios, '15.1'

target 'YourApp' do
  use_frameworks!
  pod 'KalapaAdsSDK', '~> 0.1'
end
```

Rồi chạy:

```bash
pod repo update
pod install
```

SDK được phát hành dạng binary (`KalapaAdsSDK.xcframework` kèm `KalapaAdsSDK.bundle`) trên [GitHub](https://github.com/KalapaTechTeam/ads_ios_sdk/releases). Khi build, CocoaPods tự copy `KalapaAdsSDK.bundle` (giao diện các template, màn mini-app, privacy manifest) vào app; app không cần làm gì thêm.

**Cập nhật lên bản mới:**

```bash
pod repo update
pod update KalapaAdsSDK
```

**Gặp lỗi `Unable to find a specification for KalapaAdsSDK`:** máy chưa có danh sách pod mới nhất. Chạy `pod repo update` rồi `pod install` lại.

## 3. Khởi tạo

Gọi `KalapaAds.initialize` **một lần**, ngay khi app khởi động. Config được giữ cố định trong suốt vòng đời process, và các lần gọi sau đều bị bỏ qua.

```swift
import KalapaAdsSDK

func application(_ application: UIApplication,
                 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    KalapaAds.initialize(config: KalapaAdsConfig(
        userId: "001094018640",
        fullName: "Nguyễn Văn A",
        phoneNumber: "0965234589",
        amount: "50000000",
        period: "12",
        miniAppURL: URL(string: "https://moneyiq.vn/mini-app"),
        logHandler: { level, action, screenId, data, metadata in
            print("[KalapaAds] \(level.stringValue) \(action) @\(screenId) \(data)")
        }
    ))
    return true
}
```

### `KalapaAdsConfig`

Mọi tham số đều không bắt buộc.

| Tham số | Kiểu | Mặc định | Ý nghĩa |
|---|---|---|---|
| `userId` | `String?` | `nil` | Số CCCD của user (`id_card_number`). Dùng `String` để giữ số 0 ở đầu |
| `fullName` | `String?` | `nil` | Họ tên. Bị bỏ nếu chứa một trong các ký tự `!@#$%^*(` |
| `phoneNumber` | `String?` | `nil` | Số điện thoại |
| `amount` | `String?` | `nil` | Số tiền vay mong muốn |
| `period` | `String?` | `nil` | Kỳ hạn vay (tháng), là số nguyên dương như `"12"`. Giá trị khác bị bỏ |
| `miniAppURL` | `URL?` | `nil` | Mini-app mặc định cho `openMiniApp`, xem [mục 6.3](#63-mở-mini-app-không-qua-ad-ví-dụ-từ-thông-báo). Ngoài production thì dùng URL UAT |
| `miniAppAllowedHosts` | `Set<String>` | `[]` | Các host khác mà `openMiniApp` được mở, ngoài host của `miniAppURL` |
| `requestTimeout` | `TimeInterval` | `10` | Thời gian chờ tối đa khi load ad (giây) |
| `idGenerator` | `(() -> String)?` | `nil` | Hàm tạo id riêng cho event và phiên hiển thị. Không truyền thì SDK tự tạo |
| `allowsInsecureURLs` | `Bool` | `false` | Cho phép ad và mini-app dùng `http://`. Chỉ có tác dụng ở bản Debug |
| `logHandler` | `KLPAdLogHandler?` | `nil` | Nhận mọi log của SDK, xem [mục 7](#7-log-và-lỗi) |

`userId`, `fullName`, `phoneNumber`, `amount` và `period` được gắn vào URL mini-app để user không phải nhập lại. Field nào để `nil` hoặc rỗng thì SDK không gửi field đó.

---

## 4. Native ad với UIKit

Mỗi vị trí đặt ad cần hai thứ:
- `NativeAdController`: giữ trạng thái và dữ liệu của ad.
- `NativeAdView`: view hiển thị ad.

**App giữ controller** (ví dụ trong view controller của màn hình). View có thể bị tạo lại, ví dụ khi cell được tái sử dụng, nhưng controller thì phải giữ nguyên.

```swift
import KalapaAdsSDK

final class HomeViewController: UIViewController {

    private let adController = NativeAdController(adUnitId: "<ad unit id>")
    private let adView = NativeAdView()

    override func viewDidLoad() {
        super.viewDidLoad()
        adController.delegate = self
        adView.controller = adController
        adView.isHidden = true

        adView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(adView)
        NSLayoutConstraint.activate([
            adView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            adView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            adView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            // Chiều cao lấy theo template, qua intrinsicContentSize
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if adController.state == .idle {
            adController.load()
        }
    }

    deinit {
        let controller = adController
        Task { @MainActor in controller.dispose() }
    }
}

extension HomeViewController: NativeAdControllerDelegate {
    func nativeAdController(_ controller: NativeAdController, didFinishLoading result: NativeAdLoadResult) {
        switch result {
        case .loaded:
            adView.isHidden = false
        case .noFill, .failed:
            adView.isHidden = true
        }
    }

    func nativeAdController(_ controller: NativeAdController, didRequestClose info: NativeAdEventInfo) {
        adView.isHidden = true   // user bấm × trên strip
    }
}
```

### Kích thước

| Template | Kích thước tối thiểu của `NativeAdView` |
|---|---|
| `strip` | 320 × 80 |
| `promo_card`, `product_card` | 320 × 250 |

Template giãn ra theo chiều rộng của view và giữ nguyên chiều cao.

- Nên đặt view vào layout **trước khi gọi `load()`**. Khi đó SDK biết kích thước slot và tự bỏ qua các ad không vừa.
- Nếu slot nhỏ hơn template, load trả về `.failed(SLOT_TOO_SMALL)`. Slot co lại sau khi ad đã hiện (ví dụ xoay màn hình) cũng cho lỗi này.

### Vòng đời

| Hàm | Khi nào gọi |
|---|---|
| `load(datasetId:)` | Load hoặc load lại ad. Load lại sẽ kết thúc phiên hiển thị hiện tại. `datasetId` chỉ dùng khi Kalapa yêu cầu |
| `dispose()` | Khi bỏ hẳn vị trí ad. Gọi nhiều lần cũng không sao. Sau `dispose()`, các lần gọi `load()` đều không có tác dụng |
| `setVisibleRatio(_:)` | Khi app biết rõ hơn SDK phần ad đang hiển thị (0...1), ví dụ ad bị UI của app che. Truyền `nil` để SDK tự đo lại |

`controller.state` có các giá trị `idle`, `loading`, `ready(NativeAd)`, `noFill`, `failed(KLPAdError)`, `hidden` (user đã đóng), `disposed`.

### `NativeAdControllerDelegate`

Mọi hàm đều không bắt buộc và đều được gọi trên main thread.

| Hàm | Khi nào |
|---|---|
| `didFinishLoading(_:)` | Load xong: `.loaded`, `.noFill` hoặc `.failed` |
| `didRecordImpression(_:)` | Ad bắt đầu hiện trên màn hình; mỗi phiên hiển thị chỉ gọi một lần |
| `didRecordViewableImpression(_:)` | Ad hiện từ 50% diện tích trở lên, liên tục 1 giây |
| `didClick(_:)` | User bấm ad. Hai lần bấm cách nhau dưới 1 giây chỉ tính một |
| `didRequestClose(_:)` | User bấm × trên `strip`; ad đã bị ẩn, app thu gọn slot nếu cần |
| `didRequestInfo(_:)` | User bấm nhãn "Quảng cáo" |
| `didReceive(_ miniAppEvent:)` | Mini-app mở được, mở lỗi, hoặc đã đóng, xem [mục 6](#6-mini-app) |

SDK tự gửi event display/click về Kalapa. App không cần gọi API nào.

### Trong `UITableView` / `UICollectionView`

Giữ controller theo vị trí trong danh sách, không giữ theo cell. Khi cấu hình cell thì gán `cell.adView.controller = controllerForRow`. Gán controller cho view mới không tính thêm impression.

---

## 5. Native ad với SwiftUI

```swift
import KalapaAdsSDK
import SwiftUI

struct FeedView: View {
    @StateObject private var ad = NativeAdController(adUnitId: "<ad unit id>")

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // ... nội dung
                NativeAdSlot(controller: ad)
                    .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            if ad.state == .idle { ad.load() }
        }
    }
}
```

`NativeAdSlot` tự lấy kích thước theo template đã load. Khi chưa có ad thì slot có kích thước 0, nên không cần tự ẩn. `NativeAdController` là `ObservableObject`, nên view tự cập nhật theo `ad.state`.

---

## 6. Mini-app

### 6.1 Mở từ ad

User bấm ad thì SDK tự mở mini-app toàn màn hình, app không cần làm gì. URL được lấy từ `target_url` mà server trả về, cộng thêm:

| Tham số | Lấy từ |
|---|---|
| `user_id`, `full_name`, `phone_number`, `amount`, `period` | `KalapaAdsConfig` |
| `source` | Bundle ID của app, bỏ các phần `com` và `vn`. Ví dụ `com.kalapa.icallme` thành `kalapa.icallme`. App không cần config |

Mỗi lúc chỉ mở được một mini-app.

### 6.2 Theo dõi mini-app

Mini-app mở từ ad báo về qua `NativeAdControllerDelegate.didReceive(_ miniAppEvent:)`. Nếu muốn nhận ở một chỗ duy nhất cho mọi vị trí ad, dùng `KalapaAds.miniAppListener`:

```swift
final class MiniAppTracker: MiniAppEventListener {
    func miniApp(didReceive event: MiniAppEvent) {
        switch event {
        case .opened(let adId, let sessionId): break
        case .openFailed(let adId, let error): print(error)   // xem docs/ERRORS.md
        case .closed(let adId, let sessionId, let reason, let result): break
        }
    }
}

// Giữ tham chiếu mạnh tới tracker; listener là weak.
KalapaAds.miniAppListener = tracker
```

`reason` cho biết mini-app đóng vì sao: `CALLBACK` (trang tự đóng), `CLOSE_BUTTON`, `BACK_AT_ROOT` (vuốt back ở trang đầu), `HOST_DISMISS`. `result` (`SUCCESS`, `FAILURE`, `CANCEL`, `CLOSE`) chỉ có khi `reason` là `CALLBACK`. Đây là điều trang báo lại, không phải xác nhận nghiệp vụ từ backend.

### Nút đóng của SDK (`showsCloseButton`)

Màn mini-app có thể hiện thêm nút × của SDK ở góc trên bên phải, đè lên trang web.

| Cách mở | Nút × của SDK | Đổi được không |
|---|---|---|
| User bấm ad (6.1) | **Không có** | Không |
| `KalapaAds.openMiniApp` (6.3) | **Có**, mặc định `showsCloseButton: true` | Có: truyền `showsCloseButton: false` để tắt |

Không có nút × thì user vẫn đóng mini-app được bằng:
- nút đóng hoặc nút hoàn tất của chính trang (trang gọi callback, `reason = CALLBACK`);
- vuốt từ mép trái màn hình khi đang ở trang đầu tiên (`reason = BACK_AT_ROOT`). Ở các trang sau, vuốt từ mép trái là quay lại trang trước.

Mini-app không đóng được bằng cách vuốt xuống.

Nếu trang đã có nút đóng riêng ở góc trên bên phải (ví dụ trang MoneyIQ), hãy truyền `showsCloseButton: false`, nếu không hai nút sẽ đè lên nhau.

### 6.3 Mở mini-app không qua ad (ví dụ từ thông báo)

```swift
KalapaAds.openMiniApp(url: nil, from: nil, showsCloseButton: true) { outcome in
    switch outcome {
    case .failed(let error):
        print(error)                              // xem docs/ERRORS.md, mục 2.3
    case .closed(let reason, let pageResult):
        print(reason, pageResult as Any)
    }
}
```

| Tham số | Ý nghĩa |
|---|---|
| `url` | Trang cần mở. `nil` thì mở `KalapaAdsConfig.miniAppURL` |
| `from` | View controller dùng để present. `nil` thì SDK tự tìm màn hình trên cùng |
| `showsCloseButton` | Mặc định `true`: hiện nút × của SDK ở góc trên bên phải. Truyền `false` nếu trang đã có nút đóng riêng ở vị trí đó. Xem [Nút đóng của SDK](#nút-đóng-của-sdk-showsclosebutton) |
| `completion` | Gọi đúng một lần trên main thread: `.failed` nếu không mở được, `.closed` sau khi màn hình đã đóng |

**Giới hạn host:** host của `url` phải trùng host của `miniAppURL`, hoặc nằm trong `miniAppAllowedHosts`. Nếu không, SDK trả `MINIAPP_INVALID_URL` và không mở. Quy định này để dữ liệu cá nhân trong config (số CCCD, số điện thoại…) không bị gửi sang trang lạ.

Luồng này không gửi event về `miniAppListener`, cũng không gửi về backend quảng cáo.

### 6.4 Mở mini-app khi user bấm thông báo

Đặt delegate của `UNUserNotificationCenter` **ngay trong `didFinishLaunching`**. Nếu đặt muộn hơn, app sẽ không nhận được lượt bấm khi thông báo làm app khởi động từ trạng thái đã tắt.

```swift
import KalapaAdsSDK
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        KalapaAds.initialize(config: KalapaAdsConfig(miniAppURL: URL(string: "https://moneyiq.vn/mini-app")))
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        // "mini_app_url" là khóa do app tự đặt trong payload thông báo; không có thì mở miniAppURL.
        let url = (response.notification.request.content.userInfo["mini_app_url"] as? String)
            .flatMap(URL.init(string:))
        Task { @MainActor in
            KalapaAds.openMiniApp(url: url, from: nil) { outcome in
                if case .failed(let error) = outcome { print(error) }
            }
            completionHandler()
        }
    }
}
```

Truyền `from: nil` để SDK tự present mini-app lên màn hình đang được đưa lên foreground. Cách này chạy được cả khi app đang mở, đang ở background, hoặc vừa khởi động từ thông báo.

---

## 7. Log và lỗi

Mọi lỗi đều là `KLPAdError`, với `code` (ví dụ `NO_VALID_CREATIVE`), `field`, `httpStatus` và `rejections`. Danh sách mã lỗi và cách xử lý: [docs/ERRORS.md](docs/ERRORS.md).

`logHandler` nhận mọi log của SDK trên main thread:

```swift
logHandler: { level, action, screenId, data, metadata in
    // level: KLPAdLogLevel (verbose, debug, info, warning, error)
    // action: "AD_LOAD_FAILED", "MINIAPP_OPEN_FAILED", …
    // screenId: "NATIVE_AD" hoặc "MINI_APP"
}
```

Log từ mức `INFO` trở lên được gửi về hệ thống log của Kalapa (`sdk-log.kalapa.vn`), giống eKYC và FaceOTP SDK. Log không chứa số CCCD, họ tên, số điện thoại, số tiền hay URL mini-app đầy đủ.

---

## 8. Banner và interstitial (định dạng cũ)

Đây là quảng cáo HTML chuyển sang từ KalapaScoreSDK. Hai định dạng này không cần gọi `KalapaAds.initialize`.

**Banner:**

```swift
let bannerView = KLPBannerView(adSize: .banner)       // 320×50; có .largeBanner, .mediumRectangle,
bannerView.adUnitID = "<ad unit id>"                  // .adaptiveBanner(for: width)…
bannerView.rootViewController = self
bannerView.delegate = self                            // KLPBannerViewDelegate
view.addSubview(bannerView)
bannerView.load(KLPRequest())
```

**Interstitial:**

```swift
KLPInterstitialAd.load(with: "<ad unit id>", request: KLPRequest(), adType: "interstitial") { result in
    switch result {
    case .success(let ad):
        ad.fullScreenContentDelegate = self           // KLPFullScreenContentDelegate
        ad.present(fromRootViewController: self)
    case .failure(let error):
        print(error)
    }
}
```

`adType` là `"interstitial"` (toàn màn hình) hoặc `"overlay"` (popup).

---

## 9. Checklist trước khi release

- [ ] Gọi `KalapaAds.initialize` một lần trong `didFinishLaunching`.
- [ ] `miniAppURL` trỏ tới URL production, không phải UAT.
- [ ] `NativeAdView` có kích thước ít nhất bằng template (320×80 hoặc 320×250).
- [ ] Ẩn slot khi nhận `.noFill`, `.failed` hoặc `didRequestClose`.
- [ ] Giữ `NativeAdController` theo vị trí đặt ad, không theo view hay cell. Gọi `dispose()` khi bỏ vị trí ad.
- [ ] Nếu mở mini-app từ thông báo: đặt delegate thông báo trong `didFinishLaunching`. Đã test cả lúc app đang mở, ở background và đã bị tắt.

## 10. Phiên bản

| Version | Ngày | Thay đổi |
|---|---|---|
| 0.1.0 | 02/11/2026 | Bản đầu tiên: native ad (UIKit, SwiftUI), mini-app, `openMiniApp`, log lỗi, banner và interstitial |
