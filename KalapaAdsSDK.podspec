# The podspec published to CocoaPods trunk: the binary built by build_sdk.sh, downloaded from the
# GitHub release. ../KalapaAdsSDK.podspec builds from source and stays internal.
# build_sdk.sh writes the version and the checksum.

Pod::Spec.new do |s|
  s.name             = 'KalapaAdsSDK'
  s.version          = '0.1.0'
  s.summary          = 'Kalapa Ads SDK for iOS: banner, interstitial and native ads.'
  s.description      = <<-DESC
    Kalapa Ads SDK serves Kalapa Ads Network creatives in iOS apps: native ads for UIKit and
    SwiftUI, the mini-app they open, and the banner and interstitial formats.
  DESC

  s.homepage         = 'https://github.com/KalapaTechTeam/ads_ios_sdk'
  s.license          = { :type => 'Commercial', :text => 'Copyright Kalapa. All rights reserved.' }
  s.author           = { 'Kalapa' => 'dev@kalapa.vn' }
  s.source           = {
    :http => "https://github.com/KalapaTechTeam/ads_ios_sdk/releases/download/#{s.version}/KalapaAdsSDK.xcframework.zip",
    :sha256 => '1b4608cc2a78cd19c6dfc9eb9e90745cc2f7b5a33cf01f264df1334010e91cbe'
  }

  s.ios.deployment_target = '15.1'
  s.swift_version    = '5.9'
  s.static_framework = true

  s.vendored_frameworks = 'KalapaAdsSDK.xcframework'
  s.resources        = 'KalapaAdsSDK.bundle'
  s.frameworks       = 'UIKit', 'WebKit', 'SwiftUI', 'Combine'
end
