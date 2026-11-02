//
//  DemoNotifications.swift
//  KalapaAdsDemo
//
//  Created by thachlh on 29/10/26.
//

import KalapaAdsSDK
import UIKit
import UserNotifications

/// Sends a local notification that opens a mini-app when tapped, so the notification flow can be tried
/// with the app open, in the background or killed. Installed at launch: a tap that launches the app is
/// delivered before any screen exists.
@MainActor
final class DemoNotifications: NSObject {

    static let shared = DemoNotifications()

    private enum Key {
        static let url = "mini_app_url"
        static let showsCloseButton = "shows_close_button"
    }

    /// The Mini-app screen's log while it is on screen; otherwise outcomes show as an alert.
    var onLog: ((String, String, DemoTone) -> Void)?

    func install() {
        UNUserNotificationCenter.current().delegate = self
    }

    /// `url` `nil` opens `KalapaAdsConfig.miniAppURL`.
    func schedule(url: URL?, showsCloseButton: Bool, after delay: TimeInterval, completion: @escaping (String?) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else {
                DispatchQueue.main.async { completion("Chưa cho phép thông báo: bật trong Cài đặt > KalapaAdsDemo") }
                return
            }
            let content = UNMutableNotificationContent()
            content.title = "Kalapa Ads"
            content.body = "Bấm để mở mini-app"
            content.sound = .default
            content.userInfo = [Key.url: url?.absoluteString ?? "", Key.showsCloseButton: showsCloseButton]
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            )
            center.add(request) { error in
                DispatchQueue.main.async { completion(error?.localizedDescription) }
            }
        }
    }

    private func open(_ userInfo: [AnyHashable: Any]) {
        let url = (userInfo[Key.url] as? String).flatMap { $0.isEmpty ? nil : URL(string: $0) }
        let showsCloseButton = userInfo[Key.showsCloseButton] as? Bool ?? true
        report("notification", "Bấm thông báo, mở \(url?.absoluteString ?? "URL mặc định")", .progress)
        // `from: nil`: the SDK finds the screen itself, which is what a cold launch tests.
        KalapaAds.openMiniApp(url: url, from: nil, showsCloseButton: showsCloseButton) { [weak self] outcome in
            switch outcome {
            case .failed(let error):
                self?.report("failed", "\(error)", .failure)
            case .closed(let reason, let pageResult):
                self?.report("closed", "\(reason.rawValue) · \(pageResult?.rawValue ?? "trang không báo kết quả")", .success)
            }
        }
    }

    private func report(_ tag: String, _ message: String, _ tone: DemoTone) {
        if let onLog = onLog {
            onLog(tag, message, tone)
            return
        }
        guard tone == .failure || tone == .success else { return }
        let alert = UIAlertController(title: "Mini-app từ thông báo: \(tag)", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        Self.topmost?.present(alert, animated: true)
    }

    private static var topmost: UIViewController? {
        var top = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}

extension DemoNotifications: UNUserNotificationCenterDelegate {
    /// Shows the banner while the app is open too.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        Task { @MainActor in
            self.open(userInfo)
            completionHandler()
        }
    }
}
