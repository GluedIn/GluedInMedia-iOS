//
//  GADInterstitialManager.swift
//  plusSAW
//
//  Created by Ashish Verma on 09/11/21.
//  Copyright © 2021 SAW. All rights reserved.
//

import Foundation
import GoogleMobileAds
import UIKit
import AdSupport
import GluedInFeedSDK
import GluedInCoreSDK

typealias successHandlerInter = (_ didCompleted: Bool) -> ()
typealias errorHandlerInter = (_ didCompleteWithError: String) -> ()
typealias didPresentFullScreenContent = () -> ()
typealias didDismissFullScreenContent = () -> ()
typealias didFailToPresentFullScreenContentWithError = (_ didFailToPresentWithError: String) -> ()

class GADInterstitialManager: NSObject, FullScreenContentDelegate {
    
    static let shared: GADInterstitialManager = {
        let manager = GADInterstitialManager()
        return manager
    }()
    
    private var interstitial: InterstitialAd?
    private var presentFullScreenContent: didPresentFullScreenContent?
    private var dismissFullScreenContent: didDismissFullScreenContent?
    private var failToPresentFullScreenContentWithError : didFailToPresentFullScreenContentWithError?
    
    func initilizeAds() -> () {
        MobileAds.shared.start(completionHandler: nil)
    }
    
    func loadInterstitialAds(
        adUnitID: String,
        didCompleted: @escaping successHandlerInter,
        didCompleteWithError: @escaping errorHandlerInter
    ) -> () {
        InterstitialAd.load(
            with: adUnitID,
            request: Request(),
            completionHandler: { [weak self] ad, error in
                guard let self = self else { return }
                if let error = error {
                    didCompleteWithError(error.localizedDescription)
                    return
                }
                interstitial = ad
                interstitial?.fullScreenContentDelegate = self
                didCompleted(true)
            })
    }
    
    func showInterstitialAds(
        view: UIViewController,
        didPresent: @escaping didPresentFullScreenContent,
        didDismiss: @escaping didDismissFullScreenContent,
        didFailToPresent: @escaping didFailToPresentFullScreenContentWithError
    ) -> () {
        presentFullScreenContent = didPresent
        dismissFullScreenContent = didDismiss
        failToPresentFullScreenContentWithError = didFailToPresent
        if let ad = interstitial {
            ad.present(from: view)
        } else {
            print("Ads was not ready")
        }
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ads Fail to Present")
    }
    
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        presentFullScreenContent?()
    }
    
    func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        dismissFullScreenContent?()
    }
    
}



