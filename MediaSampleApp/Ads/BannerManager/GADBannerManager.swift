//
//  GADBannerManager.swift
//  GluedIn
//
//  Created by Amit Choudhary on 22/08/24.
//

import Foundation
import GoogleMobileAds
import UIKit

typealias BannerLoadCompletion = (_ view: UIView?) -> Void

final class GADBannerManager: NSObject {

    static let shared = GADBannerManager()

    // Keep banners alive + store completion per banner
    private var bannerCompletions: [ObjectIdentifier: BannerLoadCompletion] = [:]
    private var banners: [ObjectIdentifier: BannerView] = [:]

    func initializeAds() {
        MobileAds.shared.start(completionHandler: nil)
    }

    /// Loads a banner. Completion returns:
    /// - bannerView (when loaded)
    /// - nil (if failed / not loaded)
    func loadBanner(
        adUnitID: String,
        viewController: UIViewController?,
        completion: @escaping BannerLoadCompletion
    ) {
        guard let viewController else {
            completion(nil)
            return
        }

        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = viewController
        bannerView.delegate = self

        let key = ObjectIdentifier(bannerView)
        banners[key] = bannerView
        bannerCompletions[key] = completion

        bannerView.load(Request())
    }

    private func finish(_ bannerView: BannerView, result: UIView?) {
        let key = ObjectIdentifier(bannerView)
        let completion = bannerCompletions[key]

        // cleanup
        bannerCompletions[key] = nil
        banners[key] = nil

        DispatchQueue.main.async {
            completion?(result)
        }
    }
}

// MARK: - GADBannerViewDelegate
extension GADBannerManager: BannerViewDelegate {

    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        print("✅ Banner loaded successfully")
        finish(bannerView, result: bannerView)
    }

    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        print("❌ Failed to receive ads: \(error.localizedDescription)")
        finish(bannerView, result: nil)
    }

    func bannerViewWillPresentScreen(_ bannerView: BannerView) { print("bannerViewWillPresentScreen") }
    func bannerViewWillDismissScreen(_ bannerView: BannerView) { print("bannerViewWillDismissScreen") }
    func bannerViewDidDismissScreen(_ bannerView: BannerView) { print("bannerViewDidDismissScreen") }

    // NOTE: For newer SDKs this may not be called; it's fine to keep if it compiles.
    func adViewWillLeaveApplication(_ bannerView: BannerView) { print("adViewWillLeaveApplication") }
}

