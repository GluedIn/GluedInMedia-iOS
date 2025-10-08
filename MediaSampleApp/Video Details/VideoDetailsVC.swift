//
//  VideoDetailsVC.swift
//  MediaSampleApp
//
//  Created by Abhishek Mishra on 04/09/25.
//

import UIKit
import GluedInCoreSDK
import GluedInCreatorSDK
import GluedInSDK
 
class VideoDetailsVC: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var scrView: UIScrollView!
    @IBOutlet weak var viewBg: UIView!
    @IBOutlet weak var viewCreator: UIView!
    @IBOutlet weak var lblcreatorone: UILabel!
    @IBOutlet weak var lblCreatorTwo: UILabel!
    @IBOutlet weak var relatedCollectionView: UICollectionView!
    @IBOutlet weak var btnLeaderBoard: UIButton!
    @IBOutlet weak var labelWidgetTitle: UILabel!
    @IBOutlet weak var btnReward: UIButton!

    // MARK: - Properties
    private var widgetVideos: [FeedModel] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.relatedCollectionView.reloadData()
                let hasVideos = !self.widgetVideos.isEmpty
                self.relatedCollectionView.isHidden = !hasVideos
                self.labelWidgetTitle.isHidden = !hasVideos
            }
        }
    }

    private var widgetData: WidgetResponse?
    
    var assetsDetail: Asset = Asset(
        id: AssetDetails.productId,
        assetName: AssetDetails.assetName,
        discountPrice: 200,
        imageUrl: AssetDetails.imageUrl,
        discountEndDate: "",
        discountStartDate: "",
        callToAction: AssetDetails.callToAction,
        mrp: 40000,
        shoppableLink: AssetDetails.shoppableLink,
        currencySymbol: AssetDetails.currencySymbol
    )

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        
        registerXIBs()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        fetchWidgetsData()
    }

    // MARK: - UI Setup
    func setupUI() {
        btnLeaderBoard.layer.borderColor = btnLeaderBoard.titleLabel?.textColor?.cgColor
        btnLeaderBoard.layer.borderWidth = 1.0
        
        btnReward.layer.borderColor = btnReward.titleLabel?.textColor?.cgColor
        btnReward.layer.borderWidth = 1.0

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleCreatorTap))
        viewCreator.isUserInteractionEnabled = true
        viewCreator.addGestureRecognizer(tapGesture)
    }

    func registerXIBs() {
        if let layout = relatedCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.estimatedItemSize = .zero
        }

        let nib = UINib(nibName: VideoCollectionCell.identifier, bundle: nil)
        relatedCollectionView.register(nib, forCellWithReuseIdentifier: VideoCollectionCell.identifier)
        relatedCollectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    // MARK: - Creator Tap
    @objc func handleCreatorTap() {
        guard let widgetRespData = widgetData else { return }

        view.isUserInteractionEnabled = false
        initializeSDK { [weak self] isSuccess in
            guard let self = self else { return }

            if isSuccess {
                GluedIn.shared.launchSDK(
                    typeOfEntry: .creator,
                    assets: self.assetsDetail,
                    challenge: widgetRespData.result?.challengeInfo?.title,
                    contextType: nil,
                    contextId: nil,
                    selectedContentId: nil,
                    challengeInfo: nil,
                    isRewardCallback: false,
                    delegate: self
                ) { controller in
                    self.view.isUserInteractionEnabled = true
                    if let controller = controller {
                        self.navigationController?.pushViewController(controller, animated: true)
                    }
                } failure: { error in
                    self.view.isUserInteractionEnabled = true
                    self.showDefaultAlert(title: "", message: error)
                }
            }
        }
    }

    // MARK: - Leaderboard Button
    @IBAction func actionLeaderBoard(_ sender: Any) {
        guard let challengeData = widgetData?.result?.challengeInfo else { return }

        view.isUserInteractionEnabled = false
        initializeSDK { [weak self] isSuccess in
            guard let self = self else { return }

            if isSuccess {
                GluedIn.shared.launchSDK(
                    typeOfEntry: .leaderboard,
                    assets: self.assetsDetail,
                    challenge: nil,
                    contextType: nil,
                    contextId: nil,
                    selectedContentId: nil,
                    challengeInfo: challengeData,
                    isRewardCallback: false,
                    delegate: self
                ) { controller in
                    self.view.isUserInteractionEnabled = true
                    if let controller = controller {
                        self.navigationController?.pushViewController(controller, animated: true)
                    }
                } failure: { error in
                    self.view.isUserInteractionEnabled = true
                    self.showDefaultAlert(title: "", message: error)
                }
            }
        }
    }

    // MARK: - Reward Button
    @IBAction func actionReward(_ sender: Any) {
        initializeSDK { [weak self] isSuccess in
            guard let weakSelf = self else { return }
            if isSuccess {
                GluedIn.shared.launchSDK(
                    typeOfEntry: .reward,
                    assets: weakSelf.assetsDetail,
                    challenge: nil,
                    contextType: nil,
                    contextId: nil,
                    selectedContentId: nil,
                    challengeInfo: nil,
                    isRewardCallback: false,
                    delegate: self
                ) { controller in
                    
                    if let controller = controller {
                        weakSelf.navigationController?.pushViewController(controller, animated: true)
                    }
                } failure: { error in
                    weakSelf.showDefaultAlert(title: "", message: error)
                }
            }
        }
    }
    // MARK: - Back Button
    @IBAction func backButtonTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Fetch Widget Data
    func fetchWidgetsData() {
        initializeSDK { [weak self] isSuccess in
            guard let self = self else { return }

            if isSuccess {
                let assetId = self.assetsDetail.id ?? ""

                GluedIn.shared.widgetDetailWithFeed(byAssetId: assetId) { widgetDetails, feeds in
                    self.widgetData = widgetDetails

                    if let videos = feeds?.result {
                        self.widgetVideos = videos
                    }

                    let challengeInfo = widgetDetails?.result?.challengeInfo
                    self.updateCreatorTitle(widgetDetails: widgetDetails)

                    self.btnLeaderBoard.isHidden = challengeInfo != nil ?
                        (feeds?.result?.isEmpty ?? true) || !(challengeInfo?.leaderboardEnabled ?? false)
                        : true
                    self.btnReward.isHidden = !GluedInCore.shared.isRewardEnable()

                    self.viewCreator.isHidden = !(widgetDetails?.result?.creatorEnabled ?? false)
                    self.labelWidgetTitle.text = widgetDetails?.result?.widgetTitle?.en ?? ""
                } failure: { error, _ in
                    Debug.Log(message: error)
                }
            }
        }
    }

    // MARK: - Creator Title
    func updateCreatorTitle(widgetDetails: WidgetResponse?) {
        if let challengeTitle = widgetDetails?.result?.challengeInfo?.title {
            let titleString = "Participate in #\(challengeTitle) Upload videos and earn reward points"
            let attributed = NSMutableAttributedString(string: titleString,
                                                       attributes: [.font: UIFont.systemFont(ofSize: 12)])

            let boldRange = (titleString as NSString).range(of: "#\(challengeTitle)")
            attributed.addAttributes([.font: UIFont.boldSystemFont(ofSize: 12)], range: boldRange)

            lblcreatorone.attributedText = attributed
            lblcreatorone.textAlignment = .left
            lblcreatorone.numberOfLines = 0
        } else {
            lblcreatorone.text = widgetDetails?.result?.creatorTitle?.en ?? "createVideoTitle"
            lblcreatorone.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            lblcreatorone.textAlignment = .center
            lblcreatorone.numberOfLines = 1
        }
    }

    // MARK: - Initialize SDK
    private func initializeSDK(completionHandler: @escaping (Bool) -> Void) {
        GluedIn.shared.initWithUserInfo(
            apiKey: SDKEnvironment.apiKey,
            secretKey: SDKEnvironment.secretKey,
            email: SDKEnvironment.email,
            password: SDKEnvironment.password,
            fullName: SDKEnvironment.name,
            personaType: ""
        ) {
            completionHandler(true)
        } failure: { [weak self] error, _ in
            self?.view.isUserInteractionEnabled = true
            print(error)
        }
    }

    func showDefaultAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionView Delegate & DataSource
extension VideoDetailsVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return widgetVideos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let videoCell = collectionView.dequeueReusableCell(
            withReuseIdentifier: VideoCollectionCell.identifier, for: indexPath
        ) as? VideoCollectionCell else {
            return UICollectionViewCell()
        }
        videoCell.configureData(feed: widgetVideos[indexPath.item])
        return videoCell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let model = widgetVideos[indexPath.item]

        view.isUserInteractionEnabled = false
        initializeSDK { [weak self] isSuccess in
            guard let self = self else { return }

            if isSuccess {
                GluedIn.shared.launchSDK(
                    typeOfEntry: .subFeed,
                    assets: self.assetsDetail,
                    challenge: nil,
                    contextType: .asset,
                    contextId: self.assetsDetail.id,
                    selectedContentId: model.videoId,
                    challengeInfo: nil,
                    isRewardCallback: false,
                    delegate: self
                ) { controller in
                    self.view.isUserInteractionEnabled = true
                    if let controller = controller {
                        self.navigationController?.pushViewController(controller, animated: true)
                    }
                } failure: { error in
                    self.view.isUserInteractionEnabled = true
                    self.showDefaultAlert(title: "", message: error)
                }
            }
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return CGSize(width: 98, height: 175)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 8.0
    }
}
 
extension VideoDetailsVC : GluedInDelegate {
    func onUserAction(action: GluedInCoreSDK.UserAction, assetId: String?, productUrl: String?, eventRefId: Int, navigationController: UINavigationController) {
        
    }
    
    func navigateToCart(viewController: UIViewController?) {
        
    }
    
    func showOrderHistory(viewController: UIViewController?) {
        
    }
    
    func getCartItemCount(completion: @escaping (Result<Int, any Error>) -> Void) {
        
    }
    
    func onInitiateSeriesPurchase(paymentType: GluedInCoreSDK.PaymentMethod, inAppSkuId: String?, purchaseUrl: String?, seriesId: String?, episodeNumber: Int?, controller: UIViewController?) {
    }
    
    func appScreenViewEvent(pageName: String) {
    }
    
    func appViewClickEvent(device_ID: String, user_email: String, user_name: String, platform_name: String) {
    }
    
    func appLaunchEvent(deviceID: String, platformName: String) {
    }
    
    func requestForBannerAds(viewController: UIViewController?, adsType: GluedInCoreSDK.AdsType, adUnitID: String?, customParmas: [GluedInCoreSDK.GAMExtraParams]?) -> UIView? {
        return UIView()
    }
    
    func requestForInterstitialAds(viewController: UIViewController?, adsType: GluedInCoreSDK.AdsType, adUnitID: String?, customParmas: [GluedInCoreSDK.GAMExtraParams]?) {
        
    }
    
    func requestForAdmobNativeAds(viewController: UIViewController?, adUnitID: String?, adsType: GluedInCoreSDK.AdsType, customParmas: [GluedInCoreSDK.GAMExtraParams]?) {
        
    }
    
    func getAdmobNativeAdsController() -> UIViewController? {
        return UIViewController()
    }
    
    func getNativeAdNibName() -> String {
        return ""
    }
    
    func requestNativeAdCell() -> UITableViewCell {
        return UITableViewCell()
    }
    
    func requestForGamNativeAds(adUnitID: String?, adsType: GluedInCoreSDK.AdsType, configParams: [String : String]?, extraParams: [GluedInCoreSDK.GAMExtraParams]?, adsFormatId: [String]?) {
        
    }
    
    func getGamNativeAdsController() -> UIViewController? {
        return UIViewController()
    }
    
    func onAnalyticsEvent(name: String, properties: [String : Any]) {
        
    }
    
    func appScreenViewEvent(journeyEntryPoint: String, pageName: String) {
        
    }
    
    func appViewMoreEvent(Journey_entry_point: String, device_ID: String, user_email: String, user_name: String, platform_name: String, page_name: String, tab_name: String, element: String, button_type: String) {
        
    }
    
    func appContentUnLikeEvent(eventName: String?, params: [String : Any]?) {
        
    }
    
    func appContentLikeEvent(eventName: String?, params: [String : Any]?) {
        
    }
    
    func appVideoReplayEvent(eventName: String?, params: [String : Any]?) {
        
    }
    
    func appSessionEvent(eventName: String?, params: [String : Any]?) {
        
    }
    
    func appVideoPlayEvent(eventName: String?, params: [String : Any]?) {
        
    }
    
    func appContentSwipeEvent(eventName: String?, params: [String : Any]?) {
        
    }
    
    func appVideoPauseEvent(eventName: String?, params: [String : Any]?) {
        
    }
    
    func appVideoResumeEvent(eventName: String?, params: [String : Any]?) {
        
    }
    
    func appCommentsViewedEvent(eventName: String?, params: [String : Any]?) {
        
    }
    
    func appCommentedEvent(eventName: String?, params: [String : Any]?) {
        
    }
    
    func appContentNextEvent(eventName: String?, params: [String : Any]?) {
        
    }
    
    func appContentPreviousEvent(eventName: String?, params: [String : Any]?) {
        
    }
    
    func appVideoStopEvent(device_ID: String, content_id: String, user_email: String, user_name: String, user_id: String, platform_name: String, page_name: String, tab_name: String, creator_userid: String, creator_username: String, hashtag: String, content_type: String, gluedIn_version: String, played_duration: String, content_creator_id: String, dialect_id: String, dialect_language: String, genre: String, genre_id: String, shortvideo_labels: String, video_duration: String, feed: GluedInCoreSDK.FeedModel?) {
        
    }
    
    func appViewClickEvent(device_ID: String, user_email: String, user_name: String, user_id: String, platform_name: String, page_name: String, tab_name: String, content_type: String, button_type: String, cta_name: String, gluedIn_version: String, feed: GluedInCoreSDK.FeedModel?) {
        
    }
    
    func appUserFollowEvent(eventName: String?, params: [String : Any]?) {
        
    }
    
    func appCTAClickedEvent(eventName: String?, params: [String : Any]?) {
        
    }
    
    func appProfileEditEvent(eventName: String?, params: [String : Any]?) {
        
    }
    
    func appExitEvent(eventName: String?, params: [String : Any]?) {
        
    }
    
    func appClickHashtagEvent(eventName: String?, params: [String : Any]?) {
        
    }
    
    func appClickSoundTrackEvent(eventName: String?, params: [String : Any]?) {
        
    }
    
    func appContentMuteEvent(eventName: String?, params: [String : Any]?) {
        
    }
    
    func appContentUnmuteEvent(eventName: String?, params: [String : Any]?) {
        
    }
    
    func didSelectBack() {
        
    }
    
    func onGluedInShareAction(shareData: GluedInCoreSDK.ShareData, viewController: UIViewController?) {
        let subDomain = "gluedinvertical.page.link"
        let urlStringWithQueryItems = "https://\(subDomain)/data?\(shareData.deeplink)"
        guard let urlToShare = URL(string: urlStringWithQueryItems) else {
            print("Invalid URL(s)")
            return
        }
        // Prepare the items to share
        let itemsToShare: [Any] = [urlToShare]
        // No thumbnail, just present the URL
        let activityViewController = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        viewController?.present(activityViewController, animated: true, completion: nil)
    }
    
    func appSkipLoginEvent(device_ID: String, platform_name: String, page_name: String) {
        
    }
    
    func didSelectParentApp() {
        
    }
    
    func appTabClickEvent(Journey_entry_point: String, device_ID: String, user_email: String, user_name: String, user_id: String, platform_name: String, page_name: String, tab_name: String, button_type: String, cta_name: String, gluedIn_version: String, played_duration: String, content_creator_id: String, video_duration: String) {
        
    }
    
    func appRegisterCTAClickEvent(device_ID: String, user_email: String, user_name: String, user_isFollow: String, user_following_count: String, user_follower_count: String, platform_name: String, page_name: String) {
        
    }
    
    func appLoginCTAClickEvent(device_ID: String, user_email: String, user_name: String, user_id: String, user_isFollow: String, user_following_count: String, user_follower_count: String, platform_name: String, page_name: String, tab_name: String, button_type: String, cta_name: String, gluedIn_version: String, content_creator_id: String, video_duration: String) {
        
    }
    
    func callClientSignInView() {
        
    }
    
    func callClientSignUpView() {
        
    }
    
    func appLaunchEvent(email: String, username: String, userId: String, version: String, deviceID: String, platformName: String) {
        
    }
    
    func appSearchButtonClickEvent(eventName: String?, params: [String : Any]?) {
        
    }
    
    func appCreatorRecordingDoneEvent() {
        
    }
    
    func appPopupLaunchEvent(device_ID: String, user_email: String, user_name: String, platform_name: String, page_name: String, tab_name: String, popup_name: String, cta_name: String, user_id: String, gluedIn_version: String, content_creator_id: String, video_duration: String) {
        
    }
    
    func appPopupCTAsEvent(device_ID: String, user_email: String, user_name: String, user_id: String, platform_name: String, page_name: String, tab_name: String, element: String, button_type: String, popup_name: String, cta_name: String, gluedIn_version: String, played_duration: String, content_creator_id: String, video_duration: String) {
        
    }
    
    func onUserProfileClick(userId: String) {
        
    }
    
    func didClickReward(navigationController: UINavigationController?) {
        
    }
    
    func onPostKeepShoppingClick(navigationController: UINavigationController?) {
        
    }
    
    func onPaywallActionClicked(seriesId: String?, currentEpisode: Int?, deeplink: String?, navigationController: UINavigationController?) {
        
    }
    
    func onWatchNowAction(deeplink: String) {
        
    }
}
