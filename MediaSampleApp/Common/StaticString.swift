//
//  StaticString.swift
//  MediaSampleApp
//
//  Created by Abhishek Mishra on 09/09/25.
//

import Foundation

struct CellHeights {
    static let mediaList: [CGFloat] = [44, 145, 44, 192, 44, 106, 44, 192, 44, 190, 44, 85, 44, 190]
    static let cellWidthArr: [CGFloat] = [0, 0, 0, 110, 0, 170, 0, 110, 0, 110, 0, 85, 0, 110]
    
    static let mediaSectionTitle: [String] = ["Top Release", "", "Trending Shorts", "", "Non Stop Action", "", "Latest Micro Drama", "", "Popular in Comedy", "","Latest Stories", "", "Latest Movies Just For", ""]
}

enum CellIdentifier {
    static let mainCell             = "MainCell"
    static let headingCell          = "HeadingCell"
    static let mediaCollectionCell  = "MediaCollectionCell"
    static let StoryCell            = "StoryCell"
}

enum SDKEnvironment {
    static let apiKey = "put_here_your_api_key"
    static let secretKey = "put_here_your_secret_key"
    static let serverUrl = "put_here_your_server_Url"
    static let email = "put_here_your_email@example.com"
    static let password = "put_here_your_password"
    static let name = "put_here_your_name"
    static let profileUrl = "put_here_your_profile_url"
}

enum storyName {
    static let main = "Main"
    static let videoDetailsVC = "VideoDetailsVC"
}

enum AssetDetails {
    static let productId = "put_here_asset_id"
    static let assetName = "put_here_asset_name"
    static let imageUrl = "put_here_asset_image_url"
    static let callToAction = "put_here_asset_call_to_action"
    static let shoppableLink = "put_here_asset_shoppable_link"
    static let currencySymbol = "put_here_asset_currency_symbol"
}

enum ShopifyConfig {
    static let shopDomain   = "put_here_shop_domain"
    static let accessToken  = "put_here_access_token"
}

enum ConstantRailIds {
    static let rail     = "put_here_video_rail_id"
    static let series   = "put_here_series_rail_id"
    static let story    = "put_here_story_rail_id"
}
