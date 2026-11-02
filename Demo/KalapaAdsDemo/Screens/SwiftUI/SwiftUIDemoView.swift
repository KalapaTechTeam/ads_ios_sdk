//
//  SwiftUIDemoView.swift
//  KalapaAdsDemo
//
//  Created by thachlh on 15/10/26.
//

import SwiftUI
import KalapaAdsSDK

/// A feed with a native ad in the middle, the way a SwiftUI host would embed it.
struct SwiftUIDemoView: View {

    @StateObject private var ad = NativeAdController(adUnitId: DemoSettings.current.nativeAdUnitIds[0])

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                FeedPlaceholder(title: "Tin tức hôm nay", lines: 3)
                FeedPlaceholder(title: "Lịch thanh toán", lines: 2)

                NativeAdSlot(controller: ad)
                    .frame(maxWidth: .infinity)
                    .animation(.easeInOut(duration: 0.25), value: ad.state)

                Text(Self.describe(ad.state))
                    .font(.footnote.weight(.medium))
                    .foregroundColor(Color("TextSecondary"))

                FeedPlaceholder(title: "Ưu đãi dành cho bạn", lines: 4)
                FeedPlaceholder(title: "Mẹo tài chính", lines: 3)
            }
            .padding(20)
        }
        .background(Color("Background").ignoresSafeArea())
        .navigationTitle("SwiftUI")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Tải lại") { ad.load() }
        }
        .onAppear {
            if ad.state == .idle {
                ad.load()
            }
        }
    }

    private static func describe(_ state: NativeAdController.State) -> String {
        switch state {
        case .idle: return "Chưa tải"
        case .loading: return "Đang tải… (ô quảng cáo thu gọn)"
        case .ready(let ad): return "Đã tải \(ad.template.kind.rawValue) · \(Int(ad.size.width))×\(Int(ad.size.height))"
        case .noFill: return "Không có quảng cáo · ô thu gọn"
        case .failed(let error): return "Lỗi \(error.code.rawValue) · ô thu gọn"
        case .hidden: return "User đã đóng · ô thu gọn"
        case .disposed: return "Đã huỷ"
        }
    }
}
