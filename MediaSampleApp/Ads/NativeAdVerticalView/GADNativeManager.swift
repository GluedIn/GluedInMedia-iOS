import Foundation
import GoogleMobileAds
import GluedInCoreSDK
import UIKit

typealias successHandlerCustNative = (_ customNativeAd: CustomNativeAd) -> ()
typealias successHandlerNative = (_ nativeAd: NativeAd) -> ()

typealias errorHandlerNative = (_ error: String) -> ()

class GADNativeManager: NSObject, NativeAdLoaderDelegate {
    
    var adLoaderDelegate: AdLoaderDelegate?
    var gadAdLoader: AdLoader?
    var adsFormatIds: [String]?
    private var completed: successHandlerCustNative?
    private var completNative: successHandlerNative?
    private var failedWithError: errorHandlerNative?
    
    override init() {
        super.init()
    }

    deinit {
        debugPrint("Deinit: GADNativeManager")
    }

    func getExtraAdditionalParameters(
        gamExtraParams: [GAMExtraParams]?,
        configParams: [String: String]?
    ) -> [String: String]? {
        let userDefineParameters = gamExtraParams?.reduce(into: [String: String]()) { dictionary, response in
            if let key = response.key,
               let value = response.value {
                dictionary[key] = value
            }
        }
        
        let dictionaries: [[String: String]?] = [configParams, userDefineParameters]
        
        let combinedDict = dictionaries.compactMap { $0 }.reduce([String: String]()) { (result, dict) in
            return result.merging(dict) { (_, new) in new }
        }
        return combinedDict
    }

    func loadNativeAds(
        configParams: [String: String]?,
        gamExtraParams: [GAMExtraParams]?,
        adUnitID: String?,
        adsFormatId: [String]?,
        didCompeleted: @escaping successHandlerCustNative,
        didFailedWithError: @escaping errorHandlerNative
    ) {
        self.completed = didCompeleted
        self.failedWithError = didFailedWithError
        self.adsFormatIds = adsFormatId
        self.adLoaderDelegate = self
        MobileAds.shared.audioVideoManager.isAudioSessionApplicationManaged = true
        let videoOptions = VideoOptions()
        videoOptions.shouldStartMuted = true
        videoOptions.areCustomControlsRequested = true
        
        self.gadAdLoader = AdLoader(
            adUnitID: adUnitID ?? "",
            rootViewController: nil,
            adTypes: [.customNative],
            options: [videoOptions]
        )
        self.gadAdLoader?.delegate = self
        let request = AdManagerRequest()
        if let customTargetingParams = getExtraAdditionalParameters(
            gamExtraParams: gamExtraParams,
            configParams: configParams
        ) {
            request.customTargeting = customTargetingParams
        }
        self.gadAdLoader?.load(request)
    }

    func fetchAdsNative(
        adUnitID: String?,
        didCompeleted: @escaping successHandlerNative,
        didFailedWithError: @escaping errorHandlerNative
    ) {
        self.completNative = didCompeleted
        self.failedWithError = didFailedWithError
        self.adLoaderDelegate = self
        MobileAds.shared.audioVideoManager.isAudioSessionApplicationManaged = true
        let videoOptions = VideoOptions()
        videoOptions.shouldStartMuted = true
        videoOptions.areCustomControlsRequested = true
        
        self.gadAdLoader = AdLoader(
            adUnitID: adUnitID ?? "",
            rootViewController: nil,
            adTypes: [.native],
            options: [videoOptions]
        )
        self.gadAdLoader?.delegate = self
        let request = AdManagerRequest()
        self.gadAdLoader?.load(request)
    }
    
    func fetchAds(
        genre: [String]?,
        dialect: [String]?,
        originalLanguage: [String]?,
        gamExtraParams: [GAMExtraParams]?,
        adUnitID: String?,
        adsFormatId: [String]?,
        didCompeleted: @escaping successHandlerNative,
        didFailedWithError: @escaping errorHandlerNative
    ) {
        self.completNative = didCompeleted
        self.failedWithError = didFailedWithError
        self.adsFormatIds = adsFormatId
        self.adLoaderDelegate = self
        MobileAds.shared.audioVideoManager.isAudioSessionApplicationManaged = true
        let videoOptions = VideoOptions()
        videoOptions.shouldStartMuted = true
        videoOptions.areCustomControlsRequested = true
        
        self.gadAdLoader = AdLoader(
            adUnitID: adUnitID ?? "",
            rootViewController: nil,
            adTypes: [.customNative],
            options: [videoOptions]
        )
        self.gadAdLoader?.delegate = self
        let request = AdManagerRequest()
        if let customTargetingParams = getExtraAdditionalParameters(
            gamExtraParams: gamExtraParams,
            configParams: nil
        ) {
            request.customTargeting = customTargetingParams
        }
        self.gadAdLoader?.load(request)
    }


    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        // Handle receiving a native ad
        completNative?(nativeAd)
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        failedWithError?(error.localizedDescription)
    }

    func adLoaderDidFinishLoading(_ adLoader: AdLoader) {
        self.gadAdLoader = nil
        self.adLoaderDelegate = nil
    }
}

extension GADNativeManager: CustomNativeAdLoaderDelegate {

    func customNativeAdFormatIDs(for adLoader: AdLoader) -> [String] {
        return adsFormatIds ?? []
    }

    func adLoader(_ adLoader: AdLoader, didReceive customNativeAd: CustomNativeAd) {
        completed?(customNativeAd)
    }
}
