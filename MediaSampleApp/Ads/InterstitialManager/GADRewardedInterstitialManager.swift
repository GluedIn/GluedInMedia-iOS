//
//  GADRewardedInterstitialManager.swift
//  GluedIn
//
//  Created by Ashish on 22/10/25.
//

import Foundation
import GoogleMobileAds
import UIKit

typealias successHandlerRewardInter = (_ didCompleted: Bool) -> ()
typealias errorHandlerRewardInter = (_ didCompleteWithError: String) -> ()
typealias didPresentFullScreenContentRewardInter = () -> ()
typealias didDismissFullScreenContentRewardInter = () -> ()
typealias didFailToPresentFullScreenContentWithErrorRewardInter = (_ didFailToPresentWithError: String) -> ()
typealias didEarnRewardHandler = (_ type: String, _ amount: NSDecimalNumber) -> ()

final class GADRewardedInterstitialManager: NSObject, FullScreenContentDelegate {

    static let shared = GADRewardedInterstitialManager()

    private var rewardedInterstitial: RewardedInterstitialAd?
    private var presentHandler: didPresentFullScreenContentRewardInter?
    private var dismissHandler: didDismissFullScreenContentRewardInter?
    private var failPresentHandler: didFailToPresentFullScreenContentWithErrorRewardInter?
    private var earnRewardHandler: didEarnRewardHandler?

    func initializeAds() {
        MobileAds.shared.start(completionHandler: nil)
    }

    func loadRewardedInterstitial(
        adUnitID: String,
        didCompleted: @escaping successHandlerRewardInter,
        didCompleteWithError: @escaping errorHandlerRewardInter
    ) {
        RewardedInterstitialAd.load(with: adUnitID,
                                    request: Request()) { [weak self] ad, error in
            guard let self = self else { return }
            if let error = error {
                didCompleteWithError(error.localizedDescription)
                return
            }
            self.rewardedInterstitial = ad
            self.rewardedInterstitial?.fullScreenContentDelegate = self
            didCompleted(true)
        }
    }

    /// Presents the rewarded-interstitial. If the user watches enough, `earnReward` is invoked.
    func showRewardedInterstitial(
        from viewController: UIViewController,
        didPresent: @escaping didPresentFullScreenContentRewardInter,
        didDismiss: @escaping didDismissFullScreenContentRewardInter,
        didFailToPresent: @escaping didFailToPresentFullScreenContentWithErrorRewardInter,
        earnReward: @escaping didEarnRewardHandler
    ) {
        presentHandler = didPresent
        dismissHandler = didDismiss
        failPresentHandler = didFailToPresent
        earnRewardHandler = earnReward

        guard let ad = rewardedInterstitial else {
            didFailToPresent("Rewarded interstitial not ready")
            return
        }

        ad.present(from: viewController) { [weak self] in
            guard let self = self else { return }
            let reward = ad.adReward
            // Called only when the user has earned the reward.
            self.earnRewardHandler?(reward.type, reward.amount)
        }
    }

    // MARK: - GADFullScreenContentDelegate
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        presentHandler?()
    }

    func ad(_ ad: FullScreenPresentingAd,
            didFailToPresentFullScreenContentWithError error: Error) {
        failPresentHandler?(error.localizedDescription)
        rewardedInterstitial = nil
    }

    func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        dismissHandler?()
        rewardedInterstitial = nil
    }
}
