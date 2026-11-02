//
//  EventLog.swift
//  KalapaAdsDemo
//
//  Created by thachlh on 13/10/26.
//

import UIKit

/// Newest-first event list rendered into a text view.
final class EventLog {

    private weak var textView: UITextView?
    private let content = NSMutableAttributedString()
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    init(textView: UITextView) {
        self.textView = textView
        textView.text = nil
    }

    func add(_ tag: String, _ message: String, tone: DemoTone = .neutral) {
        let line = NSMutableAttributedString()
        line.append(NSAttributedString(string: timeFormatter.string(from: Date()) + "  ", attributes: [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular),
            .foregroundColor: DemoTone.neutral.color,
        ]))
        line.append(NSAttributedString(string: tag.uppercased(), attributes: [
            .font: UIFont.systemFont(ofSize: 11, weight: .bold),
            .foregroundColor: tone.color,
        ]))
        line.append(NSAttributedString(string: "  " + message + "\n", attributes: [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor(named: "TextPrimary") ?? .label,
        ]))
        content.insert(line, at: 0)
        textView?.attributedText = content
        print("[\(tag)] \(message)")
    }

    func clear() {
        content.setAttributedString(NSAttributedString())
        textView?.attributedText = content
    }
}
