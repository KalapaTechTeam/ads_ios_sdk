//
//  DemoTone.swift
//  KalapaAdsDemo
//
//  Created by thachlh on 13/10/26.
//

import UIKit

enum DemoTone {
    case neutral
    case progress
    case success
    case warning
    case failure

    var color: UIColor {
        switch self {
        case .neutral: return UIColor(named: "TextSecondary") ?? .secondaryLabel
        case .progress: return UIColor(named: "Primary") ?? .systemBlue
        case .success: return .systemGreen
        case .warning: return .systemOrange
        case .failure: return .systemRed
        }
    }
}
