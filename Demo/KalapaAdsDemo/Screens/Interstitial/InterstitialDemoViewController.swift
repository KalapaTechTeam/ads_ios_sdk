//
//  InterstitialDemoViewController.swift
//  KalapaAdsDemo
//
//  Created by thachlh on 13/10/26.
//

import UIKit
import KalapaAdsSDK

final class InterstitialDemoViewController: UIViewController {

    @IBOutlet private weak var adUnitLabel: UILabel!
    @IBOutlet private weak var adTypeControl: UISegmentedControl!
    @IBOutlet private weak var statusBadge: StatusBadgeView!
    @IBOutlet private weak var logTextView: UITextView!

    private let adUnitId = "3ecf1b20-0700-4008-a824-b53a836c6a57"
    private var interstitialAd: KLPInterstitialAd?
    private var log: EventLog!

    private var adType: String {
        adTypeControl.titleForSegment(at: adTypeControl.selectedSegmentIndex) ?? "overlay"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Interstitial"
        adUnitLabel.text = adUnitId
        log = EventLog(textView: logTextView)
        load()
    }

    private func load() {
        let adType = adType
        interstitialAd = nil
        statusBadge.show("Đang tải…", tone: .progress)
        log.add("load", adType, tone: .progress)

        KLPInterstitialAd.load(with: adUnitId, request: KLPRequest(), adType: adType) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let ad):
                    ad.fullScreenContentDelegate = self
                    self.interstitialAd = ad
                    self.statusBadge.show("Sẵn sàng", tone: .success)
                    self.log.add("loaded", adType, tone: .success)
                case .failure(let error):
                    self.statusBadge.show("Lỗi", tone: .failure)
                    self.log.add("failed", error.localizedDescription, tone: .failure)
                }
            }
        }
    }

    @IBAction private func didChangeAdType() {
        load()
    }

    @IBAction private func didTapShow() {
        guard let interstitialAd = interstitialAd else {
            log.add("show", "Quảng cáo chưa sẵn sàng", tone: .warning)
            return
        }
        interstitialAd.present(fromRootViewController: self)
    }

    @IBAction private func didTapReload() {
        load()
    }

    @IBAction private func didTapClearLog() {
        log.clear()
    }
}

extension InterstitialDemoViewController: KLPFullScreenContentDelegate {
    func adDidRecordImpression(_ ad: KLPInterstitialAd) {
        log.add("impression", adType, tone: .success)
    }

    func adDidRecordClick(_ ad: KLPInterstitialAd) {
        log.add("click", "Mở link ngoài bằng Safari", tone: .progress)
    }

    func ad(_ ad: KLPInterstitialAd, didFailToPresentFullScreenContentWithError error: Error) {
        log.add("failed", error.localizedDescription, tone: .failure)
    }

    func adDidDismissFullScreenContent(_ ad: KLPInterstitialAd) {
        log.add("dismiss", "Interstitial chỉ hiện một lần, tải cái mới")
        load()
    }
}
