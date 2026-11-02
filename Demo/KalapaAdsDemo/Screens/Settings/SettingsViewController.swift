//
//  SettingsViewController.swift
//  KalapaAdsDemo
//
//  Created by thachlh on 26/10/26.
//

import UIKit

/// The native ad unit and the SDK config the demo uses, kept on the device (`DemoSettings`).
final class SettingsViewController: UIViewController {

    private enum Field: CaseIterable {
        case adUnit, userId, fullName, phoneNumber, amount, period, miniAppURL
    }

    private let stack = UIStackView()
    private var fields: [Field: UITextField] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Cài đặt"
        view.backgroundColor = UIColor(named: "Background")
        layoutForm()
        buildForm()
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }

    private func layoutForm() {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive
        stack.axis = .vertical
        stack.spacing = 12
        for subview in [scrollView, stack] {
            subview.translatesAutoresizingMaskIntoConstraints = false
        }
        view.addSubview(scrollView)
        scrollView.addSubview(stack)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: stack.trailingAnchor, constant: 20),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: stack.bottomAnchor, constant: 20),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),
        ])
    }

    private func buildForm() {
        let settings = DemoSettings.current
        addSection("AD UNIT")
        addField(.adUnit, caption: "Ad unit native, cách nhau bằng dấu phẩy", text: settings.nativeAdUnitIds.joined(separator: ", "), keyboard: .asciiCapable)
        let adUnitNote = makeLabel("Các vị trí ở màn Native lần lượt dùng từng ad unit, nên ad unit trả strip và ad unit trả card hiện cùng lúc. Màn SwiftUI dùng ad unit đầu tiên.", size: 12, weight: .regular)
        adUnitNote.numberOfLines = 0
        stack.addArrangedSubview(adUnitNote)
        addSection("SDK CONFIG · THAM SỐ MINI-APP")
        addField(.userId, caption: "user_id (id_card_number)", text: settings.userId, keyboard: .numberPad)
        addField(.fullName, caption: "full_name", text: settings.fullName, keyboard: .default)
        addField(.phoneNumber, caption: "phone_number", text: settings.phoneNumber, keyboard: .phonePad)
        addField(.amount, caption: "amount", text: settings.amount, keyboard: .numberPad)
        addField(.period, caption: "period (số nguyên dương, vd. 12)", text: settings.period, keyboard: .numberPad)
        let note = makeLabel("Để trống trường nào thì SDK không truyền trường đó. full_name có ký tự !@#$%^*( hoặc period không phải số nguyên dương cũng bị bỏ. SDK đọc các thông tin này một lần khi app khởi động (KalapaAds.initialize): tắt hẳn app rồi mở lại để áp dụng.", size: 12, weight: .regular)
        note.numberOfLines = 0
        stack.addArrangedSubview(note)
        addSection("MỞ MINI-APP TRỰC TIẾP")
        addField(.miniAppURL, caption: "URL mặc định (miniAppURL)", text: settings.miniAppURL, keyboard: .URL)
        let urlNote = makeLabel("openMiniApp() không truyền URL thì mở URL này. Chỉ host của URL này được nhận tham số người dùng. Tắt hẳn app rồi mở lại để áp dụng.", size: 12, weight: .regular)
        urlNote.numberOfLines = 0
        stack.addArrangedSubview(urlNote)
    }

    private func addSection(_ title: String) {
        let label = makeLabel(title, size: 12, weight: .semibold)
        stack.addArrangedSubview(label)
        if let previous = stack.arrangedSubviews.dropLast().last {
            stack.setCustomSpacing(24, after: previous)
        }
    }

    private func addField(_ field: Field, caption: String, text: String?, keyboard: UIKeyboardType) {
        let textField = UITextField()
        textField.text = text
        textField.borderStyle = .roundedRect
        textField.font = .systemFont(ofSize: 14, weight: .medium)
        textField.keyboardType = keyboard
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .done
        textField.delegate = self
        fields[field] = textField

        let row = UIStackView(arrangedSubviews: [makeLabel(caption, size: 13, weight: .medium), textField])
        row.axis = .vertical
        row.spacing = 4
        stack.addArrangedSubview(row)
    }

    private func makeLabel(_ text: String, size: CGFloat, weight: UIFont.Weight) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: size, weight: weight)
        label.textColor = UIColor(named: "TextSecondary")
        return label
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func save() {
        func value(_ field: Field) -> String? {
            let text = fields[field]?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return text.isEmpty ? nil : text
        }
        var settings = DemoSettings.current
        let adUnitIds = DemoSettings.adUnitIds(from: value(.adUnit) ?? "")
        if !adUnitIds.isEmpty {
            settings.nativeAdUnitIds = adUnitIds
        }
        settings.userId = value(.userId)
        settings.fullName = value(.fullName)
        settings.phoneNumber = value(.phoneNumber)
        settings.amount = value(.amount)
        settings.period = value(.period)
        settings.miniAppURL = value(.miniAppURL)
        DemoSettings.current = settings
        fields[.adUnit]?.text = settings.nativeAdUnitIds.joined(separator: ", ")
    }
}

extension SettingsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        save()
    }
}
