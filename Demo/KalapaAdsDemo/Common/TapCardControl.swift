//
//  TapCardControl.swift
//  KalapaAdsDemo
//
//  Created by thachlh on 13/10/26.
//

import UIKit

final class TapCardControl: UIControl {
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.12) {
                self.alpha = self.isHighlighted ? 0.6 : 1
            }
        }
    }
}
