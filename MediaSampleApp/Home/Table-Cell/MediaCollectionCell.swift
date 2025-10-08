//
//  MediaCollectionCell.swift
//  MediaSampleApp
//
//  Created by Abhishek Mishra on 04/09/25.
//

import UIKit
import GluedInCoreSDK
import GluedInCreatorSDK
import GluedInSDK
 
// MARK: - Video Selection Protocol
protocol VideoSelectionDelegate: AnyObject {
    func didSelectVideo(with id: String, entryPoint: EntryPoint)
}

// MARK: - mediaCollectionCell
class MediaCollectionCell: UITableViewCell {

    // MARK: - IBOutlets
    @IBOutlet weak var mediaCollectionCell: UICollectionView!

    // MARK: - Properties
    var railData: GluedInCoreSDK.CurationDataSeeAllModel? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.mediaCollectionCell.reloadData()
            }
        }
    }
    
    var isGrayCell : Bool = false {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.mediaCollectionCell.reloadData()
            }
        }
    }
    var cellWidth : CGFloat = 110.0
    var cellHeight : CGFloat = 190.0
    
    weak var delegate: VideoSelectionDelegate?
    var entryPoint: EntryPoint = .subFeed

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        setupCollectionView()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    // MARK: - Setup
    private func setupCollectionView() {
        let nib = UINib(nibName: VideoCollectionCell.identifier, bundle: nil)
        mediaCollectionCell.register(nib, forCellWithReuseIdentifier: VideoCollectionCell.identifier)
        
        let nibGray = UINib(nibName: GrayCollectionViewCell.identifier, bundle: nil)
        mediaCollectionCell.register(nibGray, forCellWithReuseIdentifier: GrayCollectionViewCell.identifier)
        
        mediaCollectionCell.delegate = self
        mediaCollectionCell.dataSource = self
        mediaCollectionCell.contentInset = .zero
    }
}

// MARK: - UICollectionView Delegate & DataSource
extension MediaCollectionCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isGrayCell {
            return 10
        }
        return railData?.result?.itemList?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if isGrayCell {
            guard
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GrayCollectionViewCell.identifier, for: indexPath) as? GrayCollectionViewCell
            else {
                return UICollectionViewCell()
            }
            return cell
        }
        guard
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCollectionCell.identifier, for: indexPath) as? VideoCollectionCell,
            let model = railData?.result?.itemList?[indexPath.row]
        else {
            return UICollectionViewCell()
        }

        cell.configDiscoverCell(model: model, typeCheck: railData?.result?.type)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isGrayCell {
            return
        }
        guard let item = railData?.result?.itemList?[indexPath.item] else { return }

        let selectedId: String? = {
            if entryPoint == .story {
                return item.assetId
            } else {
                return item.video?.videoId ?? item.id
            }
        }()

        if let id = selectedId, !id.isEmpty {
            delegate?.didSelectVideo(with: id, entryPoint: entryPoint)
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: cellWidth, height: cellHeight)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8.0
    }
}
