//
//  NativeAdVerticalViewController.swift
//  plusSAW
//
//  Created by plusSAW on 17/11/21.
//  Copyright © 2021 SAW. All rights reserved.
//

import UIKit
import GoogleMobileAds
import GluedInFeedSDK
import GluedInCoreSDK
import AVFoundation

enum MySimpleNativeAdViewTypeProperties {
    static let HeadlineKey = "Heading"
    static let MainImageKey = "Image"
    static let DescriptionKey = "Description"
    static let CTATextKey = "CTAText"
    static let LogoKey = "Logo"
    static let TextURLKey = "TextURL"
}

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}

class NativeAdVerticalViewController: UIViewController {
    
    @IBOutlet weak var nativeAdPlaceholder: UIView!
    
    @IBOutlet weak var labelDescription: UILabel!
    @IBOutlet weak var buttonCTA: UIButton!
    @IBOutlet weak var viewLogo: UIView!
    @IBOutlet weak var imageLogo: UIImageView!
    @IBOutlet weak var labelTitle: UILabel!
    
    @IBOutlet weak var imageViewPlay: UIImageView!
    @IBOutlet weak var clearView: UIView!
    @IBOutlet weak var mediaView: MediaView!
    @IBOutlet weak var adsImageView: UIImageView!
    
    var customNativeAds: CustomNativeAd?
    var NativeAds: NativeAd?
    // Tracks whether ad video was playing right before an audio interruption (e.g., phone call)
    private var wasPlayingBeforeInterruption = false

    deinit {
        NotificationCenter.default.removeObserver(self)
        print("Deinit Controller :- NativeAdVerticalViewController")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setUpUI()
        prepareAdvertisementView()
        // Observe audio session interruptions (e.g., phone calls)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }
    
    func setUpUI() -> () {
        imageViewPlay.image = UIImage(named: "icAdsPlay")
        imageViewPlay.isHidden = true
        
        let playPauseTap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        imageViewPlay.isUserInteractionEnabled = true
        imageViewPlay.addGestureRecognizer(playPauseTap)
        
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.numberOfTapsRequired = 1
        clearView.addGestureRecognizer(tapGesture)
        
        labelDescription.font = UIFont.systemFont(ofSize: 15)
        buttonCTA.backgroundColor = UIColor(red: 209.0/255.0, green: 215.0/255.0, blue: 224.0/255.0, alpha: 0.3)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) {  [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.buttonCTA.backgroundColor = UIColor.white
        }
        buttonCTA.layer.cornerRadius = 24.0
        buttonCTA.setTitleColor(UIColor(red: 24.0/255.0, green: 29.0/255.0, blue: 37.0/255.0, alpha: 0.8), for: .normal)
        buttonCTA.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        buttonCTA.addTarget(self, action: #selector(onClickCTA), for: .touchUpInside)
        
        labelTitle.font = UIFont.systemFont(ofSize: 17) //.textStyleRegular17
        
        imageLogo.contentMode = .scaleAspectFit
        
        imageLogo.layer.cornerRadius = imageLogo.frame.size.height / 2
        
        viewLogo.layer.cornerRadius = viewLogo.frame.size.height / 2
        viewLogo.layer.masksToBounds = true
        
        adsImageView.contentMode = .scaleAspectFit
        mediaView.isHidden = true
        adsImageView.isHidden = true
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        if NativeAds?.mediaContent.hasVideoContent ?? false {
            if imageViewPlay.isHidden {
                mediaView?.mediaContent?.videoController.pause()
                imageViewPlay.isHidden = false
            } else {
                mediaView?.mediaContent?.videoController.play()
                imageViewPlay.isHidden = true
            }
        }
        if customNativeAds?.mediaContent.hasVideoContent ?? false {
            if imageViewPlay.isHidden {
                mediaView?.mediaContent?.videoController.pause()
                imageViewPlay.isHidden = false
            } else {
                mediaView?.mediaContent?.videoController.play()
                imageViewPlay.isHidden = true
            }
        }
    }
    
    @objc func onClickCTA(_ sender: UIButton) {
        let textURLKey = MySimpleNativeAdViewTypeProperties.TextURLKey
      if let textURL = customNativeAds?.string(forKey: textURLKey),
           let url = URL(string: textURL) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
      } else if  let textURL = NativeAds?.advertiser,
                 let url = URL(string: textURL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
      } else {
        buttonCTA.isHidden = true
      }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if customNativeAds?.mediaContent.hasVideoContent ?? false {
            imageViewPlay.isHidden = true
            //            mediaView?.mediaContent?.videoController.play()
            //            mediaView?.mediaContent?.videoController.setMute(true)
            //            mediaView?.mediaContent?.videoController.pause()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        mediaView?.mediaContent?.videoController.play()
        mediaView?.mediaContent?.videoController.isMuted = true
        super.viewDidAppear(animated)
    }
     
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        if customNativeAds?.mediaContent.hasVideoContent ?? false {
//            mediaView?.mediaContent?.videoController.pause()
//        }
    }
    
    private func currentVideoController() -> VideoController? {
        if let hasVideo = NativeAds?.mediaContent.hasVideoContent, hasVideo {
            return mediaView?.mediaContent?.videoController
        }
        if let hasVideo = customNativeAds?.mediaContent.hasVideoContent, hasVideo {
            return mediaView?.mediaContent?.videoController
        }
        return nil
    }
    
    @objc private func handleAudioSessionInterruption(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        switch type {
        case .began:
            // Remember if it was playing (overlay hidden implies playing)
            wasPlayingBeforeInterruption = imageViewPlay.isHidden
            // Pause playback and show overlay
            currentVideoController()?.pause()
            imageViewPlay.isHidden = false

        case .ended:
            // Check whether the system recommends resuming
            let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue ?? 0)
            if options.contains(.shouldResume), wasPlayingBeforeInterruption {
                currentVideoController()?.play()
                imageViewPlay.isHidden = true
            }
            // Reset flag
            wasPlayingBeforeInterruption = false

        @unknown default:
            break
        }
    }
    
}

extension NativeAdVerticalViewController {
    
    func prepareAdvertisementView() {
        if let customAds = customNativeAds {
            addCustomNativeAds(customNativeAds: customAds)
        } else if let NativeAds = NativeAds {
          addCustomNativeAds(customNativeAds: NativeAds)
        }
      
    }
    
    func addCustomNativeAds(customNativeAds: NativeAd?) -> () {
      DispatchQueue.main.async { [weak self] in
          guard let weakSelf = self else { return }
        let logoImage: UIImage? = customNativeAds?.icon?.image
          weakSelf.imageLogo.image = logoImage
        weakSelf.labelTitle.text = customNativeAds?.headline
        weakSelf.buttonCTA.setTitle(customNativeAds?.callToAction?.description, for: .normal)
        weakSelf.labelDescription.text = customNativeAds?.body
          
          if customNativeAds?.mediaContent.hasVideoContent ?? false {
              weakSelf.mediaView.mediaContent = customNativeAds?.mediaContent
              weakSelf.mediaView.mediaContent?.videoController.delegate = self
              weakSelf.mediaView.isHidden = false
          } else {
              let imageKey = MySimpleNativeAdViewTypeProperties.MainImageKey
              let image: UIImage? = customNativeAds?.images?.first?.image
              weakSelf.adsImageView.image = image
              weakSelf.adsImageView.isHidden = false
          }
        
        if ((customNativeAds?.advertiser) != nil) {
          weakSelf.buttonCTA.isHidden = false
        } else {
          weakSelf.buttonCTA.isHidden = true
        }
      }
  }
    func addCustomNativeAds(customNativeAds: CustomNativeAd?) -> () {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else { return }
            let logoKey = MySimpleNativeAdViewTypeProperties.LogoKey
            let logoImage: UIImage? = customNativeAds?.image(forKey: logoKey)?.image
            weakSelf.imageLogo.image = logoImage
            
            let headlineKey = MySimpleNativeAdViewTypeProperties.HeadlineKey
            weakSelf.labelTitle.text = customNativeAds?.string(forKey: headlineKey)
            
            let ctaTextKey = MySimpleNativeAdViewTypeProperties.CTATextKey
            weakSelf.buttonCTA.setTitle(customNativeAds?.string(forKey: ctaTextKey), for: .normal)
            
            let descriptionKey = MySimpleNativeAdViewTypeProperties.DescriptionKey
            weakSelf.labelDescription.text = customNativeAds?.string(forKey: descriptionKey)
            
            if customNativeAds?.mediaContent.hasVideoContent ?? false {
                weakSelf.mediaView.mediaContent = customNativeAds?.mediaContent
                weakSelf.mediaView.mediaContent?.videoController.delegate = self
                weakSelf.mediaView.isHidden = false
            } else {
                let imageKey = MySimpleNativeAdViewTypeProperties.MainImageKey
                let image: UIImage? = customNativeAds?.image(forKey: imageKey)?.image
                weakSelf.adsImageView.image = image
                weakSelf.adsImageView.isHidden = false
            }
            customNativeAds?.recordImpression()
        }
    }
    
}

extension NativeAdVerticalViewController: VideoControllerDelegate {
    
    func videoControllerDidPlayVideo(_ videoController: VideoController) {
        imageViewPlay.isHidden = true
    }
    
    func videoControllerDidPauseVideo(_ videoController: VideoController) {
    }
    
    func videoControllerDidMuteVideo(_ videoController: VideoController) {
        
    }
    
    func videoControllerDidUnmuteVideo(_ videoController: VideoController) {
        
    }
    
    func videoControllerDidEndVideoPlayback(_ videoController: VideoController) {
        videoController.play()
    }
    
}
