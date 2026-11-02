//
//  DemoSettings.swift
//  KalapaAdsDemo
//
//  Created by thachlh on 26/10/26.
//

import Foundation
import KalapaAdsSDK

/// What the tester types on the Settings screen, kept on the device.
/// An empty mini-app field means "not provided": the SDK leaves it out of the URL.
struct DemoSettings {
    /// Native ad units. The Native screen's placements use them in turn, so ad units serving different
    /// templates show side by side; the SwiftUI screen uses the first.
    var nativeAdUnitIds: [String]
    var userId: String?
    var fullName: String?
    var phoneNumber: String?
    var amount: String?
    var period: String?
    /// What `KalapaAds.openMiniApp` opens without a URL. UAT, so tests never create a real lead.
    var miniAppURL: String?

    var adsConfig: KalapaAdsConfig {
        KalapaAdsConfig(
            userId: userId,
            fullName: fullName,
            phoneNumber: phoneNumber,
            amount: amount,
            period: period,
            miniAppURL: miniAppURL.flatMap(URL.init(string:)),
            logHandler: { level, action, screenId, data, _ in
                print("[KalapaAds] \(level.stringValue) \(action) @\(screenId) \(data)")
            }
        )
    }

    private static let defaults = DemoSettings(
        nativeAdUnitIds: [
            "be9abee4-ed55-4557-b9d4-a70ecbc1c6de", // promo and product cards
            "b1a8a5f3-8cb0-4463-a69b-366ce610b255", // strips
        ],
        userId: "001094018640",
        fullName: "Someone",
        phoneNumber: "0965234589",
        amount: "50000000",
        period: "12",
        miniAppURL: "https://uat.moneyiq.vn/mini-app"
    )

    private enum Key {
        static let nativeAdUnitIds = "demo.adUnitIds"
        static let userId = "demo.userId"
        static let fullName = "demo.fullName"
        static let phoneNumber = "demo.phoneNumber"
        static let amount = "demo.amount"
        static let period = "demo.period"
        static let miniAppURL = "demo.miniAppURL"
    }

    /// Ad unit ids typed as a list, separated by commas, spaces or new lines.
    static func adUnitIds(from text: String) -> [String] {
        text.split { $0 == "," || $0.isWhitespace }.map(String.init)
    }

    static var current: DemoSettings {
        get {
            let store = UserDefaults.standard
            // A missing key falls back to the default; a stored empty string stays "not provided".
            func value(_ key: String, _ fallback: String?) -> String? {
                let stored = store.string(forKey: key) ?? fallback ?? ""
                return stored.isEmpty ? nil : stored
            }
            return DemoSettings(
                nativeAdUnitIds: value(Key.nativeAdUnitIds, nil).map(adUnitIds).flatMap { $0.isEmpty ? nil : $0 } ?? defaults.nativeAdUnitIds,
                userId: value(Key.userId, defaults.userId),
                fullName: value(Key.fullName, defaults.fullName),
                phoneNumber: value(Key.phoneNumber, defaults.phoneNumber),
                amount: value(Key.amount, defaults.amount),
                period: value(Key.period, defaults.period),
                miniAppURL: value(Key.miniAppURL, defaults.miniAppURL)
            )
        }
        set {
            let store = UserDefaults.standard
            store.set(newValue.nativeAdUnitIds.joined(separator: ", "), forKey: Key.nativeAdUnitIds)
            store.set(newValue.userId ?? "", forKey: Key.userId)
            store.set(newValue.fullName ?? "", forKey: Key.fullName)
            store.set(newValue.phoneNumber ?? "", forKey: Key.phoneNumber)
            store.set(newValue.amount ?? "", forKey: Key.amount)
            store.set(newValue.period ?? "", forKey: Key.period)
            store.set(newValue.miniAppURL ?? "", forKey: Key.miniAppURL)
        }
    }
}
