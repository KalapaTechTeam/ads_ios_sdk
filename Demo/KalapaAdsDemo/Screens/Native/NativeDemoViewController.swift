//
//  NativeDemoViewController.swift
//  KalapaAdsDemo
//
//  Created by thachlh on 13/10/26.
//

import UIKit
import KalapaAdsSDK

final class NativeDemoViewController: UIViewController {

    @IBOutlet private weak var adUnitLabel: UILabel!
    @IBOutlet private weak var slotsStack: UIStackView!
    @IBOutlet private weak var statusBadge: StatusBadgeView!
    @IBOutlet private weak var logTextView: UITextView!

    private static let placementCounts = [1, 2, 3]

    /// Ad unit and mini-app fields typed on the Home screen.
    private let settings = DemoSettings.current
    private var placementCount = 3
    /// One placement per slot, each with its own controller and its own request.
    private var slots: [DemoAdSlotView] = []
    private var controllers: [NativeAdController] = []
    /// Slots load one after another.
    private var loadQueue: [NativeAdController] = []
    /// Each slot's height once its load settles, applied to every slot at once so the page moves only once.
    private var settledHeights: [Int: CGFloat] = [:]
    private var log: EventLog!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Native Ads"
        adUnitLabel.numberOfLines = 0
        adUnitLabel.text = settings.nativeAdUnitIds.joined(separator: "\n")
        addPlacementCountControl()
        log = EventLog(textView: logTextView)
        makePlacements()
        reload()
    }

    deinit {
        let controllers = controllers
        Task { @MainActor in controllers.forEach { $0.dispose() } }
    }

    private func addPlacementCountControl() {
        let control = UISegmentedControl(items: Self.placementCounts.map { "\($0) vị trí" })
        control.selectedSegmentIndex = Self.placementCounts.firstIndex(of: placementCount) ?? 0
        control.addTarget(self, action: #selector(didChangePlacementCount(_:)), for: .valueChanged)
        insertAboveSlots(control)
    }

    private func insertAboveSlots(_ view: UIView) {
        guard let content = slotsStack.superview as? UIStackView,
              let index = content.arrangedSubviews.firstIndex(of: slotsStack) else { return }
        content.insertArrangedSubview(view, at: index)
    }

    @objc private func didChangePlacementCount(_ control: UISegmentedControl) {
        placementCount = Self.placementCounts[control.selectedSegmentIndex]
        makePlacements()
        reload()
    }

    private func makePlacements() {
        controllers.forEach { $0.dispose() }
        slots.forEach { $0.removeFromSuperview() }
        // Placements take the ad units in turn, so units serving different templates show together.
        let adUnitIds = settings.nativeAdUnitIds
        slots = (1...placementCount).map { DemoAdSlotView(number: $0, adUnitId: adUnitIds[($0 - 1) % adUnitIds.count]) }
        controllers = slots.map { slot in
            slotsStack.addArrangedSubview(slot)
            let controller = NativeAdController(adUnitId: slot.adUnitId)
            controller.delegate = self
            slot.adView.controller = controller
            return controller
        }
    }

    private func reload() {
        settledHeights = [:]
        for slot in slots {
            slot.setAdHeight(DemoAdSlotView.loadingAdHeight)
            slot.setAdHidden(true)
            slot.showStatus("Đang tải…", tone: .progress)
        }
        // The loader reads each slot's size when `load` starts.
        view.layoutIfNeeded()
        statusBadge.show("Đang tải…", tone: .progress)
        log.add("load", "\(controllers.count) vị trí · count 5 mỗi vị trí", tone: .progress)
        loadQueue = controllers
        loadNext()
    }

    private func loadNext() {
        guard !loadQueue.isEmpty else { return }
        loadQueue.removeFirst().load()
    }

    /// Once every slot has its result: all heights in one animation, then the ads fade in.
    private func revealSlotsIfSettled() {
        guard loadQueue.isEmpty, !controllers.contains(where: { $0.state == .loading }) else { return }
        for (index, slot) in slots.enumerated() {
            slot.setAdHeight(settledHeights[index] ?? 0)
        }
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
            self.slots.forEach { $0.setAdHidden(false) }
        }
    }

    @IBAction private func didTapReload() {
        reload()
    }

    private func slot(for controller: NativeAdController) -> (number: Int, view: DemoAdSlotView)? {
        controllers.firstIndex { $0 === controller }.map { ($0 + 1, slots[$0]) }
    }

    private func updateSummary() {
        let loading = controllers.filter { $0.state == .loading }.count
        let loaded = controllers.filter { $0.ad != nil }.count
        guard loading == 0 else {
            statusBadge.show("Đang tải… \(controllers.count - loading)/\(controllers.count)", tone: .progress)
            return
        }
        let tone: DemoTone = loaded == controllers.count ? .success : (loaded == 0 ? .failure : .warning)
        statusBadge.show("Đã tải \(loaded)/\(controllers.count)", tone: tone)
    }

    @IBAction private func didTapClearLog() {
        log.clear()
    }
}

extension NativeDemoViewController: NativeAdControllerDelegate {
    func nativeAdController(_ controller: NativeAdController, didFinishLoading result: NativeAdLoadResult) {
        guard let (number, slot) = slot(for: controller) else { return }
        switch result {
        case .loaded(let ad):
            slot.showStatus(ad.template.kind.rawValue, tone: .success)
            settledHeights[number - 1] = CGFloat(ad.size.height)
            log.add("loaded", "#\(number) \(ad.template.kind.rawValue) · persona \(ad.personaId ?? "-") · ad \(ad.adId.shortId)", tone: .success)
        case .noFill:
            settledHeights[number - 1] = 0
            slot.showStatus("Không có quảng cáo", tone: .warning)
            log.add("no fill", "#\(number) Server không trả creative nào", tone: .warning)
        case .failed(let error):
            settledHeights[number - 1] = 0
            slot.showStatus(error.code.rawValue, tone: .failure)
            log.add("failed", "#\(number) \(error)", tone: .failure)
            error.rejections.forEach { log.add("rejected", "#\(number) creative \($0.index) \($0.adId?.shortId ?? "-"): \($0.error)", tone: .failure) }
        }
        updateSummary()
        loadNext()
        revealSlotsIfSettled()
    }

    func nativeAdController(_ controller: NativeAdController, didRecordImpression info: NativeAdEventInfo) {
        guard let (number, _) = slot(for: controller) else { return }
        log.add("impression", "#\(number) ad \(info.adId.shortId)", tone: .success)
    }

    func nativeAdController(_ controller: NativeAdController, didRecordViewableImpression info: NativeAdEventInfo) {
        guard let (number, _) = slot(for: controller) else { return }
        log.add("viewable", "#\(number) ≥50% trong 1 giây", tone: .success)
    }

    func nativeAdController(_ controller: NativeAdController, didClick info: NativeAdEventInfo) {
        guard let (number, _) = slot(for: controller) else { return }
        log.add("click", "#\(number) \(controller.ad?.targetURL.absoluteString ?? info.adId)", tone: .progress)
    }

    func nativeAdController(_ controller: NativeAdController, didRequestClose info: NativeAdEventInfo) {
        guard let (number, slot) = slot(for: controller) else { return }
        slot.showStatus("Đã đóng", tone: .neutral)
        log.add("close", "#\(number) User đóng quảng cáo", tone: .warning)
        updateSummary()
    }

    func nativeAdController(_ controller: NativeAdController, didRequestInfo info: NativeAdEventInfo) {
        guard let (number, _) = slot(for: controller) else { return }
        log.add("info", "#\(number) User bấm nhãn Quảng cáo")
    }

    func nativeAdController(_ controller: NativeAdController, didReceive miniAppEvent: MiniAppEvent) {
        guard let (number, _) = slot(for: controller) else { return }
        switch miniAppEvent {
        case .opened(_, let sessionId):
            log.add("mini-app", "#\(number) Đã mở · session \(sessionId.suffix(6))", tone: .progress)
        case .openFailed(_, let error):
            log.add("mini-app", "#\(number) Không mở được: \(error)", tone: .failure)
        case .closed(_, _, let reason, let result):
            log.add("mini-app", "#\(number) Đã đóng · \(reason.rawValue)\(result.map { " · \($0.rawValue)" } ?? "")")
        }
    }
}
