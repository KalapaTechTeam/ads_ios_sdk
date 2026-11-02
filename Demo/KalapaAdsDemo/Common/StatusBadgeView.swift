//
//  StatusBadgeView.swift
//  KalapaAdsDemo
//
//  Created by thachlh on 13/10/26.
//

import UIKit

final class StatusBadgeView: UIView {
    @IBOutlet private weak var textLabel: UILabel!

    func show(_ text: String, tone: DemoTone) {
        textLabel.text = text
        textLabel.textColor = tone.color
        backgroundColor = tone.color.withAlphaComponent(0.12)
    }
}
