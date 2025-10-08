//
//  AddToCartTableViewCell.swift
//  GluedIn
//
//  Created by Ashish on 07/09/25.
//

import UIKit
import GluedInCoreSDK

protocol AddToCartTableViewCellDelegate: AnyObject {
    func onTapDelete(post: CartLineVM?)
    func onTapUpdate(post: CartLineVM?, quantity: Int)
}

class AddToCartTableViewCell: UITableViewCell {

    @IBOutlet weak var productContentView: UIView!
    @IBOutlet weak var cartImageView: UIView!
    @IBOutlet weak var productImageView: UIImageView!
    @IBOutlet weak var labelTile: UILabel!
    @IBOutlet weak var labelPrice: UILabel!
    @IBOutlet weak var buttonDelete: UIButton!
    @IBOutlet weak var buttonPlus: UIButton!
    @IBOutlet weak var buttonMinus: UIButton!
    @IBOutlet weak var labelQty: UILabel!
    @IBOutlet weak var viewQty: UIView!
    @IBOutlet weak var labelVariant: UILabel!
    
    weak var delegate: AddToCartTableViewCellDelegate?
    
    var post: CartLineVM? {
        didSet {
            updateUI()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        buttonPlus.tag = 1
        buttonMinus.tag = -1
        
        productContentView.layer.cornerRadius = 9
        productContentView.layer.borderWidth = 1
        productContentView.layer.borderColor = AppColor.giBackgroundCreatorColorSecondary.cgColor
        productContentView.layer.masksToBounds = true
        
        productContentView.backgroundColor = AppColor.giBackgroundColor
        
        cartImageView.layer.cornerRadius = 10
        cartImageView.layer.masksToBounds = true
        cartImageView.layer.borderWidth = 1
        cartImageView.layer.borderColor = AppColor.giColorGraySelection.cgColor
        
        productImageView.contentMode = .scaleAspectFill
        
        buttonMinus.layer.cornerRadius = buttonMinus.frame.height / 2
        buttonMinus.layer.masksToBounds = true
    
        buttonPlus.layer.cornerRadius = buttonPlus.frame.height / 2
        buttonPlus.layer.masksToBounds = true
        
        viewQty.backgroundColor = .clear
        viewQty.layer.cornerRadius = viewQty.frame.height / 2
        viewQty.layer.borderWidth = 1
        viewQty.layer.borderColor = AppColor.giWhiteWithAlpha(alpha: 0.1).cgColor
        viewQty.layer.masksToBounds = true
        
        labelVariant.text = ""
    }
    
    func updateUI() {
        labelTile.text = post?.title
        
        if let display = Global.shared.formatPrice(from: (post?.currencyCode ?? "") + " " + (post?.priceAmount ?? "")) {
            labelPrice.text = display
            labelPrice.isHidden = false
        } else {
            labelPrice.isHidden = true
        }
        
        productImageView.retrieveImage(
            fromURLString: post?.imageURL?.absoluteString ?? "",
            placeHolder: UIImage(named: "icProductPlaceholder")
        )
        
        labelQty.text = "\(post?.quantity ?? 0)"
        
        labelVariant.text = (post?.selectedOptions.first?.name ?? "") + ": " + (post?.selectedOptions.first?.value ?? "")
    }
    
    @IBAction func onClickDelete(_ sender: UIButton) {
        delegate?.onTapDelete(post: post)
    }
    
    @IBAction func onClickUpdateQty(_ sender: UIButton) {
        guard let post = post else { return }
        var quantity = post.quantity
        if sender.tag == 1 {
            quantity += 1
        } else if sender.tag == -1 {
            quantity = max(1, quantity - 1)
        }
        // Create a new struct with updated quantity
        let updatedPost = CartLineVM(
            lineId: post.lineId,
            quantity: quantity,
            title: post.title,
            priceAmount: post.priceAmount,
            currencyCode: post.currencyCode,
            imageURL: post.imageURL,
            selectedOptions: post.selectedOptions
        )
        delegate?.onTapUpdate(post: updatedPost, quantity: quantity)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
