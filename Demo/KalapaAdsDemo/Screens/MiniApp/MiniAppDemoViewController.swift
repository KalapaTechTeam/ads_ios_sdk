//
//  MiniAppDemoViewController.swift
//  KalapaAdsDemo
//
//  Created by thachlh on 29/10/26.
//

import KalapaAdsSDK
import UIKit

/// `KalapaAds.openMiniApp` with no ad on screen, as an app would call it after a notification tap.
final class MiniAppDemoViewController: UIViewController {

    private static let notAllowedURL = "https://example.com/mini-app"

    private let stack = UIStackView()
    private let urlField = UITextField()
    private let closeButtonSwitch = UISwitch()
    private let logTextView = UITextView()
    private var log: EventLog!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Mở mini-app trực tiếp"
        view.backgroundColor = UIColor(named: "Background")
        layout()
        log = EventLog(textView: logTextView)
        log.add("ready", "URL mặc định: \(DemoSettings.current.miniAppURL ?? "chưa cấu hình")")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DemoNotifications.shared.onLog = { [weak self] tag, message, tone in
            self?.log.add(tag, message, tone: tone)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // The mini-app covers this screen without removing it: keep logging here while it is open.
        if isMovingFromParent {
            DemoNotifications.shared.onLog = nil
        }
    }

    private func layout() {
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        urlField.text = "https://uat.moneyiq.vn/mini-app?creative_id=P5-C&persona_id=P5"
        urlField.borderStyle = .roundedRect
        urlField.font = .systemFont(ofSize: 14, weight: .medium)
        urlField.keyboardType = .URL
        urlField.autocapitalizationType = .none
        urlField.autocorrectionType = .no
        urlField.clearButtonMode = .whileEditing

        closeButtonSwitch.isOn = true
        let switchRow = UIStackView(arrangedSubviews: [makeLabel("Nút Đóng của SDK", size: 14, weight: .medium), closeButtonSwitch])
        switchRow.alignment = .center

        stack.addArrangedSubview(makeLabel("URL", size: 13, weight: .medium))
        stack.addArrangedSubview(urlField)
        stack.addArrangedSubview(switchRow)
        stack.addArrangedSubview(makeButton("Mở URL mặc định", action: #selector(didTapDefault)))
        stack.addArrangedSubview(makeButton("Mở URL đã nhập", action: #selector(didTapGivenURL)))
        stack.addArrangedSubview(makeButton("Mở URL không được phép", action: #selector(didTapNotAllowed)))
        stack.addArrangedSubview(makeButton("Gửi thông báo mở URL đã nhập (sau 5 giây)", action: #selector(didTapNotify)))
        let notifyNote = makeLabel("Gửi xong, có thể ở lại app, về màn hình chính hoặc vuốt tắt app rồi bấm thông báo. Ô URL để trống thì mở URL mặc định.", size: 12, weight: .regular)
        notifyNote.numberOfLines = 0
        notifyNote.textColor = UIColor(named: "TextSecondary")
        stack.addArrangedSubview(notifyNote)

        logTextView.isEditable = false
        logTextView.backgroundColor = UIColor(named: "Card")
        logTextView.layer.cornerRadius = 12
        logTextView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logTextView)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            logTextView.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 16),
            logTextView.leadingAnchor.constraint(equalTo: stack.leadingAnchor),
            logTextView.trailingAnchor.constraint(equalTo: stack.trailingAnchor),
            logTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])
    }

    private func makeLabel(_ text: String, size: CGFloat, weight: UIFont.Weight) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: size, weight: weight)
        label.textColor = UIColor(named: "TextPrimary")
        return label
    }

    private func makeButton(_ title: String, action: Selector) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.baseBackgroundColor = UIColor(named: "Primary")
        configuration.cornerStyle = .large
        let button = UIButton(configuration: configuration)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc private func didTapDefault() {
        open(nil)
    }

    @objc private func didTapGivenURL() {
        let text = urlField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard let url = URL(string: text), !text.isEmpty else {
            log.add("invalid", "Không đọc được URL đã nhập", tone: .failure)
            return
        }
        open(url)
    }

    @objc private func didTapNotAllowed() {
        open(URL(string: Self.notAllowedURL))
    }

    @objc private func didTapNotify() {
        view.endEditing(true)
        let text = urlField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let url = text.isEmpty ? nil : URL(string: text)
        if !text.isEmpty, url == nil {
            log.add("invalid", "Không đọc được URL đã nhập", tone: .failure)
            return
        }
        DemoNotifications.shared.schedule(url: url, showsCloseButton: closeButtonSwitch.isOn, after: 5) { [weak self] error in
            if let error = error {
                self?.log.add("notification", error, tone: .failure)
            } else {
                self?.log.add("notification", "Thông báo sẽ đến sau 5 giây", tone: .progress)
            }
        }
    }

    private func open(_ url: URL?) {
        view.endEditing(true)
        log.add("open", url?.absoluteString ?? "URL mặc định", tone: .progress)
        KalapaAds.openMiniApp(url: url, from: self, showsCloseButton: closeButtonSwitch.isOn) { [weak self] outcome in
            self?.show(outcome)
        }
    }

    private func show(_ outcome: MiniAppOutcome) {
        switch outcome {
        case .failed(let error):
            log.add("failed", "\(error)", tone: .failure)
        case .closed(let reason, let pageResult?):
            log.add("closed", "\(reason.rawValue) · trang báo \(pageResult.rawValue)", tone: .success)
        case .closed(let reason, nil):
            log.add("closed", "\(reason.rawValue) · trang không báo kết quả", tone: .warning)
        }
    }
}
