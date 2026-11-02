//
//  FeedPlaceholder.swift
//  KalapaAdsDemo
//
//  Created by thachlh on 15/10/26.
//

import SwiftUI

/// Grey stand-in for the host's own content around the ad.
struct FeedPlaceholder: View {
    let title: String
    let lines: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color("TextPrimary"))
            ForEach(0..<lines, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color("TextSecondary").opacity(0.18))
                    .frame(height: 10)
                    .padding(.trailing, index == lines - 1 ? 80 : 0)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color("Card")))
    }
}
