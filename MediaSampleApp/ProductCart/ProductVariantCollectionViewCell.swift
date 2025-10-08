//
//  ProductVariantCollectionViewCell.swift
//  GluedIn
//
//  Created by Ashish on 27/08/25.
//

import UIKit
import GluedInCoreSDK

final class Colors {
    
    class var hex222222: UIColor {
        return UIColor(red: 34.0/255.0, green: 34.0/255.0, blue: 34.0/255.0, alpha: 1.0)
    }
    
    class var hexFFFFFF: UIColor {
        return UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    }
}

class ProductVariantCollectionViewCell: UICollectionViewCell {

    var onRadioTapped: (() -> Void)?
    
    @IBOutlet weak var buttonRadio: UIButton!
    @IBOutlet weak var labelPrice: UILabel!
    @IBOutlet weak var contentVIew: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        contentView.backgroundColor = .clear
        contentVIew.backgroundColor = .clear
        labelPrice.textColor = Colors.hexFFFFFF
        labelPrice.font = .textStyleSemibold16
        buttonRadio.setImage(UIImage(named: "icUnselectedRadio"), for: .normal)
        buttonRadio.setImage(UIImage(named: "icSelectedRadio"), for: .selected)
        buttonRadio.addTarget(self, action: #selector(radioTapped), for: .touchUpInside)
    }
    
    func configure(title: String, price: String, selected: Bool) {
        labelPrice.text = title
        applySelection(selected)
    }

    private func applySelection(_ isSelected: Bool) {
        buttonRadio.isSelected = isSelected
    }

    override var isSelected: Bool {
        didSet { applySelection(isSelected) }
    }
    
    @objc private func radioTapped() {
        onRadioTapped?()
    }

}
