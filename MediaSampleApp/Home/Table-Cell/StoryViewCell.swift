//
//  StoryViewCell.swift
//  MediaSampleApp
//
//  Created by Abhishek Mishra on 04/09/25.
//

import UIKit
import GluedInCoreSDK

class StoryViewCell: UICollectionViewCell {
    
    static let identifier = "StoryViewCell"
    
    @IBOutlet weak var cellView: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var titleLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        profileImageView.layer.cornerRadius = 27.0
        profileImageView.clipsToBounds = true
        cellView.layer.cornerRadius = 30
        cellView.layer.borderColor = GluedInAppColor.giButtonActiveColor.cgColor
        cellView.layer.borderWidth = 1.0
        cellView.layer.masksToBounds = true
    }
 
    // MARK: - Configure GluedIn SDK ItemList Model
    func configDiscoverCell(model: GluedInCoreSDK.ItemList?) {
        // Load profile image
        if let urlStr = model?.thumbnail, let imageURL = URL(string: urlStr) {
            profileImageView.sd_setImage(with: imageURL)
        } else {
            profileImageView.image = UIImage(named: "profile")
        }
        
        // Set title from available fields
        titleLbl.text = model?.firstName ?? model?.displayName ?? ""
    }
}
