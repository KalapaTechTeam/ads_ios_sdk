//
//  String+ShortId.swift
//  KalapaAdsDemo
//
//  Created by thachlh on 13/10/26.
//

extension String {
    /// First block of a UUID, enough to tell ads apart in the log.
    var shortId: String {
        split(separator: "-").first.map(String.init) ?? self
    }
}
