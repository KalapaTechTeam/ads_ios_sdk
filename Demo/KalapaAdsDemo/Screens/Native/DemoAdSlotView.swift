//
//  DemoAdSlotView.swift
//  KalapaAdsDemo
//
//  Created by thachlh on 26/10/26.
//

import UIKit
import KalapaAdsSDK

/// One ad placement on the Native demo: a card with its own status and a `NativeAdView`
/// at least 320 wide, 16 in from each side.
final class DemoAdSlotView: UIView {

    /// Ad height while loading: the tallest template the SDK supports, so any of them fits
    /// (strip 320×80, cards 320×250); the slot then takes the loaded ad's height.
    static var loadingAdHeight: CGFloat {
        CGFloat(NativeAdTemplate.Kind.allCases.map(\.designSize.height).max() ?? 0)
    }

    let adView = NativeAdView()
    let adUnitId: String
    private let titleLabel = UILabel()
    private let statusLabel = UILabel()
    private var adHeightConstraint: NSLayoutConstraint!

    init(number: Int, adUnitId: String) {
        self.adUnitId = adUnitId
        super.init(frame: .zero)
        backgroundColor = UIColor(named: "Card")
        layer.cornerRadius = 16

        titleLabel.text = "Vị trí \(number) · \(adUnitId.prefix(8))"
        titleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textColor = UIColor(named: "TextSecondary")
        statusLabel.font = .systemFont(ofSize: 12, weight: .medium)
        statusLabel.textAlignment = .right

        for subview in [titleLabel, statusLabel, adView] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            addSubview(subview)
        }
        adHeightConstraint = adView.heightAnchor.constraint(equalToConstant: Self.loadingAdHeight)
        let fillWidth = adView.widthAnchor.constraint(equalTo: widthAnchor, constant: -32)
        fillWidth.priority = .defaultHigh
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            statusLabel.firstBaselineAnchor.constraint(equalTo: titleLabel.firstBaselineAnchor),
            statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8),
            trailingAnchor.constraint(equalTo: statusLabel.trailingAnchor, constant: 16),
            adView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            adView.centerXAnchor.constraint(equalTo: centerXAnchor),
            adView.widthAnchor.constraint(greaterThanOrEqualToConstant: 320),
            fillWidth,
            adHeightConstraint,
            bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: 16),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setAdHeight(_ height: CGFloat) {
        adHeightConstraint.constant = height
    }

    /// Hidden ads count as not visible, so no impression is recorded until they show.
    func setAdHidden(_ hidden: Bool) {
        adView.alpha = hidden ? 0 : 1
    }

    func showStatus(_ text: String, tone: DemoTone) {
        statusLabel.text = text
        statusLabel.textColor = tone.color
    }
}
