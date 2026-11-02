//
//  HomeViewController.swift
//  KalapaAdsDemo
//
//  Created by thachlh on 13/10/26.
//

import KalapaAdsSDK
import SwiftUI
import UIKit

final class HomeViewController: UIViewController {

    @IBOutlet private weak var versionLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        versionLabel.text = "KalapaAdsSDK \(KalapaAds.sdkVersion)"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    @IBAction private func didTapSettings() {
        navigationController?.pushViewController(SettingsViewController(), animated: true)
    }

    @IBAction private func didTapNative() {
        navigationController?.pushViewController(NativeDemoViewController(), animated: true)
    }

    @IBAction private func didTapSwiftUI() {
        navigationController?.pushViewController(UIHostingController(rootView: SwiftUIDemoView()), animated: true)
    }

    @IBAction private func didTapBanner() {
        navigationController?.pushViewController(BannerDemoViewController(), animated: true)
    }

    @IBAction private func didTapInterstitial() {
        navigationController?.pushViewController(InterstitialDemoViewController(), animated: true)
    }

    @IBAction private func didTapMiniApp() {
        navigationController?.pushViewController(MiniAppDemoViewController(), animated: true)
    }
}

