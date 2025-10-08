//
//  VideoCollectionCell.swift
//  GluedIn
//
//  Created by sahil on 06/11/24.
//

import UIKit
import GluedInCoreSDK

class VideoCollectionCell: UICollectionViewCell {

    // MARK: - IBOutlets
    @IBOutlet weak var BGView: UIView!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var imageViewPlay: UIImageView!
    @IBOutlet weak var viewPlay: UIView!
    @IBOutlet weak var imageContentType: UIImageView!
    @IBOutlet weak var labelText: UILabel!
    @IBOutlet weak var labelICText: UILabel!
    @IBOutlet weak var imageSeries: UIImageView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var lblBottom: UILabel!
    @IBOutlet weak var storyView: UIView!
    @IBOutlet weak var lblNameStory: UILabel!
    @IBOutlet weak var imageProfile: UIImageView!
    @IBOutlet weak var labelCount: UILabel!
    
    // MARK: - Properties
    static let identifier = "VideoCollectionCell"
    
    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        setupInitialUI()
    }

    // MARK: - Setup UI
    private func setupInitialUI() {
        BGView.layer.cornerRadius = 8
        BGView.layer.borderWidth = 1.0
        BGView.layer.borderColor = UIColor(red: 211/255, green: 226/255, blue: 237/255, alpha: 1).cgColor

        thumbnailImageView.layer.cornerRadius = 8

        viewPlay.backgroundColor = .clear
        viewPlay.layer.cornerRadius = 20

        labelICText.textColor = UIColor(red: 173/255, green: 186/255, blue: 206/255, alpha: 1)
        labelICText.font = UIFont(name: "SFUIDisplay-Regular", size: 11)
        labelICText.numberOfLines = 1

        labelText.textColor = .black
        labelText.font = UIFont(name: "SFUIDisplay-Regular", size: 15)
        labelText.numberOfLines = 0

        imageProfile.layer.borderColor = UIColor.white.cgColor
        imageProfile.layer.borderWidth = 1
        imageProfile.clipsToBounds = true
        imageProfile.layer.cornerRadius = imageProfile.frame.width / 2.0
 
        resetAllViews()
    }

    private func resetAllViews() {
        viewPlay.isHidden = true
        imageContentType.isHidden = true
        labelText.isHidden = true
        labelICText.isHidden = true
        bottomView.isHidden = true
        lblBottom.isHidden = true
        imageSeries.isHidden = true
        storyView.isHidden = true
        labelCount.isHidden = true
    }

    // MARK: - Configure FeedModel Content
    func configureData(feed: FeedModel) {
        resetAllViews()

        if let imageURL = URL(string: feed.thumbnailUrl ?? "") {
            thumbnailImageView.sd_setImage(with: imageURL)
        }

        labelText.text = feed.descriptionField
        imageContentType.isHidden = false

        switch feed.contentType?.lowercased() {
        case "image", "gif":
            imageContentType.image = UIImage(named: "icImageContent")

        case "multi":
            imageContentType.image = UIImage(named: "icMultiContent")

        case "text":
            imageContentType.image = UIImage(named: "icTextContent")
            labelText.isHidden = false
            labelICText.isHidden = false
            thumbnailImageView.isHidden = true

        case "video":
            imageContentType.image = UIImage(named: "icVideoContent")
            viewPlay.isHidden = false

        default:
            imageContentType.image = UIImage(named: "icVideoContent")
            viewPlay.isHidden = false
        }
    }

    // MARK: - Configure GluedIn SDK ItemList Model
    func configDiscoverCell(model: GluedInCoreSDK.ItemList?, typeCheck: String?) {
        resetAllViews()

        BGView.isHidden = false
        thumbnailImageView.isHidden = false

        // Load thumbnail
        if let urlStr = model?.video?.thumbnailUrl ?? model?.thumbnail,
           let imageURL = URL(string: urlStr) {
            thumbnailImageView.sd_setImage(with: imageURL)
        } else {
            thumbnailImageView.image = UIImage(named: "placeholder")
        }

        switch typeCheck?.lowercased() {
        case "video":
            if let title = model?.video?.title, !title.isEmpty {
//                bottomView.isHidden = false
//                lblBottom.isHidden = false
//                lblBottom.text = title
            }
            
            labelCount.isHidden = false
            imageSeries.isHidden = false
            imageSeries.image = UIImage(named: "likeWhite")
            labelCount.text = (model?.video?.likeCount ?? 0).formattedCount()

        case "series":
//            imageSeries.isHidden = false
            if let title = model?.displayName, !title.isEmpty {
//                bottomView.isHidden = false
//                lblBottom.isHidden = false
//                lblBottom.text = title
            }

        case "story":
            handleStoryUI(model: model)

        default:
            break
        }
    }

    private func handleStoryUI(model: GluedInCoreSDK.ItemList?) {
        imageSeries.isHidden = true
        bottomView.isHidden = true
        storyView.isHidden = false
        lblNameStory.text = model?.firstName ?? ""
        
        if let profileURL = URL(string: model?.thumbnail ?? "") {
            imageProfile.sd_setImage(with: profileURL)
        } else {
            imageProfile.image = UIImage(named: "profile")
        }
    }
}

extension Int {
    func formattedCount() -> String {
        switch self {
        case 1_000_000...:
            return String(format: "%.1fM", Double(self) / 1_000_000).replacingOccurrences(of: ".0", with: "")
        case 1_000...:
            return String(format: "%.1fK", Double(self) / 1_000).replacingOccurrences(of: ".0", with: "")
        default:
            return "\(self)"
        }
    }
}
