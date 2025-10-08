//
//  ProductDetailViewController.swift
//  GluedIn
//
//  Created by Ashish on 24/08/25.
//

import UIKit
//import GluedInCoreSDK

protocol ProductDetailViewDelegate: AnyObject {
    // Protocol method - notifies delegate when Add to Cart is tapped with selected variant
    func onTapAddToCart(product: VariantVM?)
}

class ProductDetailViewController: UIViewController,
                                   UICollectionViewDataSource,
                                   UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var alphaView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var handlerView: UIView!
    @IBOutlet weak var productView: UIView!
    @IBOutlet weak var productImageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var buttonAddToCart: UIButton!
    // Connect this to the horizontal UICollectionView in the storyboard (Variants list)
    @IBOutlet weak var labelVariant: UILabel!
    @IBOutlet weak var variantsCollectionView: UICollectionView!
    
    var product: ProductVM?
    var variants: [VariantVM]?
    weak var delegate: ProductDetailViewDelegate?
    
    private var selectedVariantIndex: Int = 0
    
    // Computed property - returns currently selected variant based on selectedVariantIndex
    private var selectedVariant: VariantVM? { 
        guard let variantsList = variants,
                !variantsList.isEmpty,
                selectedVariantIndex >= 0,
              selectedVariantIndex < variantsList.count else {
            return nil
        }
        return variantsList[selectedVariantIndex]
    }
    
    // Called after the controller's view is loaded into memory; sets up UI and collection view
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        alphaView.backgroundColor = GluedInAppColor.giBlackWithAlpha(alpha: 0.5)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        alphaView.addGestureRecognizer(tapGesture)
        alphaView.isUserInteractionEnabled = true
        
        contentView.backgroundColor = GluedInAppColor.giBackgroundColor
        contentView.layer.cornerRadius = 8
        contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        contentView.clipsToBounds = true  // Important to apply the corner mask
        handlerView.backgroundColor = GluedInAppColor.giGrayColor
        
        productView.backgroundColor = GluedInAppColor.giWhiteWithAlpha(alpha: 1.0)
        productView.layer.cornerRadius = 8
        productView.layer.masksToBounds = true
        
        titleLabel.textColor = GluedInAppColor.giTextColorPrimary
        titleLabel.font = .textStyleBold16
        titleLabel.numberOfLines = 0
        if let title = product?.title, !title.isEmpty {
            titleLabel.text = title
            titleLabel.isHidden = false
        } else {
            titleLabel.isHidden = true
        }
        
        descriptionLabel.textColor = GluedInAppColor.giTextColorSecondary
        descriptionLabel.font = .textStyleSemibold12
        descriptionLabel.numberOfLines = 0
        if let desc = product?.description, !desc.isEmpty {
            descriptionLabel.text = desc
            descriptionLabel.isHidden = false
        } else {
            descriptionLabel.isHidden = true
        }
        
        priceLabel.textColor = Colors.hexFFFFFF
        priceLabel.font = .textStyleSemibold14
        
        setPrice()
        updateAddToCartButtonState()
        
        buttonAddToCart.setTitle("Add to Cart", for: .normal)
        buttonAddToCart.setTitleColor(GluedInAppColor.giWhiteWithAlpha(alpha: 1.0), for: .normal)
        buttonAddToCart.titleLabel?.font = .textStyleSemibold16
        buttonAddToCart.backgroundColor = GluedInAppColor.giButtonActiveColor
        buttonAddToCart.layer.cornerRadius = 4.0
        buttonAddToCart.layer.masksToBounds = true
        
        productImageView.contentMode = .scaleAspectFill
        productImageView.retrieveImage(fromURLString: product?.imageURL?.absoluteString ?? "", placeHolder: UIImage())
        
        labelVariant.textColor = Colors.hexFFFFFF
        labelVariant.font = .textStyleSemibold16
        labelVariant.text = product?.variantName == nil ? "" : (product?.variantName ?? "") + ": "
        
        if variantsCollectionView != nil {
            variantsCollectionView.backgroundColor = GluedInAppColor.giBackgroundColor
            variantsCollectionView.showsHorizontalScrollIndicator = false
            variantsCollectionView.dataSource = self
            variantsCollectionView.delegate = self
            variantsCollectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            variantsCollectionView.register(
                UINib(nibName: ProductVariantCollectionViewCell.className,
                      bundle: Bundle(for: ProductVariantCollectionViewCell.self)),
                forCellWithReuseIdentifier: ProductVariantCollectionViewCell.className)
            if variants?.isEmpty ?? false {
                variantsCollectionView.isHidden = true
                updateAddToCartButtonState()
            } else {
                variantsCollectionView.isHidden = false
                variantsCollectionView.reloadData()
                // Default-select the first variant after reload
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    if !(self.variants?.isEmpty ?? false) {
                        self.selectedVariantIndex = 0
                        self.variantsCollectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: [])
                        self.variantsCollectionView.reloadItems(at: [IndexPath(item: 0, section: 0)])
                        self.updateAddToCartButtonState()
                    }
                }
            }
        }
    }
    
    func setPrice() {
        if let display = Global.shared.formatPrice(from: selectedVariant?.price) {
            priceLabel.text = display
            priceLabel.isHidden = false
        } else {
            priceLabel.isHidden = true
        }
    }
    
    private func updateAddToCartButtonState() {
        // If no variant selected, treat as sold out
        guard let variant = selectedVariant else {
            buttonAddToCart.setTitle("Sold Out", for: .normal)
            buttonAddToCart.isEnabled = false
            buttonAddToCart.isUserInteractionEnabled = false
            buttonAddToCart.alpha = 0.5
            return
        }
        // Assuming VariantVM exposes availability as `isAvailable`
        if variant.available {
            buttonAddToCart.setTitle("Add to Cart", for: .normal)
            buttonAddToCart.isEnabled = true
            buttonAddToCart.isUserInteractionEnabled = true
            buttonAddToCart.alpha = 1.0
        } else {
            buttonAddToCart.setTitle("Sold Out", for: .normal)
            buttonAddToCart.isEnabled = false
            buttonAddToCart.isUserInteractionEnabled = false
            buttonAddToCart.alpha = 0.5
        }
    }
    
    // Handles tap on the semi-transparent background view to dismiss the controller
    @objc func handleBackgroundTap() {
        dismiss(animated: false, completion: nil)
    }
    
    // Handles tap on Add to Cart button, notifies delegate with selected variant, then dismisses
    @IBAction func onTapAddToCart(_ sender: UIButton) {
        let chosenVariant = self.selectedVariant
        dismiss(animated: false) { [weak self] in
            guard let self = self else { return }
            self.delegate?.onTapAddToCart(product: chosenVariant)
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    // MARK: - UICollectionViewDataSource
    // Returns number of variant items to display in the collection view
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return variants?.count ?? 0
    }

    // Configures and returns the cell for a given variant item at indexPath
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ProductVariantCollectionViewCell.className,
            for: indexPath
        ) as? ProductVariantCollectionViewCell else {
            return UICollectionViewCell()
        }
        let variant = variants?[indexPath.item]
        let isSelected = (indexPath.item == selectedVariantIndex)
        cell.configure(title: variant?.title ?? "", price: variant?.price ?? "", selected: isSelected)
        cell.onRadioTapped = { [weak self, weak cell] in
            guard let self = self,
                  let cell = cell,
                  let cv = self.variantsCollectionView,
                  let ip = cv.indexPath(for: cell) else { return }
            self.collectionView(cv, didSelectItemAt: ip)
        }
        return cell
    }

    // MARK: - UICollectionViewDelegate
    // Handles selection of a variant item, updates selection state and reloads affected cells
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item < (variants?.count ?? 0) else { return }
        let previous = selectedVariantIndex
        selectedVariantIndex = indexPath.item
        if previous != selectedVariantIndex {
            collectionView.reloadItems(at: [IndexPath(item: previous, section: 0), indexPath])
        } else {
            collectionView.reloadItems(at: [indexPath])
        }
        setPrice()
        updateAddToCartButtonState()
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        // Safely handle empty
        guard indexPath.item < (variants?.count ?? 0) else { return .zero }
        
        // Text width for your chip/pill cell
        let title = variants?[indexPath.item].title ?? ""
        let font = UIFont.systemFont(ofSize: 16, weight: .semibold)   // your cell’s font
        let textWidth = title.size(withAttributes: [.font: font]).width
        
        let horizontalPadding: CGFloat = 50   // left + right internal padding in the cell
        let minWidth: CGFloat = 60
        
        let width = max(minWidth, ceil(textWidth) + horizontalPadding)
        return CGSize(width: width, height: 50)
    }
}
