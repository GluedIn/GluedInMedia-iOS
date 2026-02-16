//
//  HomeVC.swift
//  MediaSampleApp
//
//  Created by Abhishek Mishra on 04/09/25.
//

import UIKit
import AVKit
import GluedInCoreSDK
import GluedInFeedSDK
import GluedInSDK
import MobileBuySDK
import GoogleMobileAds
import StoreKit

/// Home screen that renders curated rails/series/stories and wires GluedIn SDK + Shopify flows.
class HomeVC: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var homeTableView: UITableView!

    // MARK: - Data Source
    /// Static row heights for the table layout.
    let listArr = CellHeights.mediaList
    /// Section titles (mutated when rail names arrive).
    var mediaSectionTitle: [String] = CellHeights.mediaSectionTitle

    // MARK: - GluedIn SDK Properties
    /// Builder used to configure and launch GluedIn SDK entry points.
    var gluedinBuilder: GluedInLaunchBuilder?
    /// Curated rail items for subfeed.
    var railData: GluedInCoreSDK.CurationDataSeeAllModel?
    /// Curated series rail.
    var SeriesData: GluedInCoreSDK.CurationDataSeeAllModel?
    /// Curated story rail.
    var StoryData: GluedInCoreSDK.CurationDataSeeAllModel?
    
    var seriesId: String?
    var assetId: String?
    var packageId: String?
    var skuId: String?
    var paymentUrl: String?
    var userId: String?
    var paymentType: PaymentMethod = .inAppPurchase
    var gadNativeAd: NativeAd?
    var gadCustomNativeAd: CustomNativeAd?
 
    // MARK: - Shopify (Storefront API via MobileBuySDK)
    /// GraphQL Storefront client configured with shop domain + access token.
    let shopifyClient = Graph.Client(
        shopDomain: ShopifyConfig.shopDomain,
        apiKey: ShopifyConfig.accessToken
    )
    
    /// UserDefaults keys for persisting cart identifiers/URLs.
    private let kShopifyCartIdKey = "gi.shopify.cartId"
    private let kShopifyCartUrlKey = "gi.shopify.cartUrl"
    
    // MARK: - Shopify Cart (Storefront API-backed)
    //
    // Persist cart details in UserDefaults so they survive app restarts.
    // Accessing these properties always reads the saved values.
    
    /// The current Shopify cart GID (e.g., "gid://shopify/Cart/...").
    private var shopifyCartId: String? {
        get { UserDefaults.standard.string(forKey: kShopifyCartIdKey) }
        set {
            if let v = newValue, !v.isEmpty {
                UserDefaults.standard.set(v, forKey: kShopifyCartIdKey)
            } else {
                UserDefaults.standard.removeObject(forKey: kShopifyCartIdKey)
            }
        }
    }
    
    /// Last-known cart URL; may be a cart permalink or checkout URL depending on flow.
    private var shopifyCartUrl: String? {
        get { UserDefaults.standard.string(forKey: kShopifyCartUrlKey) }
        set {
            if let v = newValue, !v.isEmpty {
                UserDefaults.standard.set(v, forKey: kShopifyCartUrlKey)
            } else {
                UserDefaults.standard.removeObject(forKey: kShopifyCartUrlKey)
            }
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.fetchAllCurationData()
    }

    // MARK: - IBActions
    /// Launches the GluedIn SDK feed via button action using the prepared builder.
    @IBAction func feedLaunchAction(_ sender: Any) {
        launchSDKWithCustomParameter()
    }

    // MARK: - TableView Setup
    /// Registers cells and assigns table view delegate/data source.
    private func setupTableView() {
        homeTableView.delegate = self
        homeTableView.dataSource = self

        homeTableView.register(UINib(nibName: CellIdentifier.headingCell, bundle: nil), forCellReuseIdentifier: CellIdentifier.headingCell)
        homeTableView.register(UINib(nibName: CellIdentifier.mainCell, bundle: nil), forCellReuseIdentifier: CellIdentifier.mainCell)
        homeTableView.register(UINib(nibName: CellIdentifier.mediaCollectionCell, bundle: nil), forCellReuseIdentifier: CellIdentifier.mediaCollectionCell)
        homeTableView.register(UINib(nibName: CellIdentifier.StoryCell, bundle: nil), forCellReuseIdentifier: CellIdentifier.StoryCell)
    }

    // MARK: - SDK Launch
    /// Configures and launches the GluedIn SDK, pushing the resulting controller.
    private func launchSDKWithCustomParameter() {
        gluedinBuilder = GluedInLaunchBuilder()
            .setApiAndSecret(SDKEnvironment.apiKey, SDKEnvironment.secretKey)
            .setApiServerUrl(SDKEnvironment.serverUrl)
            .setUserInfo(email: SDKEnvironment.email, password: SDKEnvironment.password, fullName: SDKEnvironment.name, profilePhoto: "")
            .setUserPersona("")
            .setAdsCustomParams([GAMExtraParams(key: "App", value: "")])
            .setFeedType(.vertical)
            .setDelegate(self)
            .build()

        gluedinBuilder?.launch { [weak self] controller in
            if let controller = controller {
                self?.navigationController?.pushViewController(controller, animated: true)
            }
        } authenticationfailure: { error, code in
            print("Auth Failed: \(error) \(code)")
        } sdkInitializationFailure: { error, code in
            print("SDK Init Failed: \(error) \(code)")
        }
    }

    /// Initializes the GluedIn SDK and executes completion indicating success.
    private func initializeSDK(completion: @escaping (Bool) -> Void) {
        gluedinBuilder = GluedInLaunchBuilder()
            .setApiAndSecret(SDKEnvironment.apiKey, SDKEnvironment.secretKey)
            .setApiServerUrl(SDKEnvironment.serverUrl)
            .setUserInfo(email: SDKEnvironment.email, password: SDKEnvironment.password, fullName: SDKEnvironment.name, profilePhoto: SDKEnvironment.profileUrl)
            .setFeedType(.vertical)
            .setDelegate(self)
            .build()

        gluedinBuilder?.launch { controller in
            completion(true)
        } authenticationfailure: { error, code in
            print("Auth Failed: \(error) \(code)")
        } sdkInitializationFailure: { error, code in
            print("SDK Init Failed: \(error) \(code)")
        }
    }

    // MARK: - Curation Data (Fetch all)
    /// Fetches rails → series → story curation data sequentially and reloads after each.
    func fetchAllCurationData() {
        self.getCuratedData(railId: ConstantRailIds.rail, type: .rail) {
            self.homeTableView.reloadData()
            self.getCuratedData(railId: ConstantRailIds.series, type: .series) {
                self.homeTableView.reloadData()
                self.getCuratedData(railId: ConstantRailIds.story, type: .story) {
                    self.homeTableView.reloadData()
                }
            }
        }
    }

    /// Supported curated rail categories to simplify branching.
    private enum RailType { case rail, series, story }
    
    // MARK: - Get Curation Data API
    /// Initializes the Core SDK and fetches curated rail details for a given rail ID.
    /// - Parameters:
    ///   - railId: The rail identifier configured in console.
    ///   - type: Which rail bucket this call serves (rail/series/story).
    ///   - completion: Invoked after state is updated (success/failure).
    private func getCuratedData(railId: String, type: RailType, completion: @escaping () -> Void) {
        GluedInCore.shared.initSdk(
            apiKey: SDKEnvironment.apiKey,
            secretKey: SDKEnvironment.secretKey
        ) {
            DiscoverData.sharedInstance.getCuratedRailDetails(railId: railId) { [weak self] model in
                guard let self = self else { completion(); return }

                switch type {
                case .rail:
                    self.railData = model
                    self.mediaSectionTitle[2] = model.result?.railName ?? ""
                case .series:
                    self.SeriesData = model
                    self.mediaSectionTitle[6] = model.result?.railName ?? ""
                case .story:
                    self.StoryData = model
                    self.mediaSectionTitle[10] = model.result?.railName ?? "Latest Story"
                }
                completion()
            } failure: { error, code in
                print("Rail Fetch Failed: \(error) - \(code)")
                completion()
            }
        } failure: { error, code in
            print("Rail Fetch Failed: \(error) - \(code)")
            completion()
        }
    }

    // MARK: - Launch GluedIn Video
    /// Helper that ensures SDK initialization, then pushes the requested entry point.
    /// - Parameters:
    ///   - entry: Story/Series/SubFeed entry type.
    ///   - id: Selected content/series ID.
    ///   - contentIds: Optional peer content IDs for carousel context.
    private func launchGluedIn(entry: GluedInSDK.EntryPoint, id: String, contentIds: [String] = []) {
        initializeSDK { [weak self] success in
            guard let self = self, success else { return }
            
            let pushVC: (UIViewController?) -> Void = { controller in
                if let vc = controller {
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
            switch entry {
            case .story:
                // Story: open rail as shorts subfeed with selected story id
                launchRail(videoId: id, contentIds: contentIds, onlyShortsSubFeed: true, entryPoint: .story)

            case .series:
                // Series: open series rail with episode selection
                launchRail(seriesId: id, selectedEpisodeNumber: 0, onlyShortsSubFeed: true)
                
            case .subFeed:
                // SubFeed: open standard rail carousel with selected video id
                launchRail(videoId: id, contentIds: contentIds, onlyShortsSubFeed: false)
                
            default:
                break
            }
        }
    }
    
    /// Unified launcher for different GluedIn rail entry scenarios.
    /// - Parameters:
    ///   - videoId: Selected video ID if launching a content carousel.
    ///   - contentIds: Carousel context list.
    ///   - seriesId: Series identifier if launching series entry.
    ///   - selectedEpisodeNumber: Start episode index for series.
    ///   - onlyShortsSubFeed: If `true`, restricts to shorts-only subfeed.
    ///   - entryPoint: Specific entry point (default `.none`).
    func launchRail(
        videoId: String? = nil,
        contentIds: [String]? = nil,
        seriesId: String? = nil,
        selectedEpisodeNumber: Int? = nil,
        onlyShortsSubFeed: Bool = false,
        entryPoint: EntryPoint = .none
    ) -> () {
        gluedinBuilder = GluedInLaunchBuilder()
            .setApiAndSecret(SDKEnvironment.apiKey, SDKEnvironment.secretKey)
            .setApiServerUrl(SDKEnvironment.serverUrl)
            .setUserInfo(email: SDKEnvironment.email, password: SDKEnvironment.password, fullName: SDKEnvironment.name, profilePhoto: "")
            .setCarouselDetails(selectedRailContentId: videoId, railContentIds: contentIds, onlyShortsSubFeed: onlyShortsSubFeed, entryPoint: entryPoint)
            .setSeriesInfo(seriesId: seriesId, selectedEpisodeNumber: selectedEpisodeNumber, onlyShortsSubFeed: onlyShortsSubFeed)
            .setDelegate(self)
            .setFeedType(.vertical)
            .setDiscoverAsHome(false, .embedded)
            .build()
        
        gluedinBuilder?.launch { [weak self] controller in
            guard let self = self else { return }
            if let controller = controller {
                self.navigationController?.pushViewController(controller, animated: true)
            }
        } authenticationfailure: { error, code in
            print("Auth Failed: \(error) \(code)")
        } sdkInitializationFailure: { error, code in
            print("SDK Init Failed: \(error) \(code)")
        }
    }
}

// MARK: - UITableView Delegate & DataSource
extension HomeVC: UITableViewDelegate, UITableViewDataSource {
    
    /// Number of rows equals configured layout rows.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listArr.count
    }
    
    /// Height per row based on static layout config.
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(listArr[indexPath.row])
    }
    
    /// Example selection routing to video details for row 1.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 1 {
            let storyboard = UIStoryboard(name: storyName.main, bundle: nil)
            if let vc = storyboard.instantiateViewController(withIdentifier: storyName.videoDetailsVC) as? VideoDetailsVC {
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    /// Dequeues and configures cell types based on target height.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellHeight = listArr[indexPath.row]
        
        switch cellHeight {
        case 145:
            let cell =  tableView.dequeueReusableCell(withIdentifier: CellIdentifier.mainCell, for: indexPath) as? MainCell ?? UITableViewCell()
            cell.selectionStyle = .none
            return cell
        case 44:
            let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.headingCell, for: indexPath) as? HeadingCell
            cell?.titleLabel.text = mediaSectionTitle[indexPath.row]
            cell?.selectionStyle = .none
            return cell ?? UITableViewCell()
        case 192, 106, 190:
            let cell = configureCollectionCell(for: indexPath)
            cell.selectionStyle = .none
            return cell
        case 85:
            let cell = configureStoryCollectionCell(for: indexPath)
            cell.selectionStyle = .none
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    /// Configures media collection cell for rails/series (or gray placeholders).
    private func configureCollectionCell(for indexPath: IndexPath) -> UITableViewCell {
        guard let cell = homeTableView.dequeueReusableCell(withIdentifier: CellIdentifier.mediaCollectionCell, for: indexPath) as? MediaCollectionCell else {
            return UITableViewCell()
        }
        
        cell.isGrayCell = false
        switch indexPath.row {
        case 3:
            cell.railData = railData
            cell.entryPoint = .subFeed
        case 7:
            cell.railData = SeriesData
            cell.entryPoint = .series
        default:
            cell.cellHeight = listArr[indexPath.row]
            cell.cellWidth = CellHeights.cellWidthArr[indexPath.row]
            cell.isGrayCell = true
        }
        
        cell.delegate = self
        return cell
    }
    
    /// Configures story rail cell (or gray placeholder if empty).
    private func configureStoryCollectionCell(for indexPath: IndexPath) -> UITableViewCell {
        guard let cell = homeTableView.dequeueReusableCell(withIdentifier: CellIdentifier.StoryCell, for: indexPath) as? StoryCell else {
            return UITableViewCell()
        }
        
        cell.cellHeight = listArr[indexPath.row]
        cell.cellWidth = CellHeights.cellWidthArr[indexPath.row]
        
        if StoryData?.result?.itemList?.count ?? 0 > 0 {
            cell.railData = StoryData
            cell.entryPoint = .story
        } else {
            cell.isGrayCell = true
        }
        cell.delegate = self
        return cell
    }
}

// MARK: - GluedIn Video Selection Delegate
extension HomeVC: VideoSelectionDelegate {
    /// Receives item tap from collection cells and routes to the right SDK entry.
    func didSelectVideo(with id: String, entryPoint: GluedInSDK.EntryPoint) {
        switch entryPoint {
        case .story:
            let contentIds = StoryData?.result?.itemList?.compactMap { $0.assetId } ?? []
            launchGluedIn(entry: .story, id: id, contentIds: contentIds)
        case .series:
            launchGluedIn(entry: .series, id: id)
        case .subFeed:
            let contentIds = railData?.result?.itemList?.compactMap { $0.video?.videoId } ?? []
            launchGluedIn(entry: .subFeed, id: id, contentIds: contentIds)
        default:
            break
        }
    }
}

// MARK: - GluedInDelegate (Commerce, Analytics, Share, Ads stubs)
extension HomeVC : GluedInDelegate {
    func showAutoRenewalSubscribtion(viewController: UIViewController?) {
        print("GluedInDelegate method callback --> \(#function)")
        if #available(iOS 15.0, *) {
            // ✅ Apple native subscription screen
            if let scene = viewController?.view.window?.windowScene {
                Task { @MainActor in
                    do {
                        try await AppStore.showManageSubscriptions(in: scene)
                    } catch {
                        // Fallback if Apple API fails
                        openSubscriptionsURL()
                    }
                }
            } else {
                openSubscriptionsURL()
            }
        } else {
            // ❌ iOS 12–14: URL is the ONLY option
            openSubscriptionsURL()
        }
    }
    
    func openSubscriptionsURL() {
        guard let url = URL(string: "https://apps.apple.com/account/subscriptions") else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    func onInitiateSeriesPurchase(paymentType: PaymentMethod, inAppSkuId: String?, purchaseUrl: String?, seriesId: String?, packageId: String?, episodeNumber: Int?, userId: String?, controller: UIViewController?) {
        self.userId = userId
        self.seriesId = seriesId
        self.skuId = inAppSkuId
        self.paymentUrl = purchaseUrl
        self.paymentType = paymentType
        self.packageId = packageId
        
        switch paymentType {
            
        case .inAppPurchase, .inAppPurchaseSubscription:
            guard let id = skuId, !id.isEmpty else { return }
            guard SKPaymentQueue.canMakePayments() else {
                GluedIn.shared.notifyPaymentResult(
                    status: .paymentFailed,
                    transactionId: nil,
                    seriesId: seriesId,
                    skuId: skuId,
                    paymenyUrl: paymentUrl,
                    packageId: packageId,
                    paymentType: paymentType
                )
                return
            }

            if #available(iOS 15.0, *) {
                startObservingStoreKit2IfNeeded()
                purchaseStoreKit2(productId: id, userId: userId)
            } else {
                // ✅ existing SK1 flow
                let set: Set<String> = [id]
                let productsRequest = SKProductsRequest(productIdentifiers: set)
                productsRequest.delegate = self
                productsRequest.start()
            }

        case .paymentGateway:
            if let urlString = paymentUrl {
                ToastManager.shared.showToast(text: "onInitiateSeriesPurchase => Link - \(urlString)")
            }

        case .subscription:
            ToastManager.shared.showToast(
                text: "\(#function) => seriesId - \(seriesId ?? "no series") Link - \(purchaseUrl ?? "no link")"
            )
        }
    }
    
    func onFetchPrice(productIDs: [String]?, paymentType: GluedInCoreSDK.PaymentMethod, completion: @escaping (Any?) -> Void, onError: @escaping ((any Error)?) -> Void) {
        guard let productIDs = productIDs, !productIDs.isEmpty else {
            completion(nil)
            return
        }

        switch paymentType {
        case .inAppPurchase:
            IAPManager.shared.fetchPrices(for: productIDs) { infos in
                DispatchQueue.main.async { completion(infos) }
            } onError: { err in
                DispatchQueue.main.async { onError(err) }
            }

        case .inAppPurchaseSubscription:
            IAPManager.shared.fetchSubscriptionInfos(for: productIDs) { infos in
                DispatchQueue.main.async { completion(infos) }
            } onError: { err in
                DispatchQueue.main.async { onError(err) }
            }

        case .paymentGateway, .subscription:
            completion(nil)
        }
    }
    
    /* Reward Intertial Ads implementation */
    func onRewardedAdRequested(
        viewController: UIViewController?,
        adsType: AdsType,
        adUnitID: String?,
        customParmas: [GAMExtraParams]?,
        seriesId: String?
    ) {
        if let adId = adUnitID {
            GluedIn.shared.logAds(type: .adMobRewardedInterstitial, status: .impression, error: nil, seriesId: seriesId, assetId: assetId)
            GADRewardedInterstitialManager.shared.loadRewardedInterstitial(adUnitID: adId) { [weak self] didCompleted in
                guard let weakSelf = self else { return }
                if let controller = viewController {
                    weakSelf.seriesId = seriesId
                    weakSelf.assetId = adUnitID
                    weakSelf.showRewardInterstitialAds(view: controller)
                    GluedIn.shared.logAds(type: .adMobRewardedInterstitial, status: .completed, error: nil, seriesId: seriesId, assetId: adUnitID)
                }
            } didCompleteWithError: { didCompleteWithError in
                GluedIn.shared.logAds(type: .adMobRewardedInterstitial, status: .failed, error: "\(didCompleteWithError)", seriesId: seriesId, assetId: "")
            }
        }
    }
    
    func showRewardInterstitialAds(view: UIViewController) {
        GADRewardedInterstitialManager.shared.showRewardedInterstitial(from: view) { [weak self] in
            guard let self = self else { return }
            GluedIn.shared.logAds(type: .adMobRewardedInterstitial, status: .showAds, error: nil, seriesId: seriesId, assetId: assetId)

        } didDismiss: { [weak self] in
            guard let self = self else { return }
            GluedIn.shared.logAds(type: .adMobRewardedInterstitial, status: .dismiss, error: nil, seriesId: self.seriesId, assetId: self.assetId)

        } didFailToPresent: { [weak self] didFailToPresentWithError in
            guard let self = self else { return }
            GluedIn.shared.logAds(type: .adMobRewardedInterstitial, status: .failed, error: "\(didFailToPresentWithError)", seriesId: seriesId, assetId: assetId)

        } earnReward: { [weak self] type, amount in
            guard let self = self else { return }
            GluedIn.shared.logAds(type: .adMobRewardedInterstitial, status: .earned, error: nil, seriesId: seriesId, assetId: assetId)
        }
    }
    
    /// Unified user action callback from SDK for commerce CTAs.
    /// - Parameters:
    ///   - action: .addToCart or .openBrowser
    ///   - assetId: Shopify Product GID for PDP flow
    ///   - productUrl: URL to open externally if action is openBrowser
    ///   - eventRefId: Reference Id for analytics mapping (if needed)
    ///   - navigationController: Host navigation stack to present UI
    func onUserAction(action: UserAction, assetId: String?, productUrl: String?, eventRefId: Int, navigationController: UINavigationController) {
        switch action {
        case .addToCart:
            guard let gid = assetId else { return }
            fetchProductDetails(productId: gid) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let product):
                        let bundle = Bundle(for: ProductDetailViewController.self)
                        let storyboard = UIStoryboard(
                            name: "ProductDetailStoryboard",
                            bundle: bundle)
                        guard let controller = storyboard.instantiateViewController(
                            withIdentifier: ProductDetailViewController.className
                        ) as? ProductDetailViewController else {
                            return
                        }
                        controller.product = product
                        controller.variants = product.variants
                        controller.delegate = self
                        controller.modalPresentationStyle = .overCurrentContext
                        navigationController.present(controller, animated: true, completion: nil)
                        
                    case .failure(_):
                        Alert.showToast(message: "Failure to fetch the product")
                    }
                }
            }
            
        case .openBrowser:
            // Client app can decide to push a web view or handoff to Safari.
            Alert.showToast(message: "\(productUrl ?? "")")
        }
    }
    
    // MARK: - Shopify Product (Single)
    /// Fetch a single Shopify product by its GID and map to `ProductVM`.
    /// - Parameter productId: Example "gid://shopify/Product/1234567890"
    func fetchProductDetails(
        productId: String,
        completion: @escaping (Result<ProductVM, Error>) -> Void
    ) {
        let query = makeProductByIdQuery(productId)
        
        let task  = shopifyClient.queryGraphWith(query) { [weak self] response, error in
            guard let self = self else { return }
            
            if let error {
                completion(.failure(error))
                return
            }
            
            // `node` is a union/interface; cast to Product (works across SDK versions)
            guard let productNode = response?.node as? MobileBuySDK.Storefront.Product else {
                let notFound = NSError(
                    domain: "Shopify",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "Product not found for id \(productId)"]
                )
                completion(.failure(notFound))
                return
            }
            
            let vm = self.mapProduct(productNode)
            completion(.success(vm))
        }
        task.resume()
    }
    
    /// GraphQL query builder for fetching a product by GID.
    func makeProductByIdQuery(_ productId: String) -> MobileBuySDK.Storefront.QueryRootQuery {
        let gid = GraphQL.ID(rawValue: productId)
        return Storefront.buildQuery { $0
            .node(id: gid) { $0
                .onProduct { $0
                    .id()
                    .title()
                    .handle()
                    .description()
                    .images(first: 1) { $0
                        .edges { $0
                            .node { $0
                                .url()
                                .altText()
                            }
                        }
                    }
                    .priceRange { $0
                        .minVariantPrice { $0
                            .amount()
                            .currencyCode()
                        }
                        .maxVariantPrice { $0
                            .amount()
                            .currencyCode()
                        }
                    }
                    .options(first: 20) { $0
                        .name()
                        .values()
                    }
                    .variants(first: 20) { $0
                        .edges { $0
                            .node { $0
                                .id()
                                .title()
                                .price { $0
                                    .amount()
                                    .currencyCode()
                                }
                                .availableForSale()
                                .image { $0
                                    .url()
                                    .altText()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Maps Storefront Product to lightweight `ProductVM` used by the app.
    private func mapProduct(_ node: MobileBuySDK.Storefront.Product) -> ProductVM {
        let firstImageURL: URL? = node.images.edges.first?.node.url
        let min = moneyString(node.priceRange.minVariantPrice)
        let max = moneyString(node.priceRange.maxVariantPrice)
        
        // Grab the first option name, or detect size-like option
        let optionNames = node.options.map { $0.name }
        let variantName: String? = optionNames.first  // or use a helper to prefer "Size"
        
        let variants = node.variants.edges.map { mapVariant($0.node, productImageURL: firstImageURL) }
        return ProductVM(
            id: node.id.rawValue,
            title: node.title,
            handle: node.handle,
            description: node.description,
            imageURL: firstImageURL,
            minPrice: min,
            maxPrice: max,
            variants: variants,
            variantName: variantName
        )
    }
    
    /// Maps Storefront ProductVariant to `VariantVM`.
    private func mapVariant(
        _ node: MobileBuySDK.Storefront.ProductVariant,
        productImageURL: URL?
    ) -> VariantVM {
        let variantImageURL: URL? = node.image?.url ?? productImageURL
        return VariantVM(
            id: node.id.rawValue,
            title: node.title,
            price: moneyString(node.price),
            available: node.availableForSale,
            imageURL: variantImageURL
        )
    }
    
    /// Formats MoneyV2 into "CUR 0.00" string.
    private func moneyString(_ money: MobileBuySDK.Storefront.MoneyV2) -> String {
        let amount = NSDecimalNumber(decimal: money.amount).doubleValue
        return String(format: "%@ %.2f", money.currencyCode.rawValue, amount)
    }
    
    /// Pushes the "Add To Cart" intermediate screen which can update quantities.
    func navigateToCart(viewController: UIViewController?) {
        let bundle = Bundle(for: AddToCartViewController.self)
        let storyboard = UIStoryboard(
            name: "AddToCartStoryboard",
            bundle: bundle)
        guard let controller = storyboard.instantiateViewController(
            withIdentifier: AddToCartViewController.className
        ) as? AddToCartViewController else {
            return
        }
        controller.shopifyCartId = shopifyCartId
        controller.shopifyCartUrl = shopifyCartUrl
        controller.parentView = viewController
        controller.delegate = self
        viewController?.navigationController?.pushViewController(controller, animated: false)
    }
    
    /// Generic web view opener with optional title; delegates lifecycle events back to this VC.
    func openWebView(url: String, title: String? = nil, viewController: UIViewController?) {
        let bundle = Bundle(for: WebViewController.self)
        let storyboard = UIStoryboard(
            name: "WebStoryboard",
            bundle: bundle)
        guard let controller = storyboard.instantiateViewController(
            withIdentifier: WebViewController.className
        ) as? WebViewController else {
            return
        }
        controller.url = url
        controller.navTitle = title
        controller.delegate = self
        viewController?.navigationController?.pushViewController(controller, animated: false)
    }
    
    /// Opens Shopify "My Orders" (Storefront Account) page inside the app web view.
    func showOrderHistory(viewController: UIViewController?) {
        let shop = ShopifyConfig.shopDomain
        let base = "https://\(shop)"
        let loginPath = "/account" // storefront login
        let urlString = base + loginPath
        openWebView(url: urlString, title: "My Orders", viewController: viewController)
    }
    
    /// Public surface for SDK to get latest cart count (delegates to fetchCartItemsQuantity).
    func getCartItemCount(completion: @escaping (Result<Int, any Error>) -> Void) {
         fetchCartItemsQuantity(completion: completion)
    }
    
    /// Queries Storefront cart.totalQuantity for the persisted cart ID.
    func fetchCartItemsQuantity(completion: @escaping (Result<Int, Error>) -> Void) {
        guard let id = shopifyCartId else {
            completion(.success(0))
            return
        }
        let q = Storefront.buildQuery { $0
            .cart(id: GraphQL.ID(rawValue: id)) { $0
                .id()
                .totalQuantity()
            }
        }
        let task = shopifyClient.queryGraphWith(q) { response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            let qty = response?.cart?.totalQuantity ?? 0
            completion(.success(Int(qty)))
        }
        task.resume()
    }
    
    // MARK: - Analytics placeholder hooks (intentionally empty)
    func appScreenViewEvent(pageName: String) {}
    func appViewClickEvent(device_ID: String, user_email: String, user_name: String, platform_name: String) {}
    func appLaunchEvent(deviceID: String, platformName: String) {}
    
    func requestForBannerAds(
        viewController: UIViewController?,
        adsType: AdsType,
        adUnitID: String?,
        customParmas: [GAMExtraParams]?,
        completion: @escaping (UIView?) -> Void
    ) {
        guard let adUnitID else {
            completion(nil)
            return
        }
        GADBannerManager.shared.loadBanner(adUnitID: adUnitID, viewController: viewController) { banner in
            completion(banner)
        }
    }
    
    func requestForInterstitialAds(viewController: UIViewController?, adsType: GluedInCoreSDK.AdsType, adUnitID: String?, customParmas: [GluedInCoreSDK.GAMExtraParams]?) {
        if let adId = adUnitID {
            GADInterstitialManager.shared.loadInterstitialAds(adUnitID: adId) { [weak self] didCompleted in
                guard let weakSelf = self else { return }
                if let controller = viewController {
                    weakSelf.getNativeAdControllerInter(view: controller)
                }
            } didCompleteWithError: { didCompleteWithError in
                Debug.Log(message: "Error - \(didCompleteWithError)")
            }
        }
    }
    
    func getNativeAdControllerInter(view: UIViewController) {
        GADInterstitialManager.shared.showInterstitialAds(
            view: view,
            didPresent: {
                debugPrint("In Present")
            },
            didDismiss: {
                debugPrint("didDismiss")
            },
            didFailToPresent: { didFailToPresentWithError in
                debugPrint("didFailToPresent")
            })
    }
    
    func requestForAdmobNativeAds(viewController: UIViewController?, adUnitID: String?, adsType: GluedInCoreSDK.AdsType, customParmas: [GluedInCoreSDK.GAMExtraParams]?) {
        if let adUnitID = adUnitID {
            GADNativeManager().fetchAdsNative(adUnitID: adUnitID) { [weak self] nativeAd in
                guard let weakSelf = self else { return }
                weakSelf.gadNativeAd = nativeAd
            } didFailedWithError: { error in
                Debug.Log(message: "Error - \(error)")
            }
        }
    }
    func getAdmobNativeAdsController() -> UIViewController? {
        guard let ads = gadNativeAd else { return nil }
        let bundle = Bundle(for: NativeAdVerticalViewController.self)
        let storyboard = UIStoryboard(
            name: "NativeAdVerticalView",
            bundle: bundle)
        guard let controller = storyboard.instantiateViewController(
            withIdentifier: NativeAdVerticalViewController.className
        ) as? NativeAdVerticalViewController else {
            return UIViewController()
        }
        controller.NativeAds = ads
        return controller
    }
    func getNativeAdNibName() -> String { return "" }
    func requestNativeAdCell() -> UITableViewCell { return UITableViewCell() }
    
    func requestForGamNativeAds(adUnitID: String?, adsType: GluedInCoreSDK.AdsType, configParams: [String : String]?, extraParams: [GluedInCoreSDK.GAMExtraParams]?, adsFormatId: [String]?) {
        DispatchQueue.main.async {
            GADNativeManager().loadNativeAds(
                configParams: configParams,
                gamExtraParams: extraParams,
                adUnitID: adUnitID,
                adsFormatId: adsFormatId
            ) { [weak self] customNativeAd in
                guard let weakSelf = self else { return }
                weakSelf.gadCustomNativeAd = customNativeAd
            } didFailedWithError: { error in
                debugPrint("error", error)
            }
        }
    }
    
    func getGamNativeAdsController() -> UIViewController? {
        guard let ads = gadCustomNativeAd else { return nil }
        let bundle = Bundle(for: NativeAdVerticalViewController.self)
        let storyboard = UIStoryboard(
            name: "NativeAdVerticalView",
            bundle: bundle)
        guard let controller = storyboard.instantiateViewController(
            withIdentifier: NativeAdVerticalViewController.className
        ) as? NativeAdVerticalViewController else {
            return UIViewController()
        }
        controller.customNativeAds = ads
        return controller
    }
    
    func onAnalyticsEvent(name: String, properties: [String : Any]) {}
    func appScreenViewEvent(journeyEntryPoint: String, pageName: String) {}
    func appViewMoreEvent(Journey_entry_point: String, device_ID: String, user_email: String, user_name: String, platform_name: String, page_name: String, tab_name: String, element: String, button_type: String) {}
    func appContentUnLikeEvent(eventName: String?, params: [String : Any]?) {}
    func appContentLikeEvent(eventName: String?, params: [String : Any]?) {}
    func appVideoReplayEvent(eventName: String?, params: [String : Any]?) {}
    func appSessionEvent(eventName: String?, params: [String : Any]?) {}
    func appVideoPlayEvent(eventName: String?, params: [String : Any]?) {}
    func appContentSwipeEvent(eventName: String?, params: [String : Any]?) {}
    func appVideoPauseEvent(eventName: String?, params: [String : Any]?) {}
    func appVideoResumeEvent(eventName: String?, params: [String : Any]?) {}
    func appCommentsViewedEvent(eventName: String?, params: [String : Any]?) {}
    func appCommentedEvent(eventName: String?, params: [String : Any]?) {}
    func appContentNextEvent(eventName: String?, params: [String : Any]?) {}
    func appContentPreviousEvent(eventName: String?, params: [String : Any]?) {}
    func appVideoStopEvent(device_ID: String, content_id: String, user_email: String, user_name: String, user_id: String, platform_name: String, page_name: String, tab_name: String, creator_userid: String, creator_username: String, hashtag: String, content_type: String, gluedIn_version: String, played_duration: String, content_creator_id: String, dialect_id: String, dialect_language: String, genre: String, genre_id: String, shortvideo_labels: String, video_duration: String, feed: GluedInCoreSDK.FeedModel?) {}
    func appViewClickEvent(device_ID: String, user_email: String, user_name: String, user_id: String, platform_name: String, page_name: String, tab_name: String, content_type: String, button_type: String, cta_name: String, gluedIn_version: String, feed: GluedInCoreSDK.FeedModel?) {}
    func appUserFollowEvent(eventName: String?, params: [String : Any]?) {}
    func appCTAClickedEvent(eventName: String?, params: [String : Any]?) {}
    func appProfileEditEvent(eventName: String?, params: [String : Any]?) {}
    func appExitEvent(eventName: String?, params: [String : Any]?) {}
    func appClickHashtagEvent(eventName: String?, params: [String : Any]?) {}
    func appClickSoundTrackEvent(eventName: String?, params: [String : Any]?) {}
    func appContentMuteEvent(eventName: String?, params: [String : Any]?) {}
    func appContentUnmuteEvent(eventName: String?, params: [String : Any]?) {}
    func didSelectBack() {}
    /// System share sheet for GluedIn share data (deeplink-based).
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
    func appSkipLoginEvent(device_ID: String, platform_name: String, page_name: String) {}
    func didSelectParentApp() {}
    func appTabClickEvent(Journey_entry_point: String, device_ID: String, user_email: String, user_name: String, user_id: String, platform_name: String, page_name: String, tab_name: String, button_type: String, cta_name: String, gluedIn_version: String, played_duration: String, content_creator_id: String, video_duration: String) {}
    func appRegisterCTAClickEvent(device_ID: String, user_email: String, user_name: String, user_isFollow: String, user_following_count: String, user_follower_count: String, platform_name: String, page_name: String) {}
    func appLoginCTAClickEvent(device_ID: String, user_email: String, user_name: String, user_id: String, user_isFollow: String, user_following_count: String, user_follower_count: String, platform_name: String, page_name: String, tab_name: String, button_type: String, cta_name: String, gluedIn_version: String, content_creator_id: String, video_duration: String) {}
    func callClientSignInView() {}
    func callClientSignUpView() {}
    func appLaunchEvent(email: String, username: String, userId: String, version: String, deviceID: String, platformName: String) {}
    func appSearchButtonClickEvent(eventName: String?, params: [String : Any]?) {}
    func appCreatorRecordingDoneEvent() {}
    func appPopupLaunchEvent(device_ID: String, user_email: String, user_name: String, platform_name: String, page_name: String, tab_name: String, popup_name: String, cta_name: String, user_id: String, gluedIn_version: String, content_creator_id: String, video_duration: String) {}
    func appPopupCTAsEvent(device_ID: String, user_email: String, user_name: String, user_id: String, platform_name: String, page_name: String, tab_name: String, element: String, button_type: String, popup_name: String, cta_name: String, gluedIn_version: String, played_duration: String, content_creator_id: String, video_duration: String) {}
    func onUserProfileClick(userId: String) {}
    func didClickReward(navigationController: UINavigationController?) {}
    func onPostKeepShoppingClick(navigationController: UINavigationController?) {}
    func onPaywallActionClicked(seriesId: String?, currentEpisode: Int?, deeplink: String?, navigationController: UINavigationController?) {}
    func onWatchNowAction(deeplink: String) {}
}

// MARK: - ProductDetailViewDelegate (Add to Cart -> Cart URL log + stage)
extension HomeVC: ProductDetailViewDelegate {
    
    /// User tapped "Add to Cart" on PDP: add variant to cart, persist cart URL, and log stage.
    func onTapAddToCart(product: VariantVM?) {
        if let productId = product?.id {
            addVariantToShopifyCart(
                variantId: productId
            ) { [weak self] result in
                guard let weakSelf = self else { return }
                switch result {
                case .success(let info):
                    // Store the cart URL (not the checkout URL)
                    let cartId = info.checkoutUrl.components(separatedBy: "/cart/").last
                    weakSelf.shopifyCartUrl = "https://\(ShopifyConfig.shopDomain)/cart/\(cartId ?? "")"
                    GluedIn.shared.logShoppingStage(Stage: .addToCart, status: true, error: nil)
                    
                case .failure(let error):
                    print(error)
                    GluedIn.shared.logShoppingStage(Stage: .addToCart, status: false, error: error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Shopify Cart Mutations
    /// Adds a ProductVariant to the current cart (creates cart if missing).
    /// - Parameters:
    ///   - variantId: `gid://shopify/ProductVariant/...`
    ///   - quantity: Quantity to add (default 1)
    ///   - completion: Returns checkoutUrl and totalQuantity after mutation
    func addVariantToShopifyCart(
        variantId: String,
        quantity: Int32 = 1,
        completion: @escaping (Result<(checkoutUrl: String, totalQuantity: Int32), Error>) -> Void
    ) {
        createCartIfNeeded { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let err):
                completion(.failure(err))
            case .success(let info):
                let cartGID = GraphQL.ID(rawValue: info.cartId)

                // Build line input
                let line = Storefront.CartLineInput.create(
                    merchandiseId: GraphQL.ID(rawValue: variantId),
                    quantity: Input.value(quantity)
                )

                let mutation = Storefront.buildMutation { $0
                    .cartLinesAdd(cartId: cartGID, lines: [line]) { $0
                        .cart { $0
                            .id()
                            .checkoutUrl()
                            .totalQuantity()
                        }
                        .userErrors { $0
                            .field()
                            .message()
                        }
                    }
                }

                let task = self.shopifyClient.mutateGraphWith(mutation) { response, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    guard
                        let added = response?.cartLinesAdd,
                        let cart = added.cart
                    else {
                        let msg = response?.cartLinesAdd?.userErrors.first?.message ?? "Failed to add line to cart."
                        completion(.failure(NSError(domain: "Shopify", code: 0, userInfo: [NSLocalizedDescriptionKey: msg])))
                        return
                    }
                    // Update local cart id if necessary
                    self.shopifyCartId = cart.id.rawValue
                    completion(.success((cart.checkoutUrl.absoluteString, cart.totalQuantity)))
                }
                task.resume()
            }
        }
    }
    
    /// Ensures a cart exists, creating one if needed, and returns identifiers.
    /// - Returns: `cartId`, `checkoutUrl`, and `totalQuantity`
    func createCartIfNeeded(
        completion: @escaping (
            Result<(
                cartId: String,
                checkoutUrl: String,
                totalQuantity: Int32),
            Error>) -> Void
    ) {
        if let cartId = shopifyCartId {
            // We don't fetch; we just surface what we have. Caller can proceed to add lines.
            completion(.success((cartId, "", 0))) // checkoutUrl/quantity will be refreshed on add
            return
        }

        let mutation = Storefront.buildMutation { $0
            .cartCreate(input: Storefront.CartInput.create()) { $0
                .cart { $0
                    .id()
                    .checkoutUrl()
                    .totalQuantity()
                }
                .userErrors { $0
                    .field()
                    .message()
                }
            }
        }

        let task = shopifyClient.mutateGraphWith(mutation) { [weak self] response, error in
            guard let self = self else { return }
            if let error = error {
                completion(.failure(error))
                return
            }
            guard
                let cartCreate = response?.cartCreate,
                let cart = cartCreate.cart
            else {
                let msg = response?.cartCreate?.userErrors.first?.message ?? "Failed to create cart."
                completion(.failure(NSError(domain: "Shopify", code: 0, userInfo: [NSLocalizedDescriptionKey: msg])))
                return
            }
            let id = cart.id.rawValue
            self.shopifyCartId = id
            self.shopifyCartUrl = cart.checkoutUrl.absoluteString
            completion(.success((id, cart.checkoutUrl.absoluteString, cart.totalQuantity)))
        }
        task.resume()
    }
}

// MARK: - AddToCartDelegate (Checkout handoff)
extension HomeVC: AddToCartDelegate {
    
    /// User chose to proceed to checkout from the cart screen.
    /// Opens the last-known `shopifyCartUrl` in the app web view.
    func onTapCheckout(carts: [CartLineVM]?, view: UIViewController?) {
        if let shopifyCartUrl = self.shopifyCartUrl {
            openWebView(url: shopifyCartUrl, title: "Checkout", viewController: view)
        }
    }
}

// MARK: - WebViewControllerDelegate (lifecycle hooks)
extension HomeVC: WebViewControllerDelegate {
    
    /// Called when embedded webview finishes; logs exit stages for checkout/orders.
    func didFinish(title: String?) {
        switch title {
        case "Checkout":
            GluedIn.shared.logShoppingStage(Stage: .checkoutExit, status: true, error: nil)
        case "My Orders":
            GluedIn.shared.logShoppingStage(Stage: .myOrderExit, status: true, error: nil)
        default:
            break
        }
    }
}

extension HomeVC: SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {

            case .purchasing:
                GluedIn.shared.notifyPaymentResult(
                    status: .paymentStarted,
                    transactionId: transaction.transactionIdentifier,
                    seriesId: seriesId,
                    skuId: skuId,
                    paymenyUrl: paymentUrl,
                    packageId: packageId,
                    paymentType: paymentType
                )

            case .purchased:
                SKPaymentQueue.default().finishTransaction(transaction)
                GluedIn.shared.notifyPaymentResult(
                    status: .paymentSuccess,
                    transactionId: transaction.transactionIdentifier,
                    seriesId: seriesId,
                    skuId: skuId,
                    paymenyUrl: paymentUrl,
                    packageId: packageId,
                    paymentType: paymentType
                )

            case .failed:
                SKPaymentQueue.default().finishTransaction(transaction)
                GluedIn.shared.notifyPaymentResult(
                    status: .paymentFailed,
                    transactionId: transaction.transactionIdentifier,
                    seriesId: seriesId,
                    skuId: skuId,
                    paymenyUrl: paymentUrl,
                    packageId: packageId,
                    paymentType: paymentType
                )

            case .restored:
                SKPaymentQueue.default().finishTransaction(transaction)
                GluedIn.shared.notifyPaymentResult(
                    status: .paymentRestored,
                    transactionId: transaction.transactionIdentifier,
                    seriesId: seriesId,
                    skuId: skuId,
                    paymenyUrl: paymentUrl,
                    packageId: packageId,
                    paymentType: paymentType
                )

            case .deferred:
                GluedIn.shared.notifyPaymentResult(
                    status: .paymentDeferred,
                    transactionId: transaction.transactionIdentifier,
                    seriesId: seriesId,
                    skuId: skuId,
                    paymenyUrl: paymentUrl,
                    packageId: packageId,
                    paymentType: paymentType
                )

            @unknown default:
                break
            }
        }
    }

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if let oProduct = response.products.first {
            purchase(aProduct: oProduct)
        } else {
            GluedIn.shared.notifyPaymentResult(
                status: .paymentCancelled,
                transactionId: nil,
                seriesId: seriesId,
                skuId: skuId,
                paymenyUrl: paymentUrl,
                packageId: packageId,
                paymentType: paymentType
            )
        }
    }

    func purchase(aProduct: SKProduct) {
        let payment = SKMutablePayment(product: aProduct)
        payment.applicationUsername = userId
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().add(payment)
    }
}

extension HomeVC {

    @available(iOS 15.0, *)
    private static var sk2ObserverStarted = false

    @available(iOS 15.0, *)
    private static var sk2UpdatesTask: Task<Void, Never>?

    @available(iOS 15.0, *)
    private func startObservingStoreKit2IfNeeded() {
        guard !Self.sk2ObserverStarted else { return }
        Self.sk2ObserverStarted = true

        // ✅ Capture snapshot on MainActor (safe for Swift 6)
        let snapshot = self.currentPaymentSnapshot()

        Self.sk2UpdatesTask = Task.detached(priority: .background) {
            for await result in Transaction.updates {

                let transaction: Transaction
                do {
                    transaction = try SK2Verifier.checkVerified(result)
                } catch {
                    continue
                }

                // Only handle matching product
                if let currentSku = snapshot.skuId, !currentSku.isEmpty, transaction.productID != currentSku {
                    await transaction.finish()
                    continue
                }

                let txId = String(transaction.id)

                // ✅ Notify on main thread (UI safe)
                // Don't notify success here (avoid double log).
                // Observer will emit success from Transaction.updates.
                /*
                await MainActor.run {
                    GluedIn.shared.notifyPaymentResult(
                        status: .paymentSuccess,
                        transactionId: txId,
                        seriesId: snapshot.seriesId,
                        skuId: snapshot.skuId,
                        paymenyUrl: snapshot.paymentUrl,
                        packageId: snapshot.packageId,
                        paymentType: snapshot.paymentType
                    )
                }
                 */
                await transaction.finish()
            }
        }
    }
    
    @available(iOS 15.0, *)
    private func makeAccountToken(from userId: String) -> UUID? {
        let trimmed = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        return UUID(uuidString: trimmed)
    }

    @available(iOS 15.0, *)
    private func purchaseStoreKit2(
        productId: String,
        userId: String?
    ) {

        let snapshot = self.currentPaymentSnapshot()

        // ✅ Only for subscription we pass appAccountToken
        let appAccountToken: UUID? = {
            guard snapshot.paymentType == .inAppPurchaseSubscription,
                  let userId = userId,
                  !userId.isEmpty
            else {
                return nil   // ✅ IAP → nil
            }
            return makeAccountToken(from: userId)
        }()

        Task.detached(priority: .userInitiated) {

            // ---- Payment started
            await MainActor.run {
                GluedIn.shared.notifyPaymentResult(
                    status: .paymentStarted,
                    transactionId: nil,
                    seriesId: snapshot.seriesId,
                    skuId: snapshot.skuId,
                    paymenyUrl: snapshot.paymentUrl,
                    packageId: snapshot.packageId,
                    paymentType: snapshot.paymentType
                )
            }

            do {
                let products = try await Product.products(for: [productId])

                guard let product = products.first else {
                    await MainActor.run {
                        GluedIn.shared.notifyPaymentResult(
                            status: .paymentCancelled,
                            transactionId: nil,
                            seriesId: snapshot.seriesId,
                            skuId: snapshot.skuId,
                            paymenyUrl: snapshot.paymentUrl,
                            packageId: snapshot.packageId,
                            paymentType: snapshot.paymentType
                        )
                    }
                    return
                }

                // ✅ Purchase (token only for subscription)
                let result: Product.PurchaseResult
                if let token = appAccountToken {
                    result = try await product.purchase(
                        options: [.appAccountToken(token)]
                    )
                } else {
                    result = try await product.purchase()
                }

                switch result {

                case .success(let verificationResult):
                    let transaction = try SK2Verifier.checkVerified(verificationResult)
                    let txId = String(transaction.id)

                    await MainActor.run {
                        GluedIn.shared.notifyPaymentResult(
                            status: .paymentSuccess,
                            transactionId: txId,
                            seriesId: snapshot.seriesId,
                            skuId: snapshot.skuId,
                            paymenyUrl: snapshot.paymentUrl,
                            packageId: snapshot.packageId,
                            paymentType: snapshot.paymentType
                        )
                    }

                    await transaction.finish()

                case .userCancelled:
                    await MainActor.run {
                        GluedIn.shared.notifyPaymentResult(
                            status: .paymentCancelled,
                            transactionId: nil,
                            seriesId: snapshot.seriesId,
                            skuId: snapshot.skuId,
                            paymenyUrl: snapshot.paymentUrl,
                            packageId: snapshot.packageId,
                            paymentType: snapshot.paymentType
                        )
                    }

                case .pending:
                    await MainActor.run {
                        GluedIn.shared.notifyPaymentResult(
                            status: .paymentDeferred,
                            transactionId: nil,
                            seriesId: snapshot.seriesId,
                            skuId: snapshot.skuId,
                            paymenyUrl: snapshot.paymentUrl,
                            packageId: snapshot.packageId,
                            paymentType: snapshot.paymentType
                        )
                    }

                @unknown default:
                    await MainActor.run {
                        GluedIn.shared.notifyPaymentResult(
                            status: .paymentFailed,
                            transactionId: nil,
                            seriesId: snapshot.seriesId,
                            skuId: snapshot.skuId,
                            paymenyUrl: snapshot.paymentUrl,
                            packageId: snapshot.packageId,
                            paymentType: snapshot.paymentType
                        )
                    }
                }

            } catch {
                await MainActor.run {
                    GluedIn.shared.notifyPaymentResult(
                        status: .paymentFailed,
                        transactionId: nil,
                        seriesId: snapshot.seriesId,
                        skuId: snapshot.skuId,
                        paymenyUrl: snapshot.paymentUrl,
                        packageId: snapshot.packageId,
                        paymentType: snapshot.paymentType
                    )
                }
            }
        }
    }

    // MARK: - Snapshot helper (isolated access in one place)

    private struct PaymentSnapshot {
        let seriesId: String?
        let skuId: String?
        let paymentUrl: String?
        let packageId: String?
        let paymentType: PaymentMethod
    }

    // ✅ Read actor-isolated properties in one place
    private func currentPaymentSnapshot() -> PaymentSnapshot {
        return PaymentSnapshot(
            seriesId: self.seriesId,
            skuId: self.skuId,
            paymentUrl: self.paymentUrl,
            packageId: self.packageId,
            paymentType: self.paymentType
        )
    }
}
