//
//  BannerDemoViewController.swift
//  KalapaAdsDemo
//
//  Created by thachlh on 13/10/26.
//

import UIKit
import KalapaAdsSDK

final class BannerDemoViewController: UIViewController {

    @IBOutlet private weak var adUnitLabel: UILabel!
    @IBOutlet private weak var slotView: UIView!
    @IBOutlet private weak var statusBadge: StatusBadgeView!
    @IBOutlet private weak var logTextView: UITextView!

    private let adUnitId = "3ecf1b20-0700-4008-a824-b53a836c6a57"
    private let bannerView = KLPBannerView(adSize: .banner)
    private var log: EventLog!
    private static let slotPadding: CGFloat = 16

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Banner"
        adUnitLabel.text = adUnitId
        log = EventLog(textView: logTextView)

        bannerView.translatesAutoresizingMaskIntoConstraints = false
        slotView.addSubview(bannerView)
        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: slotView.centerXAnchor),
            bannerView.topAnchor.constraint(equalTo: slotView.topAnchor, constant: Self.slotPadding),
            bannerView.bottomAnchor.constraint(equalTo: slotView.bottomAnchor, constant: -Self.slotPadding),
        ])
        bannerView.delegate = self
        bannerView.rootViewController = self
        bannerView.adUnitID = adUnitId
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !bannerView.isAdLoaded {
            load()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.bannerView.adSize = BannerSize.adaptiveBanner(for: self.bannerWidth)
        })
    }

    private var bannerWidth: CGFloat {
        slotView.bounds.width - 2 * Self.slotPadding
    }

    private func load() {
        bannerView.adSize = BannerSize.adaptiveBanner(for: bannerWidth)
        statusBadge.show("Đang tải…", tone: .progress)
        log.add("load", "banner", tone: .progress)
        bannerView.load(KLPRequest())
    }

    @IBAction private func didTapReload() {
        load()
    }

    @IBAction private func didTapClearLog() {
        log.clear()
    }
}

extension BannerDemoViewController: KLPBannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: KLPBannerView) {
        statusBadge.show("Đã tải", tone: .success)
        log.add("loaded", "ad \(bannerView.currentAdItemId.shortId)", tone: .success)
    }

    func bannerView(_ bannerView: KLPBannerView, didFailToReceiveAdWithError error: Error) {
        statusBadge.show("Lỗi", tone: .failure)
        log.add("failed", error.localizedDescription, tone: .failure)
    }

    func bannerViewDidRecordImpression(_ bannerView: KLPBannerView) {
        log.add("impression", "ad \(bannerView.currentAdItemId.shortId)", tone: .success)
    }

    func bannerViewDidRecordClick(_ bannerView: KLPBannerView) {
        log.add("click", "Mở link ngoài bằng Safari", tone: .progress)
    }
}
